import '../commerce_models.dart';
import 'audit_record.dart';
import 'commerce_account.dart';
import 'idempotency_record.dart';
import 'order_id64.dart';
import 'reconciliation_cursor.dart';
import 'secure_commerce_models.dart';
import 'unit_of_work.dart';

/// Server persistence + transaction boundary.
abstract class SecureCommerceRepository implements CommerceUnitOfWork {
  Future<CommerceAccount> ensureAccount(String steamId);

  Future<CommerceAccount?> getAccount(String steamId);

  Future<CommerceProduct?> getProduct(String productId);

  Future<List<CommerceProduct>> listProducts();

  Future<SecureCommerceOrder?> getOrder(OrderId64 orderId);

  Future<SecureCommerceOrder?> findOrderByIdempotencyKey(String key);

  Future<void> saveOrder(SecureCommerceOrder order);

  Future<IdempotencyRecord?> getIdempotency(String scope, String key);

  Future<void> saveIdempotency(IdempotencyRecord record);

  Future<LedgerEntry?> findLedgerByIdempotencyKey(String key);

  Future<void> appendLedger(LedgerEntry entry);

  Future<List<LedgerEntry>> listLedger(String steamId);

  Future<CommerceEntitlement?> findEntitlement({
    required String steamId,
    required String key,
  });

  Future<void> saveEntitlement(CommerceEntitlement entitlement);

  Future<ReconciliationCursor?> getReconciliationCursor(String provider);

  Future<void> saveReconciliationCursor(ReconciliationCursor cursor);

  Future<void> appendAudit(CommerceAuditRecord record);

  Future<List<CommerceAuditRecord>> listAudit({String? steamId});
}
