import 'commerce_catalog.dart';
import 'commerce_exceptions.dart';
import 'commerce_models.dart';
import 'commerce_ports.dart';
import 'currency_kind.dart';

/// Server-neutral commerce use cases. No Flutter UI · no Vault writes · no Steam yet.
class CommerceService {
  CommerceService({
    required CommerceRepository repository,
    required PaymentProvider paymentProvider,
    DateTime Function()? clock,
    String Function()? idFactory,
  }) : _repo = repository,
       _payments = paymentProvider,
       _clock = clock ?? DateTime.now,
       _id = idFactory ?? _defaultId;

  final CommerceRepository _repo;
  final PaymentProvider _payments;
  final DateTime Function() _clock;
  final String Function() _id;

  static var _seq = 0;
  static String _defaultId() => 'id_${++_seq}_${DateTime.now().microsecondsSinceEpoch}';

  Future<WalletProjection> wallet(String userId) async =>
      projectWalletFromLedger(
        userId: userId,
        entries: await _repo.listLedger(userId),
      );

  /// Create a pending premium-pack order (Steam InitTxn equivalent later).
  Future<CommerceOrder> createPremiumPackOrder({
    required String userId,
    required String productId,
    required String idempotencyKey,
  }) async {
    final existing = await _repo.findOrderByIdempotencyKey(idempotencyKey);
    if (existing != null) return existing;

    final product = await _requireProduct(productId);
    if (product.kind != ProductKind.premiumPack) {
      throw const CommerceRejected(
        'not_premium_pack',
        'Product is not a premium currency pack.',
      );
    }
    final grant = product.grantPremiumAmount;
    if (grant == null || grant <= 0) {
      throw const CommerceRejected(
        'invalid_pack',
        'Premium pack must declare a positive grant amount.',
      );
    }

    final order = CommerceOrder(
      id: _id(),
      userId: userId,
      productId: productId,
      status: OrderStatus.pendingPayment,
      idempotencyKey: idempotencyKey,
      settledPremiumGrant: grant,
    );
    await _repo.saveOrder(order);
    return order;
  }

  /// After payment provider confirms settlement — grant Astra exactly once.
  Future<WalletProjection> finalizePremiumPackPurchase({
    required String orderId,
    required String settleIdempotencyKey,
  }) async {
    final order = await _repo.getOrder(orderId);
    if (order == null) {
      throw const CommerceNotFound('order_missing', 'Order not found.');
    }

    final existingLedger = await _repo.findLedgerByIdempotencyKey(
      settleIdempotencyKey,
    );
    if (existingLedger != null) {
      return wallet(order.userId);
    }

    if (order.status == OrderStatus.refunded) {
      throw const CommerceRejected(
        'order_refunded',
        'Cannot settle a refunded order.',
      );
    }

    if (order.status == OrderStatus.settled) {
      // Settled without this settle key — still block double grant via ledger key.
      return wallet(order.userId);
    }

    final settlement = await _payments.settle(
      orderId: orderId,
      idempotencyKey: settleIdempotencyKey,
    );
    if (!settlement.succeeded) {
      await _repo.saveOrder(order.copyWith(status: OrderStatus.failed));
      throw const CommerceRejected(
        'payment_failed',
        'Payment settlement failed.',
      );
    }

    final grant = order.settledPremiumGrant ?? 0;
    if (grant <= 0) {
      throw const CommerceRejected(
        'invalid_grant',
        'Order has no premium grant amount.',
      );
    }

    // Re-check after await (race): another finalize may have written ledger.
    final raced = await _repo.findLedgerByIdempotencyKey(settleIdempotencyKey);
    if (raced != null) {
      return wallet(order.userId);
    }

    await _repo.appendLedger(
      LedgerEntry(
        id: _id(),
        userId: order.userId,
        currency: CurrencyKind.premium,
        type: LedgerEntryType.credit,
        amount: grant,
        idempotencyKey: settleIdempotencyKey,
        createdAt: _clock().toUtc(),
        orderId: order.id,
        productId: order.productId,
        note: 'premium_pack_settlement',
      ),
    );
    await _repo.saveOrder(
      order.copyWith(
        status: OrderStatus.settled,
        externalPaymentId: settlement.externalPaymentId,
      ),
    );
    return wallet(order.userId);
  }

  /// Verifiable Echo grant (test bootstrap / operator / event code).
  Future<WalletProjection> grantEarned({
    required String userId,
    required int amount,
    required String idempotencyKey,
    String? note,
  }) async {
    if (amount <= 0) {
      throw const CommerceRejected(
        'invalid_amount',
        'Earned grant amount must be positive.',
      );
    }
    final existing = await _repo.findLedgerByIdempotencyKey(idempotencyKey);
    if (existing != null) {
      return wallet(userId);
    }
    await _repo.appendLedger(
      LedgerEntry(
        id: _id(),
        userId: userId,
        currency: CurrencyKind.earned,
        type: LedgerEntryType.credit,
        amount: amount,
        idempotencyKey: idempotencyKey,
        createdAt: _clock().toUtc(),
        note: note ?? 'earned_grant',
      ),
    );
    return wallet(userId);
  }

