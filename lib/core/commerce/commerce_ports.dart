import 'commerce_models.dart';
import 'currency_kind.dart';

/// Server-side persistence port (implementations: fake now, secure backend later).
abstract class CommerceRepository {
  Future<CommerceProduct?> getProduct(String productId);

  Future<CommerceOrder?> getOrder(String orderId);

  Future<CommerceOrder?> findOrderByIdempotencyKey(String idempotencyKey);

  Future<void> saveOrder(CommerceOrder order);

  Future<LedgerEntry?> findLedgerByIdempotencyKey(String idempotencyKey);

  Future<void> appendLedger(LedgerEntry entry);

  Future<List<LedgerEntry>> listLedger(String userId);

  Future<CommerceEntitlement?> findEntitlement({
    required String userId,
    required String key,
  });

  Future<CommerceEntitlement?> findEntitlementByIdempotencyKey(
    String idempotencyKey,
  );

  Future<void> saveEntitlement(CommerceEntitlement entitlement);
}

/// Derive wallet balances from an append-only ledger (never mutate entries).
WalletProjection projectWalletFromLedger({
  required String userId,
  required List<LedgerEntry> entries,
}) {
  var premium = 0;
  var earned = 0;
  for (final e in entries) {
    switch (e.currency) {
      case CurrencyKind.premium:
        premium += e.signedDelta;
      case CurrencyKind.earned:
        earned += e.signedDelta;
    }
  }
  return WalletProjection(
    userId: userId,
    premium: premium,
    earned: earned,
  );
}

/// External payment confirmation port (fake now; Steam microtxn later).
abstract class PaymentProvider {
  /// Confirms an external payment for [orderId]. Idempotent on [idempotencyKey].
  Future<PaymentSettlement> settle({
    required String orderId,
    required String idempotencyKey,
  });
}
