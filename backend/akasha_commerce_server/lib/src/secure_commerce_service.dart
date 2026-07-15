import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';

import 'audit_record.dart';
import 'idempotency_record.dart';
import 'mapping/steam_to_server_state_mapper.dart';
import 'order_id64.dart';
import 'reconciliation_cursor.dart';
import 'secure_commerce_models.dart';
import 'secure_commerce_repository.dart';
import 'server_order_state.dart';
import 'steam_adapter.dart';
import 'steam_txn_phase.dart';

/// Server-side orchestration over accounts, 64-bit orders, Steam adapter, ledger.
class SecureCommerceService {
  SecureCommerceService({
    required SecureCommerceRepository repository,
    required SteamMicroTxnAdapter steam,
    required OrderId64Generator orderIds,
    DateTime Function()? clock,
    String Function()? idFactory,
  }) : _repo = repository,
       _steam = steam,
       _orderIds = orderIds,
       _clock = clock ?? DateTime.now,
       _id = idFactory ?? _defaultId;

  final SecureCommerceRepository _repo;
  final SteamMicroTxnAdapter _steam;
  final OrderId64Generator _orderIds;
  final DateTime Function() _clock;
  final String Function() _id;

  static var _seq = 0;
  static String _defaultId() => 'srv_${++_seq}';

  Future<WalletProjection> wallet(String steamId) async =>
      projectWalletFromLedger(
        userId: steamId,
        entries: await _repo.listLedger(steamId),
      );

  Future<SecureCommerceOrder?> getOrder(OrderId64 orderId) =>
      _repo.getOrder(orderId);

  /// Create order + InitTxn. Returns existing order when idempotency hits.
  Future<SecureCommerceOrder> beginPremiumPackPurchase({
    required String steamId,
    required String productId,
    required String idempotencyKey,
  }) {
    return _repo.runInTransaction(() async {
      await _repo.ensureAccount(steamId);

      final existingIdem = await _repo.getIdempotency(
        'begin_premium_pack',
        idempotencyKey,
      );
      if (existingIdem?.resultRef != null) {
        final existing = await _repo.getOrder(
          OrderId64(int.parse(existingIdem!.resultRef!)),
        );
        if (existing != null) return existing;
      }

      final byKey = await _repo.findOrderByIdempotencyKey(idempotencyKey);
      if (byKey != null) return byKey;

      final product = await _requirePremiumPack(productId);
      final grant = product.grantPremiumAmount!;
      final orderId = _orderIds.next();
      final now = _clock().toUtc();

      var order = SecureCommerceOrder(
        orderId: orderId,
        steamId: steamId,
        productId: productId,
        state: ServerOrderState.created,
        idempotencyKey: idempotencyKey,
        createdAt: now,
        premiumGrantAmount: grant,
        updatedAt: now,
      );
      await _repo.saveOrder(order);

      final init = await _steam.initTxn(
        steamId: steamId,
        orderId: order.orderIdKey,
        productId: productId,
        premiumGrantAmount: grant,
      );

      order = _applySteamPhase(order, init.phase, now);
      await _repo.saveOrder(order);
      await _repo.saveIdempotency(
        IdempotencyRecord(
          key: idempotencyKey,
          scope: 'begin_premium_pack',
          createdAt: now,
          resultRef: order.orderIdKey,
        ),
      );
      await _repo.appendAudit(
        CommerceAuditRecord(
          id: _id(),
          createdAt: now,
          action: 'begin_premium_pack',
          steamId: steamId,
          orderId: order.orderIdKey,
          steamPhase: init.phase,
          detail: init.detail,
        ),
      );
      return order;
    });
  }

