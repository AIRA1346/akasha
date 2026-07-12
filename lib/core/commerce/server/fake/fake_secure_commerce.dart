import '../../commerce_catalog.dart';
import '../../commerce_models.dart';
import '../audit_record.dart';
import '../commerce_account.dart';
import '../idempotency_record.dart';
import '../order_id64.dart';
import '../reconciliation_cursor.dart';
import '../secure_commerce_models.dart';
import '../secure_commerce_repository.dart';
import '../steam_adapter.dart';
import '../steam_txn_phase.dart';

class FakeSecureCommerceRepository implements SecureCommerceRepository {
  FakeSecureCommerceRepository({List<CommerceProduct>? catalog})
    : products = {
        for (final p in catalog ?? CommerceCatalog.all) p.id: p,
      };

  final Map<String, CommerceProduct> products;
  final Map<String, CommerceAccount> accounts = {};
  final Map<String, SecureCommerceOrder> ordersById = {};
  final Map<String, SecureCommerceOrder> ordersByIdempotency = {};
  final Map<String, IdempotencyRecord> idempotency = {};
  final List<LedgerEntry> ledger = [];
  final Map<String, LedgerEntry> ledgerByIdempotency = {};
  final Map<String, CommerceEntitlement> entitlements = {};
  final Map<String, ReconciliationCursor> cursors = {};
  final List<CommerceAuditRecord> audits = [];
  int transactionDepth = 0;

  @override
  Future<T> runInTransaction<T>(Future<T> Function() body) async {
    transactionDepth++;
    try {
      return await body();
    } finally {
      transactionDepth--;
    }
  }

  @override
  Future<CommerceAccount> ensureAccount(String steamId) async {
    return accounts.putIfAbsent(
      steamId,
      () => CommerceAccount(
        steamId: steamId,
        createdAt: DateTime.utc(2026, 7, 12),
      ),
    );
  }

  @override
  Future<CommerceAccount?> getAccount(String steamId) async =>
      accounts[steamId];

  @override
  Future<CommerceProduct?> getProduct(String productId) async =>
      products[productId];

  @override
  Future<List<CommerceProduct>> listProducts() async =>
      products.values.toList(growable: false);

  @override
  Future<SecureCommerceOrder?> getOrder(OrderId64 orderId) async =>
      ordersById[orderId.toString()];

  @override
  Future<SecureCommerceOrder?> findOrderByIdempotencyKey(String key) async =>
      ordersByIdempotency[key];

  @override
  Future<void> saveOrder(SecureCommerceOrder order) async {
    ordersById[order.orderIdKey] = order;
    ordersByIdempotency[order.idempotencyKey] = order;
  }

  @override
  Future<IdempotencyRecord?> getIdempotency(String scope, String key) async =>
      idempotency['$scope::$key'];

  @override
  Future<void> saveIdempotency(IdempotencyRecord record) async {
    idempotency['${record.scope}::${record.key}'] = record;
  }

  @override
  Future<LedgerEntry?> findLedgerByIdempotencyKey(String key) async =>
      ledgerByIdempotency[key];

  @override
  Future<void> appendLedger(LedgerEntry entry) async {
    if (ledgerByIdempotency.containsKey(entry.idempotencyKey)) return;
    ledger.add(entry);
    ledgerByIdempotency[entry.idempotencyKey] = entry;
  }

  @override
  Future<List<LedgerEntry>> listLedger(String steamId) async =>
      ledger.where((e) => e.userId == steamId).toList(growable: false);

  @override
  Future<CommerceEntitlement?> findEntitlement({
    required String steamId,
    required String key,
  }) async => entitlements['$steamId::$key'];

  @override
  Future<void> saveEntitlement(CommerceEntitlement entitlement) async {
    entitlements['${entitlement.userId}::${entitlement.key}'] = entitlement;
  }

  @override
  Future<ReconciliationCursor?> getReconciliationCursor(
    String provider,
  ) async => cursors[provider];

  @override
  Future<void> saveReconciliationCursor(ReconciliationCursor cursor) async {
    cursors[cursor.provider] = cursor;
  }

  @override
  Future<void> appendAudit(CommerceAuditRecord record) async {
    audits.add(record);
  }

  @override
  Future<List<CommerceAuditRecord>> listAudit({String? steamId}) async {
    if (steamId == null) return List.unmodifiable(audits);
    return audits.where((a) => a.steamId == steamId).toList(growable: false);
  }
}

class FakeSteamMicroTxnAdapter implements SteamMicroTxnAdapter {
  FakeSteamMicroTxnAdapter();

  final Map<String, SteamTxnPhase> orderPhase = {};
  final List<SteamReportRow> reportQueue = [];
  bool finalizeIndeterminate = false;
  bool finalizeDenied = false;

  @override
  Future<SteamAdapterResult> initTxn({
    required String steamId,
    required String orderId,
    required String productId,
    required int premiumGrantAmount,
  }) async {
    orderPhase[orderId] = SteamTxnPhase.initAccepted;
    return const SteamAdapterResult(phase: SteamTxnPhase.initAccepted);
  }

  @override
  Future<SteamAdapterResult> finalizeTxn({
    required String steamId,
    required String orderId,
  }) async {
    if (finalizeIndeterminate) {
      orderPhase[orderId] = SteamTxnPhase.indeterminate;
      return const SteamAdapterResult(phase: SteamTxnPhase.indeterminate);
    }
    if (finalizeDenied) {
      orderPhase[orderId] = SteamTxnPhase.denied;
      return const SteamAdapterResult(phase: SteamTxnPhase.denied);
    }
    orderPhase[orderId] = SteamTxnPhase.finalizeSucceeded;
    return const SteamAdapterResult(phase: SteamTxnPhase.finalizeSucceeded);
  }

  @override
  Future<SteamAdapterResult> queryTxn({
    required String steamId,
    required String orderId,
  }) async {
    final phase = orderPhase[orderId] ?? SteamTxnPhase.indeterminate;
    return SteamAdapterResult(phase: phase);
  }

  @override
  Future<List<SteamReportRow>> getReport({
    required String cursorHighWater,
  }) async {
    final rows = List<SteamReportRow>.from(reportQueue);
    reportQueue.clear();
    return rows;
  }
}
