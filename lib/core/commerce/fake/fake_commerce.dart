import '../commerce_catalog.dart';
import '../commerce_models.dart';
import '../commerce_ports.dart';

class FakeCommerceRepository implements CommerceRepository {
  final Map<String, CommerceProduct> products = {
    for (final p in CommerceCatalog.all) p.id: p,
  };
  final Map<String, CommerceOrder> ordersById = {};
  final Map<String, CommerceOrder> ordersByIdempotency = {};
  final List<LedgerEntry> ledger = [];
  final Map<String, LedgerEntry> ledgerByIdempotency = {};
  final Map<String, CommerceEntitlement> entitlementsByUserKey = {};
  final Map<String, CommerceEntitlement> entitlementsByIdempotency = {};

  @override
  Future<CommerceProduct?> getProduct(String productId) async =>
      products[productId];

  @override
  Future<CommerceOrder?> getOrder(String orderId) async => ordersById[orderId];

  @override
  Future<CommerceOrder?> findOrderByIdempotencyKey(
    String idempotencyKey,
  ) async => ordersByIdempotency[idempotencyKey];

  @override
  Future<void> saveOrder(CommerceOrder order) async {
    ordersById[order.id] = order;
    ordersByIdempotency[order.idempotencyKey] = order;
  }

  @override
  Future<LedgerEntry?> findLedgerByIdempotencyKey(
    String idempotencyKey,
  ) async => ledgerByIdempotency[idempotencyKey];

  @override
  Future<void> appendLedger(LedgerEntry entry) async {
    if (ledgerByIdempotency.containsKey(entry.idempotencyKey)) {
      return;
    }
    ledger.add(entry);
    ledgerByIdempotency[entry.idempotencyKey] = entry;
  }

  @override
  Future<List<LedgerEntry>> listLedger(String userId) async =>
      ledger.where((e) => e.userId == userId).toList(growable: false);

  @override
  Future<CommerceEntitlement?> findEntitlement({
    required String userId,
    required String key,
  }) async => entitlementsByUserKey['$userId::$key'];

  @override
  Future<CommerceEntitlement?> findEntitlementByIdempotencyKey(
    String idempotencyKey,
  ) async => entitlementsByIdempotency[idempotencyKey];

  @override
  Future<void> saveEntitlement(CommerceEntitlement entitlement) async {
    entitlementsByUserKey['${entitlement.userId}::${entitlement.key}'] =
        entitlement;
    entitlementsByIdempotency[entitlement.idempotencyKey] = entitlement;
  }
}

class FakePaymentProvider implements PaymentProvider {
  FakePaymentProvider({this.succeed = true});

  bool succeed;
  final Set<String> settledKeys = {};
  int settleCalls = 0;

  @override
  Future<PaymentSettlement> settle({
    required String orderId,
    required String idempotencyKey,
  }) async {
    settleCalls++;
    if (settledKeys.contains(idempotencyKey)) {
      return PaymentSettlement(
        externalPaymentId: 'pay_$idempotencyKey',
        orderId: orderId,
        succeeded: true,
      );
    }
    settledKeys.add(idempotencyKey);
    return PaymentSettlement(
      externalPaymentId: 'pay_$idempotencyKey',
      orderId: orderId,
      succeeded: succeed,
    );
  }
}