  /// Spend currency and create a permanent theme entitlement.
  Future<CommerceEntitlement> unlockTheme({
    required String userId,
    required String productId,
    required CurrencyKind payWith,
    required String idempotencyKey,
  }) async {
    final existingEnt = await _repo.findEntitlementByIdempotencyKey(
      idempotencyKey,
    );
    if (existingEnt != null) return existingEnt;

    final product = await _requireProduct(productId);
    if (product.kind != ProductKind.themeUnlock) {
      throw const CommerceRejected(
        'not_theme',
        'Product is not a theme unlock.',
      );
    }
    final entitlementKey = product.entitlementKey;
    if (entitlementKey == null || entitlementKey.isEmpty) {
      throw const CommerceRejected(
        'missing_entitlement_key',
        'Theme product requires entitlementKey.',
      );
    }
    if (!product.payment.allows(payWith)) {
      throw const CommerceRejected(
        'payment_not_allowed',
        'Currency not accepted for this product.',
      );
    }
    final price = product.payment.priceFor(payWith);
    if (price == null || price <= 0) {
      throw const CommerceRejected(
        'invalid_price',
        'Product has no valid price for chosen currency.',
      );
    }

    final owned = await _repo.findEntitlement(
      userId: userId,
      key: entitlementKey,
    );
    if (owned != null) {
      throw const CommerceConflict(
        'entitlement_owned',
        'Theme entitlement already owned.',
      );
    }

    final balance = await wallet(userId);
    if (balance.of(payWith) < price) {
      throw const CommerceRejected(
        'insufficient_balance',
        'Not enough currency for theme unlock.',
      );
    }

    final spendKey = 'spend:$idempotencyKey';
    final existingSpend = await _repo.findLedgerByIdempotencyKey(spendKey);
    if (existingSpend == null) {
      await _repo.appendLedger(
        LedgerEntry(
          id: _id(),
          userId: userId,
          currency: payWith,
          type: LedgerEntryType.debit,
          amount: price,
          idempotencyKey: spendKey,
          createdAt: _clock().toUtc(),
          productId: productId,
          note: 'theme_unlock_spend',
        ),
      );
    }

    final entitlement = CommerceEntitlement(
      userId: userId,
      key: entitlementKey,
      grantedAt: _clock().toUtc(),
      sourceProductId: productId,
      idempotencyKey: idempotencyKey,
    );
    await _repo.saveEntitlement(entitlement);
    return entitlement;
  }

  /// Astra-only donation spend; no entitlement.
  Future<WalletProjection> donate({
    required String userId,
    required String productId,
    required String idempotencyKey,
  }) async {
    final existing = await _repo.findLedgerByIdempotencyKey(idempotencyKey);
    if (existing != null) {
      return wallet(userId);
    }

    final product = await _requireProduct(productId);
    if (product.kind != ProductKind.donation) {
      throw const CommerceRejected(
        'not_donation',
        'Product is not a donation.',
      );
    }
    if (!product.payment.allows(CurrencyKind.premium)) {
      throw const CommerceRejected(
        'donation_premium_only',
        'Donations must be paid with premium currency.',
      );
    }
    final price = product.payment.premiumPrice;
    if (price == null || price <= 0) {
      throw const CommerceRejected(
        'invalid_price',
        'Donation product needs a positive premium price.',
      );
    }

    final balance = await wallet(userId);
    if (balance.premium < price) {
      throw const CommerceRejected(
        'insufficient_balance',
        'Not enough Astra for donation.',
      );
    }

    await _repo.appendLedger(
      LedgerEntry(
        id: _id(),
        userId: userId,
        currency: CurrencyKind.premium,
        type: LedgerEntryType.debit,
        amount: price,
        idempotencyKey: idempotencyKey,
        createdAt: _clock().toUtc(),
        productId: productId,
        note: 'donation_spend',
      ),
    );
    return wallet(userId);
  }

  /// Refund a settled premium-pack order: reversal credit offset + mark refunded.
  Future<WalletProjection> refundSettledPremiumPack({
    required String orderId,
    required String idempotencyKey,
  }) async {
    final existing = await _repo.findLedgerByIdempotencyKey(idempotencyKey);
    if (existing != null) {
      final order = await _repo.getOrder(orderId);
      return wallet(order?.userId ?? existing.userId);
    }

    final order = await _repo.getOrder(orderId);
    if (order == null) {
      throw const CommerceNotFound('order_missing', 'Order not found.');
    }
    if (order.status != OrderStatus.settled) {
      throw const CommerceRejected(
        'not_settled',
        'Only settled orders can be refunded.',
      );
    }

    final grant = order.settledPremiumGrant ?? 0;
    final entries = await _repo.listLedger(order.userId);
    LedgerEntry? credit;
    for (final e in entries) {
      if (e.orderId == order.id &&
          e.type == LedgerEntryType.credit &&
          e.currency == CurrencyKind.premium) {
        credit = e;
        break;
      }
    }
    if (credit == null || grant <= 0) {
      throw const CommerceRejected(
        'missing_credit',
        'No premium credit found for order.',
      );
    }

    // Reversal offsets the prior credit without mutating/deleting it.
    // amount is a signed adjustment (negative when reversing a credit).
    await _repo.appendLedger(
      LedgerEntry(
        id: _id(),
        userId: order.userId,
        currency: CurrencyKind.premium,
        type: LedgerEntryType.reversal,
        amount: -grant,
        idempotencyKey: idempotencyKey,
        createdAt: _clock().toUtc(),
        orderId: order.id,
        productId: order.productId,
        reversesEntryId: credit.id,
        note: 'refund_reversal',
      ),
    );
    await _repo.saveOrder(order.copyWith(status: OrderStatus.refunded));
    return wallet(order.userId);
  }

  Future<CommerceProduct> _requireProduct(String productId) async {
    final fromRepo = await _repo.getProduct(productId);
    final product = fromRepo ?? CommerceCatalog.byId(productId);
    if (product == null) {
      throw CommerceNotFound('product_missing', 'Unknown product: $productId');
    }
    return product;
  }
}