  /// Mark authorized (user approved) then FinalizeTxn → grant Astra once.
  Future<WalletProjection> completePremiumPackPurchase({
    required OrderId64 orderId,
    required String finalizeIdempotencyKey,
  }) {
    return _repo.runInTransaction(() async {
      final existingGrant = await _repo.findLedgerByIdempotencyKey(
        finalizeIdempotencyKey,
      );
      if (existingGrant != null) {
        return wallet(existingGrant.userId);
      }

      var order = await _repo.getOrder(orderId);
      if (order == null) {
        throw const CommerceNotFound('order_missing', 'Order not found.');
      }

      if (order.state == ServerOrderState.completed) {
        return wallet(order.steamId);
      }
      if (order.state == ServerOrderState.refunded ||
          order.state == ServerOrderState.chargedBack) {
        throw const CommerceRejected(
          'order_closed',
          'Cannot finalize a refunded/charged-back order.',
        );
      }

      final now = _clock().toUtc();
      if (order.state == ServerOrderState.authorizationPending ||
          order.state == ServerOrderState.created) {
        order = order.copyWith(
          state: ServerOrderState.authorized,
          lastSteamPhase: SteamTxnPhase.userAuthorized,
          updatedAt: now,
        );
        await _repo.saveOrder(order);
      }

      order = order.copyWith(
        state: ServerOrderState.finalizing,
        updatedAt: now,
      );
      await _repo.saveOrder(order);

      final fin = await _steam.finalizeTxn(
        steamId: order.steamId,
        orderId: order.orderIdKey,
      );

      if (fin.phase == SteamTxnPhase.indeterminate) {
        order = order.copyWith(
          state: ServerOrderState.indeterminate,
          lastSteamPhase: fin.phase,
          updatedAt: now,
        );
        await _repo.saveOrder(order);
        await _repo.appendAudit(
          CommerceAuditRecord(
            id: _id(),
            createdAt: now,
            action: 'finalize_indeterminate',
            steamId: order.steamId,
            orderId: order.orderIdKey,
            steamPhase: fin.phase,
          ),
        );
        throw const CommerceRejected(
          'finalize_indeterminate',
          'Finalize ambiguous; use QueryTxn/GetReport before granting.',
        );
      }

      if (!fin.isCompletedConfirmation) {
        order = _applySteamPhase(order, fin.phase, now);
        await _repo.saveOrder(order);
        throw CommerceRejected(
          'finalize_failed',
          'Finalize did not complete: ${fin.phase.name}',
        );
      }

      return _grantPremiumForCompletedOrder(
        order: order,
        finalizeIdempotencyKey: finalizeIdempotencyKey,
        steamPhase: fin.phase,
        now: now,
      );
    });
  }

  /// Resolve indeterminate via QueryTxn; grant if completed.
  Future<WalletProjection> resolveIndeterminateOrder({
    required OrderId64 orderId,
    required String resolveIdempotencyKey,
  }) {
    return _repo.runInTransaction(() async {
      final existing = await _repo.findLedgerByIdempotencyKey(
        resolveIdempotencyKey,
      );
      if (existing != null) return wallet(existing.userId);

      var order = await _repo.getOrder(orderId);
      if (order == null) {
        throw const CommerceNotFound('order_missing', 'Order not found.');
      }
      if (order.state == ServerOrderState.completed) {
        return wallet(order.steamId);
      }

      final query = await _steam.queryTxn(
        steamId: order.steamId,
        orderId: order.orderIdKey,
      );
      final now = _clock().toUtc();
      if (!query.isCompletedConfirmation) {
        order = _applySteamPhase(order, query.phase, now);
        await _repo.saveOrder(order);
        throw CommerceRejected(
          'still_incomplete',
          'QueryTxn did not confirm completion: ${query.phase.name}',
        );
      }

      return _grantPremiumForCompletedOrder(
        order: order,
        finalizeIdempotencyKey: resolveIdempotencyKey,
        steamPhase: query.phase,
        now: now,
      );
    });
  }

  /// Process GetReport rows for post-hoc reconciliation (not first-grant wait).
  Future<int> reconcileGetReport({required String cursorHighWater}) {
    return _repo.runInTransaction(() async {
      final rows = await _steam.getReport(cursorHighWater: cursorHighWater);
      var processed = 0;
      String mark = cursorHighWater;
      final now = _clock().toUtc();

      for (final row in rows) {
        mark = row.reportId;
        final order = await _repo.getOrder(OrderId64(int.parse(row.orderId)));
        if (order == null) continue;

        if (row.phase == SteamTxnPhase.reportChargeback &&
            order.state == ServerOrderState.completed) {
          await _reversePremiumGrant(
            order: order,
            idempotencyKey: 'recon_chargeback:${row.reportId}',
            now: now,
            chargedBack: true,
          );
          processed++;
        } else if (row.phase == SteamTxnPhase.reportCompleted &&
            order.state == ServerOrderState.indeterminate) {
          await _grantPremiumForCompletedOrder(
            order: order,
            finalizeIdempotencyKey: 'recon_completed:${row.reportId}',
            steamPhase: row.phase,
            now: now,
          );
          processed++;
        }

        await _repo.appendAudit(
          CommerceAuditRecord(
            id: _id(),
            createdAt: now,
            action: 'getreport_row',
            steamId: row.steamId,
            orderId: row.orderId,
            steamPhase: row.phase,
            detail: row.reportId,
          ),
        );
      }

      await _repo.saveReconciliationCursor(
        ReconciliationCursor(
          provider: 'steam_getreport',
          highWaterMark: mark,
          updatedAt: now,
        ),
      );
      return processed;
    });
  }

