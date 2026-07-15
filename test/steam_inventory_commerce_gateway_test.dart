import 'package:akasha/core/commerce/commerce.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
              SteamInventoryReadItem(
                instanceId: '1',
                itemDefId: 40001,
                quantity: 300,
              ),
              SteamInventoryReadItem(
                instanceId: '2',
                itemDefId: 40001,
                quantity: 400,
              ),
              SteamInventoryReadItem(
                instanceId: '3',
                itemDefId: 40002,
                quantity: 50,
              ),
              SteamInventoryReadItem(
                instanceId: '4',
                itemDefId: 41003,
                quantity: 1,
              ),
              SteamInventoryReadItem(
                instanceId: '5',
                itemDefId: 10001,
                quantity: 9999,
              ),
              SteamInventoryReadItem(
                instanceId: '6',
                itemDefId: 20001,
                quantity: 1,
              ),
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
                SteamInventoryReadItem(
                  instanceId: '1',
                  itemDefId: 40001,
                  quantity: 5,
                ),
                SteamInventoryReadItem(
                  instanceId: '2',
                  itemDefId: 40002,
                  quantity: 6,
                ),
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
              SteamInventoryReadItem(
                instanceId: '1',
                itemDefId: 40001,
                quantity: 20,
              ),
              SteamInventoryReadItem(
                instanceId: '2',
                itemDefId: 40002,
                quantity: 30,
              ),
              SteamInventoryReadItem(
                instanceId: '3',
                itemDefId: 41001,
                quantity: 1,
              ),
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

  group('SteamInventoryCommerceGateway transactions', () {
    test(
      'enables transactions only with an explicit transaction port',
      () async {
        final gateway = SteamInventoryCommerceGateway(
          port: _FakeSteamInventoryReadPort(
            items: _inventory([
              _item('1', SteamInventoryItemDefs.astraUnit, 500),
              _item('2', SteamInventoryItemDefs.echoUnit, 500),
            ]),
          ),
          transactionPort: _FakeSteamInventoryTransactionPort(),
          transactionsEnabled: true,
        );

        final snapshot = await gateway.loadAccount();

        expect(snapshot.canTransact, isTrue);
        expect(snapshot.transactionsEnabled, isTrue);
      },
    );

    test(
      'confirms an Astra purchase only after inventory delta appears',
      () async {
        final readPort = _FakeSteamInventoryReadPort(
          itemSequence: [
            _inventory([
              _item('10', SteamInventoryItemDefs.astraUnit, 100),
              _item('20', SteamInventoryItemDefs.echoUnit, 0),
            ]),
            _inventory([
              _item('11', SteamInventoryItemDefs.astraUnit, 600),
              _item('20', SteamInventoryItemDefs.echoUnit, 0),
            ]),
          ],
        );
        final transactionPort = _FakeSteamInventoryTransactionPort(
          purchaseResult: const SteamInventoryTransactionResult(
            status: SteamInventoryTransactionStatus.confirmed,
            providerHandle: 'purchase_1',
            orderId: '9001',
            transactionId: '8001',
          ),
        );
        final gateway = SteamInventoryCommerceGateway(
          port: readPort,
          transactionPort: transactionPort,
          transactionsEnabled: true,
        );
        await gateway.loadAccount();

        final result = await gateway.purchaseAstraPack(
          productId: CommerceCatalog.astraPack500ProductId,
        );

        expect(result.status, CommerceOperationStatus.confirmed);
        expect(result.providerHandle, 'purchase_1');
        expect(result.providerOrderId, '9001');
        expect(result.providerTransactionId, '8001');
        expect(result.snapshot.astraBalance, 600);
        expect(result.snapshot.canTransact, isTrue);
        expect(transactionPort.purchaseItemDefIds, [40110]);
        expect(readPort.inventoryCalls, 2);
      },
    );

    test(
      'blocks retry when a confirmed callback has no inventory outcome',
      () async {
        final readPort = _FakeSteamInventoryReadPort(
          itemSequence: [
            _inventory([
              _item('10', SteamInventoryItemDefs.astraUnit, 100),
              _item('20', SteamInventoryItemDefs.echoUnit, 0),
            ]),
            _inventory([
              _item('10', SteamInventoryItemDefs.astraUnit, 100),
              _item('20', SteamInventoryItemDefs.echoUnit, 0),
            ]),
          ],
        );
        final transactionPort = _FakeSteamInventoryTransactionPort(
          purchaseResult: const SteamInventoryTransactionResult(
            status: SteamInventoryTransactionStatus.confirmed,
            providerHandle: 'purchase_2',
          ),
        );
        final gateway = SteamInventoryCommerceGateway(
          port: readPort,
          transactionPort: transactionPort,
          transactionsEnabled: true,
        );
        await gateway.loadAccount();

        final result = await gateway.purchaseAstraPack(
          productId: CommerceCatalog.astraPack500ProductId,
        );
        final retry = await gateway.purchaseAstraPack(
          productId: CommerceCatalog.astraPack500ProductId,
        );

        expect(result.status, CommerceOperationStatus.indeterminate);
        expect(result.issueCode, 'steam_reconciliation_outcome_missing');
        expect(result.snapshot.canTransact, isFalse);
        expect(retry.status, CommerceOperationStatus.rejected);
        expect(retry.issueCode, 'steam_reconciliation_required');
        expect(transactionPort.purchaseItemDefIds, [40110]);
      },
    );

    test(
      'keeps a cancelled purchase non-authoritative and retryable',
      () async {
        final inventory = _inventory([
          _item('10', SteamInventoryItemDefs.astraUnit, 100),
          _item('20', SteamInventoryItemDefs.echoUnit, 0),
        ]);
        final transactionPort = _FakeSteamInventoryTransactionPort(
          purchaseResult: const SteamInventoryTransactionResult(
            status: SteamInventoryTransactionStatus.cancelled,
            providerHandle: 'purchase_3',
            issueCode: 'steam_cancelled',
          ),
        );
        final gateway = SteamInventoryCommerceGateway(
          port: _FakeSteamInventoryReadPort(
            itemSequence: [inventory, inventory],
          ),
          transactionPort: transactionPort,
          transactionsEnabled: true,
        );
        await gateway.loadAccount();

        final result = await gateway.purchaseAstraPack(
          productId: CommerceCatalog.astraPack500ProductId,
        );

        expect(result.status, CommerceOperationStatus.cancelled);
        expect(result.snapshot.astraBalance, 100);
        expect(result.snapshot.canTransact, isTrue);
      },
    );

    test(
      'exchanges one currency using real instance ids and then owns theme',
      () async {
        final readPort = _FakeSteamInventoryReadPort(
          itemSequence: [
            _inventory([
              _item('101', SteamInventoryItemDefs.astraUnit, 300),
              _item('102', SteamInventoryItemDefs.astraUnit, 250),
              _item('201', SteamInventoryItemDefs.echoUnit, 900),
            ]),
            _inventory([
              _item('102', SteamInventoryItemDefs.astraUnit, 50),
              _item('201', SteamInventoryItemDefs.echoUnit, 900),
              _item('301', SteamInventoryItemDefs.sakuraThemeEntitlement, 1),
            ]),
          ],
        );
        final transactionPort = _FakeSteamInventoryTransactionPort(
          exchangeResult: const SteamInventoryTransactionResult(
            status: SteamInventoryTransactionStatus.confirmed,
            providerHandle: 'exchange_1',
          ),
        );
        final gateway = SteamInventoryCommerceGateway(
          port: readPort,
          transactionPort: transactionPort,
          transactionsEnabled: true,
        );
        await gateway.loadAccount();

        final result = await gateway.exchangeProduct(
          productId: CommerceCatalog.sakuraThemeProductId,
          payWith: CurrencyKind.premium,
        );

        expect(result.status, CommerceOperationStatus.confirmed);
        expect(
          result.snapshot.owns(CommerceCatalog.sakuraThemeEntitlementKey),
          isTrue,
        );
        expect(transactionPort.exchangeGenerateItemDefIds, [41101]);
        expect(transactionPort.exchangeDestroyItems.single, [
          const SteamInventoryDestroyItem(instanceId: '101', quantity: 300),
          const SteamInventoryDestroyItem(instanceId: '102', quantity: 200),
        ]);
      },
    );

    test('rejects insufficient currency before calling Steam', () async {
      final transactionPort = _FakeSteamInventoryTransactionPort();
      final gateway = SteamInventoryCommerceGateway(
        port: _FakeSteamInventoryReadPort(
          items: _inventory([
            _item('1', SteamInventoryItemDefs.astraUnit, 499),
            _item('2', SteamInventoryItemDefs.echoUnit, 900),
          ]),
        ),
        transactionPort: transactionPort,
        transactionsEnabled: true,
      );
      await gateway.loadAccount();

      final result = await gateway.exchangeProduct(
        productId: CommerceCatalog.nocturneThemeProductId,
        payWith: CurrencyKind.premium,
      );

      expect(result.status, CommerceOperationStatus.rejected);
      expect(result.issueCode, 'steam_insufficient_currency');
      expect(transactionPort.exchangeGenerateItemDefIds, isEmpty);
    });

    test('rejects a duplicate theme exchange before calling Steam', () async {
      final transactionPort = _FakeSteamInventoryTransactionPort();
      final gateway = SteamInventoryCommerceGateway(
        port: _FakeSteamInventoryReadPort(
          items: _inventory([
            _item('1', SteamInventoryItemDefs.astraUnit, 900),
            _item('2', SteamInventoryItemDefs.echoUnit, 900),
            _item('3', SteamInventoryItemDefs.nocturneThemeEntitlement, 1),
          ]),
        ),
        transactionPort: transactionPort,
        transactionsEnabled: true,
      );
      await gateway.loadAccount();

      final result = await gateway.exchangeProduct(
        productId: CommerceCatalog.nocturneThemeProductId,
        payWith: CurrencyKind.earned,
      );

      expect(result.status, CommerceOperationStatus.rejected);
      expect(result.issueCode, 'steam_theme_already_owned');
      expect(transactionPort.exchangeGenerateItemDefIds, isEmpty);
    });
  });

  group('MethodChannelSteamInventoryTransactionPort', () {
    const channel = MethodChannel('akasha/test/steam_transactions');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'waits past pending and unrelated events for matching completion',
      () async {
        var pollCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'startPurchase') {
                return <String, Object?>{
                  'ok': true,
                  'status': 'pending',
                  'handle': 'purchase_10',
                };
              }
              if (call.method == 'poll') {
                pollCount += 1;
                if (pollCount == 1) {
                  return <String, Object?>{
                    'ok': true,
                    'ops': [
                      {'status': 'success', 'handle': 'load_1'},
                      {
                        'status': 'pending',
                        'handle': 'purchase_10',
                        'orderId': '90010',
                        'transactionId': '80010',
                      },
                    ],
                  };
                }
                return <String, Object?>{
                  'ok': true,
                  'ops': [
                    {
                      'status': 'success',
                      'handle': 'purchase_10',
                      'steamResultName': 'k_EResultOK',
                    },
                  ],
                };
              }
              return null;
            });
        const port = MethodChannelSteamInventoryTransactionPort(
          channel: channel,
          pollInterval: Duration.zero,
          completionTimeout: Duration(seconds: 1),
        );

        final result = await port.startPurchase(itemDefId: 40110);

        expect(result.status, SteamInventoryTransactionStatus.confirmed);
        expect(result.providerHandle, 'purchase_10');
        expect(result.orderId, '90010');
        expect(result.transactionId, '80010');
        expect(pollCount, 2);
      },
    );

    test(
      'returns one result when a poll contains duplicate terminal events',
      () async {
        var pollCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'startPurchase') {
                return <String, Object?>{
                  'ok': true,
                  'status': 'pending',
                  'handle': 'purchase_duplicate',
                };
              }
              pollCount += 1;
              return <String, Object?>{
                'ok': true,
                'ops': [
                  {
                    'status': 'success',
                    'handle': 'purchase_duplicate',
                    'steamResultName': 'k_EResultOK',
                  },
                  {
                    'status': 'success',
                    'handle': 'purchase_duplicate',
                    'steamResultName': 'k_EResultOK',
                  },
                ],
              };
            });
        const port = MethodChannelSteamInventoryTransactionPort(
          channel: channel,
          pollInterval: Duration.zero,
          completionTimeout: Duration(seconds: 1),
        );

        final result = await port.startPurchase(itemDefId: 40110);

        expect(result.status, SteamInventoryTransactionStatus.confirmed);
        expect(result.providerHandle, 'purchase_duplicate');
        expect(pollCount, 1);
      },
    );

    test('maps cancellation and provider rejection without a local grant', () {
      final cancelled =
          MethodChannelSteamInventoryTransactionPort.parseOperation({
            'status': 'canceled',
            'handle': 'purchase_11',
            'steamResultName': 'k_EResultCancelled',
          });
      final insufficient =
          MethodChannelSteamInventoryTransactionPort.parseOperation({
            'status': 'failed',
            'handle': 'exchange_11',
            'steamResultName': 'k_EResultInsufficientFunds',
          });

      expect(cancelled.status, SteamInventoryTransactionStatus.cancelled);
      expect(cancelled.issueCode, 'steam_cancelled');
      expect(insufficient.status, SteamInventoryTransactionStatus.rejected);
      expect(insufficient.issueCode, 'steam_insufficient_funds');
    });

    test('timeout after API acceptance is indeterminate', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'startPurchase') {
              return <String, Object?>{
                'ok': true,
                'status': 'pending',
                'handle': 'purchase_12',
              };
            }
            return <String, Object?>{'ok': true, 'ops': const []};
          });
      const port = MethodChannelSteamInventoryTransactionPort(
        channel: channel,
        pollInterval: Duration.zero,
        completionTimeout: Duration.zero,
      );

      final result = await port.startPurchase(itemDefId: 40110);

      expect(result.status, SteamInventoryTransactionStatus.indeterminate);
      expect(result.issueCode, 'steam_transaction_timeout');
    });
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

    test('preserves numeric instance ids required for exchange allocation', () {
      final result = MethodChannelSteamInventoryReadPort.parseItems({
        'ok': true,
        'items': [
          {
            'instanceId': '18446744073709551615',
            'itemDefId': 40001,
            'quantity': 7,
          },
          {'itemDefId': 40001, 'quantity': 99},
        ],
      });

      expect(result.items, hasLength(1));
      expect(result.items.single.instanceId, '18446744073709551615');
      expect(result.items.single.quantity, 7);
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
    this.itemSequence,
    this.prices = const SteamInventoryPricesResult(
      status: SteamInventoryReadStatus.success,
      currencyCode: 'USD',
    ),
  }) : diagnosticResult = diagnostic;

  SteamInventoryDiagnostic diagnosticResult;
  final SteamInventoryItemsResult items;
  final List<SteamInventoryItemsResult>? itemSequence;
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
    final sequence = itemSequence;
    if (sequence != null && sequence.isNotEmpty) {
      final index = inventoryCalls - 1;
      return sequence[index < sequence.length ? index : sequence.length - 1];
    }
    return items;
  }

  @override
  Future<SteamInventoryPricesResult> requestPrices() async {
    priceCalls += 1;
    return prices;
  }
}

