import 'package:akasha/core/commerce/commerce.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('production Steam ItemDef registry', () {
    test('maps only approved launch products to production ItemDefs', () {
      expect(SteamInventoryItemDefs.pricedPackByProductId, {
        CommerceCatalog.astraPack500ProductId: 40110,
        CommerceCatalog.astraPack1000ProductId: 40111,
        CommerceCatalog.astraPack2500ProductId: 40112,
      });
      expect(SteamInventoryItemDefs.entitlementKeyByItemDef, {
        41001: CommerceCatalog.sakuraThemeEntitlementKey,
        41002: CommerceCatalog.amethystThemeEntitlementKey,
        41003: CommerceCatalog.nocturneThemeEntitlementKey,
      });
      expect(SteamInventoryItemDefs.retiredPocItemDefs, contains(10001));
      expect(SteamInventoryItemDefs.retiredPocItemDefs, contains(20001));
      expect(SteamInventoryItemDefs.productIdByPricedPack[10010], isNull);
      expect(SteamInventoryItemDefs.entitlementKeyByItemDef[20001], isNull);
    });
  });

  group('SteamInventoryCommerceGateway', () {
    test(
      'loads balances, entitlements, and approved localized prices',
      () async {
        final observedAt = DateTime.utc(2026, 7, 15, 5, 30);
        final port = _FakeSteamInventoryReadPort(
          items: SteamInventoryItemsResult(
            status: SteamInventoryReadStatus.success,
            observedAt: observedAt,
            items: const [
              SteamInventoryReadItem(itemDefId: 40001, quantity: 300),
              SteamInventoryReadItem(itemDefId: 40001, quantity: 400),
              SteamInventoryReadItem(itemDefId: 40002, quantity: 50),
              SteamInventoryReadItem(itemDefId: 41003, quantity: 1),
              SteamInventoryReadItem(itemDefId: 10001, quantity: 9999),
              SteamInventoryReadItem(itemDefId: 20001, quantity: 1),
            ],
          ),
          prices: const SteamInventoryPricesResult(
            status: SteamInventoryReadStatus.success,
            currencyCode: 'KRW',
            prices: [
              SteamInventoryPriceRow(
                itemDefId: 40110,
                currentAmount: 5500,
                baseAmount: 6000,
              ),
              SteamInventoryPriceRow(itemDefId: 40111, currentAmount: 11000),
              SteamInventoryPriceRow(itemDefId: 40001, currentAmount: 10),
              SteamInventoryPriceRow(itemDefId: 10010, currentAmount: 100),
            ],
          ),
        );
        final gateway = SteamInventoryCommerceGateway(port: port);

        final snapshot = await gateway.loadAccount();

        expect(snapshot.state, CommerceAuthorityState.ready);
        expect(snapshot.astraBalance, 700);
        expect(snapshot.echoBalance, 50);
        expect(snapshot.entitlementKeys, {
          CommerceCatalog.nocturneThemeEntitlementKey,
        });
        expect(snapshot.observedAt, observedAt);
        expect(snapshot.transactionsEnabled, isFalse);
        expect(snapshot.canTransact, isFalse);
        expect(snapshot.priceIssueCode, isNull);
        expect(snapshot.localizedPrices, hasLength(2));
        expect(
          snapshot.priceOf(CommerceCatalog.astraPack500ProductId)?.currencyCode,
          'KRW',
        );
        expect(
          snapshot
              .priceOf(CommerceCatalog.astraPack500ProductId)
              ?.currentAmount,
          5500,
        );
        expect(
          snapshot.priceOf(CommerceCatalog.astraPack500ProductId)?.baseAmount,
          6000,
        );
        expect(port.diagnosticCalls, 1);
        expect(port.inventoryCalls, 1);
        expect(port.priceCalls, 1);
      },
    );

    test(
      'keeps a valid account when localized prices are unavailable',
      () async {
        final gateway = SteamInventoryCommerceGateway(
          port: _FakeSteamInventoryReadPort(
            items: const SteamInventoryItemsResult(
              status: SteamInventoryReadStatus.success,
              items: [
                SteamInventoryReadItem(itemDefId: 40001, quantity: 5),
                SteamInventoryReadItem(itemDefId: 40002, quantity: 6),
              ],
            ),
            prices: const SteamInventoryPricesResult(
              status: SteamInventoryReadStatus.failed,
              issueCode: 'steam_prices_timeout',
            ),
          ),
        );

        final snapshot = await gateway.loadAccount();

        expect(snapshot.state, CommerceAuthorityState.ready);
        expect(snapshot.astraBalance, 5);
        expect(snapshot.echoBalance, 6);
        expect(snapshot.localizedPrices, isEmpty);
        expect(snapshot.priceIssueCode, 'steam_prices_timeout');
      },
    );

    test('offline authority never turns unknown balances into zero', () async {
      final port = _FakeSteamInventoryReadPort(
        diagnostic: const SteamInventoryDiagnostic(
          status: SteamInventoryReadStatus.offline,
          appId: 4677560,
          issueCode: 'steam_offline',
        ),
      );
      final gateway = SteamInventoryCommerceGateway(port: port);

      final snapshot = await gateway.loadAccount();

      expect(snapshot.state, CommerceAuthorityState.unavailable);
      expect(snapshot.astraBalance, isNull);
      expect(snapshot.echoBalance, isNull);
      expect(snapshot.issueCode, 'steam_offline');
      expect(port.inventoryCalls, 0);
      expect(port.priceCalls, 0);
    });

    test(
      'offline refresh preserves a prior provider snapshot as cache',
      () async {
        final port = _FakeSteamInventoryReadPort(
          items: const SteamInventoryItemsResult(
            status: SteamInventoryReadStatus.success,
            items: [
              SteamInventoryReadItem(itemDefId: 40001, quantity: 20),
              SteamInventoryReadItem(itemDefId: 40002, quantity: 30),
              SteamInventoryReadItem(itemDefId: 41001, quantity: 1),
            ],
          ),
        );
        final gateway = SteamInventoryCommerceGateway(port: port);
        await gateway.loadAccount();
        port.diagnosticResult = const SteamInventoryDiagnostic(
          status: SteamInventoryReadStatus.offline,
          appId: 4677560,
          issueCode: 'steam_offline',
        );

        final cached = await gateway.loadAccount();

        expect(cached.state, CommerceAuthorityState.offlineCache);
        expect(cached.astraBalance, 20);
        expect(cached.echoBalance, 30);
        expect(cached.owns(CommerceCatalog.sakuraThemeEntitlementKey), isTrue);
        expect(cached.canTransact, isFalse);
        expect(cached.issueCode, 'steam_offline');
      },
    );

    test('rejects a diagnostic from a different Steam AppID', () async {
      final port = _FakeSteamInventoryReadPort(
        diagnostic: const SteamInventoryDiagnostic(
          status: SteamInventoryReadStatus.success,
          appId: 480,
        ),
      );
      final gateway = SteamInventoryCommerceGateway(port: port);

      final snapshot = await gateway.loadAccount();

      expect(snapshot.state, CommerceAuthorityState.unavailable);
      expect(snapshot.issueCode, 'steam_app_id_mismatch');
      expect(snapshot.astraBalance, isNull);
      expect(port.inventoryCalls, 0);
    });

    test(
      'mutating methods are rejected without touching the read port',
      () async {
        final port = _FakeSteamInventoryReadPort();
        final gateway = SteamInventoryCommerceGateway(port: port);

        final purchase = await gateway.purchaseAstraPack(
          productId: CommerceCatalog.astraPack500ProductId,
        );
        final exchange = await gateway.exchangeProduct(
          productId: CommerceCatalog.sakuraThemeProductId,
          payWith: CurrencyKind.premium,
        );

        expect(purchase.status, CommerceOperationStatus.rejected);
        expect(purchase.issueCode, 'steam_commerce_read_only');
        expect(exchange.status, CommerceOperationStatus.rejected);
        expect(exchange.issueCode, 'steam_commerce_read_only');
        expect(port.diagnosticCalls, 0);
        expect(port.inventoryCalls, 0);
        expect(port.priceCalls, 0);
      },
    );
  });

  group('MethodChannelSteamInventoryReadPort parsing', () {
    test('preserves Steam currency and raw current/base amounts', () {
      final result = MethodChannelSteamInventoryReadPort.parsePrices({
        'ok': true,
        'currencyCode': 'krw',
        'prices': [
          {'itemDefId': 40110, 'priceAmount': 5500, 'basePriceAmount': 6000},
        ],
      });

      expect(result.status, SteamInventoryReadStatus.success);
      expect(result.currencyCode, 'KRW');
      expect(result.prices.single.currentAmount, 5500);
      expect(result.prices.single.baseAmount, 6000);
    });

    test('rejects a price response without a currency code', () {
      final result = MethodChannelSteamInventoryReadPort.parsePrices({
        'ok': true,
        'prices': const [],
      });

      expect(result.status, SteamInventoryReadStatus.failed);
      expect(result.issueCode, 'steam_currency_code_missing');
    });

    test('maps native offline inventory failure explicitly', () {
      final result = MethodChannelSteamInventoryReadPort.parseItems({
        'ok': false,
        'code': 'offline',
      });

      expect(result.status, SteamInventoryReadStatus.offline);
      expect(result.issueCode, 'steam_offline');
      expect(result.items, isEmpty);
    });
  });
}

class _FakeSteamInventoryReadPort implements SteamInventoryReadPort {
  _FakeSteamInventoryReadPort({
    SteamInventoryDiagnostic diagnostic = const SteamInventoryDiagnostic(
      status: SteamInventoryReadStatus.success,
      appId: 4677560,
    ),
    this.items = const SteamInventoryItemsResult(
      status: SteamInventoryReadStatus.success,
    ),
    this.prices = const SteamInventoryPricesResult(
      status: SteamInventoryReadStatus.success,
      currencyCode: 'USD',
    ),
  }) : diagnosticResult = diagnostic;

  SteamInventoryDiagnostic diagnosticResult;
  final SteamInventoryItemsResult items;
  final SteamInventoryPricesResult prices;
  int diagnosticCalls = 0;
  int inventoryCalls = 0;
  int priceCalls = 0;

  @override
  Future<SteamInventoryDiagnostic> diagnostic() async {
    diagnosticCalls += 1;
    return diagnosticResult;
  }

  @override
  Future<SteamInventoryItemsResult> getAllItems() async {
    inventoryCalls += 1;
    return items;
  }

  @override
  Future<SteamInventoryPricesResult> requestPrices() async {
    priceCalls += 1;
    return prices;
  }
}