  Future<WalletProjection> _grantPremiumForCompletedOrder({
    required SecureCommerceOrder order,
    required String finalizeIdempotencyKey,
    required SteamTxnPhase steamPhase,
    required DateTime now,
  }) async {
    final raced = await _repo.findLedgerByIdempotencyKey(
      finalizeIdempotencyKey,
    );
    if (raced != null) return wallet(order.steamId);

    final grant = order.premiumGrantAmount ?? 0;
    if (grant <= 0) {
      throw const CommerceRejected('invalid_grant', 'Missing premium grant.');
    }

    await _repo.appendLedger(
      LedgerEntry(
        id: _id(),
        userId: order.steamId,
        currency: CurrencyKind.premium,
        type: LedgerEntryType.credit,
        amount: grant,
        idempotencyKey: finalizeIdempotencyKey,
        createdAt: now,
        orderId: order.orderIdKey,
        productId: order.productId,
        note: 'premium_pack_finalization',
      ),
    );

    final completed = order.copyWith(
      state: ServerOrderState.completed,
      lastSteamPhase: steamPhase,
      updatedAt: now,
    );
    await _repo.saveOrder(completed);
    await _repo.appendAudit(
      CommerceAuditRecord(
        id: _id(),
        createdAt: now,
        action: 'grant_premium',
        steamId: order.steamId,
        orderId: order.orderIdKey,
        steamPhase: steamPhase,
      ),
    );
    return wallet(order.steamId);
  }

  Future<void> _reversePremiumGrant({
    required SecureCommerceOrder order,
    required String idempotencyKey,
    required DateTime now,
    required bool chargedBack,
  }) async {
    final existing = await _repo.findLedgerByIdempotencyKey(idempotencyKey);
    if (existing != null) return;

    final grant = order.premiumGrantAmount ?? 0;
    final entries = await _repo.listLedger(order.steamId);
    LedgerEntry? credit;
    for (final e in entries) {
      if (e.orderId == order.orderIdKey &&
          e.type == LedgerEntryType.credit &&
          e.currency == CurrencyKind.premium) {
        credit = e;
        break;
      }
    }
    if (credit == null || grant <= 0) return;

    await _repo.appendLedger(
      LedgerEntry(
        id: _id(),
        userId: order.steamId,
        currency: CurrencyKind.premium,
        type: LedgerEntryType.reversal,
        amount: -grant,
        idempotencyKey: idempotencyKey,
        createdAt: now,
        orderId: order.orderIdKey,
        productId: order.productId,
        reversesEntryId: credit.id,
        note: chargedBack ? 'chargeback_reversal' : 'refund_reversal',
      ),
    );
    await _repo.saveOrder(
      order.copyWith(
        state: chargedBack
            ? ServerOrderState.chargedBack
            : ServerOrderState.refunded,
        lastSteamPhase: chargedBack
            ? SteamTxnPhase.reportChargeback
            : SteamTxnPhase.reportSettlement,
        updatedAt: now,
      ),
    );
  }

  SecureCommerceOrder _applySteamPhase(
    SecureCommerceOrder order,
    SteamTxnPhase phase,
    DateTime now,
  ) {
    return order.copyWith(
      state: SteamToServerStateMapper.mapPhase(phase, current: order.state),
      lastSteamPhase: phase,
      updatedAt: now,
    );
  }

  Future<CommerceProduct> _requirePremiumPack(String productId) async {
    if (!CommerceCatalog.isApprovedAstraPack(productId)) {
      throw const CommerceRejected(
        'unapproved_astra_pack',
        'Product is not an approved Astra pack.',
      );
    }
    final product =
        await _repo.getProduct(productId) ?? CommerceCatalog.byId(productId);
    if (product == null || product.kind != ProductKind.premiumPack) {
      throw const CommerceRejected(
        'not_premium_pack',
        'Product is not a premium pack.',
      );
    }
    if ((product.grantPremiumAmount ?? 0) <= 0) {
      throw const CommerceRejected('invalid_pack', 'Invalid grant amount.');
    }
    return product;
  }
}