class _FakeSteamInventoryTransactionPort
    implements SteamInventoryTransactionPort {
  _FakeSteamInventoryTransactionPort({
    this.purchaseResult = const SteamInventoryTransactionResult(
      status: SteamInventoryTransactionStatus.failed,
      issueCode: 'steam_fake_purchase_failed',
    ),
    this.exchangeResult = const SteamInventoryTransactionResult(
      status: SteamInventoryTransactionStatus.failed,
      issueCode: 'steam_fake_exchange_failed',
    ),
  });

  final SteamInventoryTransactionResult purchaseResult;
  final SteamInventoryTransactionResult exchangeResult;
  final List<int> purchaseItemDefIds = [];
  final List<int> exchangeGenerateItemDefIds = [];
  final List<List<SteamInventoryDestroyItem>> exchangeDestroyItems = [];

  @override
  Future<SteamInventoryTransactionResult> startPurchase({
    required int itemDefId,
    int quantity = 1,
  }) async {
    purchaseItemDefIds.add(itemDefId);
    return purchaseResult;
  }

  @override
  Future<SteamInventoryTransactionResult> exchangeItems({
    required int generateItemDefId,
    required List<SteamInventoryDestroyItem> destroyItems,
  }) async {
    exchangeGenerateItemDefIds.add(generateItemDefId);
    exchangeDestroyItems.add(destroyItems);
    return exchangeResult;
  }
}

SteamInventoryItemsResult _inventory(List<SteamInventoryReadItem> items) =>
    SteamInventoryItemsResult(
      status: SteamInventoryReadStatus.success,
      items: items,
    );

SteamInventoryReadItem _item(String instanceId, int itemDefId, int quantity) =>
    SteamInventoryReadItem(
      instanceId: instanceId,
      itemDefId: itemDefId,
      quantity: quantity,
    );
