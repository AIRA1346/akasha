import 'dart:io';

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
              SteamInventoryPriceRow(itemDefId: 40112, currentAmount: 27500),
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
        expect(snapshot.localizedPrices, hasLength(3));
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

    test('support report classifies and sanitizes runtime paths', () async {
      final gateway = SteamInventoryCommerceGateway(
        port: _FakeSteamInventoryReadPort(
          diagnostic: const SteamInventoryDiagnostic(
            status: SteamInventoryReadStatus.success,
            appId: 4677560,
            initialized: true,
            initializationAttempted: true,
            loggedOn: true,
            subscribedApp: true,
            overlayEnabled: true,
            processUptimeMs: 12000,
            overlayFirstSampleEnabled: false,
            overlayFirstSampleElapsedMs: 25,
            overlayFirstTrueElapsedMs: 8000,
            overlayEnabledSampleCount: 9,
            overlayEnabledTransitionCount: 1,
            overlayActivatedCallbackCount: 1,
            overlayDeactivatedCallbackCount: 1,
            overlayLastCallbackElapsedMs: 11000,
            buildMode: 'Debug',
            executablePath:
                r'C:\Users\Alice\src\akasha\build\windows\x64\runner\Debug\akasha.exe',
            currentWorkingDirectory: r'C:\Users\Alice\src\akasha',
          ),
        ),
      );

      await gateway.loadAccount();
      final report = gateway.buildSupportReport();

      expect(report, contains('initializationAttempted=true'));
      expect(report, contains('processUptimeMs=12000'));
      expect(report, contains('overlayFirstSampleEnabled=false'));
      expect(report, contains('overlayFirstTrueElapsedMs=8000'));
      expect(report, contains('overlayEnabledTransitionCount=1'));
      expect(report, contains('overlayActivatedCallbackCount=1'));
      expect(report, contains('overlayDeactivatedCallbackCount=1'));
      expect(report, contains('executionEnvironment=localDebug'));
      expect(
        report,
        contains(
          r'executablePath=<repo>\build\windows\x64\runner\Debug\akasha.exe',
        ),
      );
      expect(
        report,
        contains(r'currentWorkingDirectory=<user-profile>\src\akasha'),
      );
      expect(report, isNot(contains('Alice')));
    });

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

    test('keeps account read-only when Steam Overlay is unavailable', () async {
      final gateway = SteamInventoryCommerceGateway(
        port: _FakeSteamInventoryReadPort(
          diagnostic: const SteamInventoryDiagnostic(
            status: SteamInventoryReadStatus.success,
            appId: 4677560,
            initialized: true,
            loggedOn: true,
            subscribedApp: true,
            overlayEnabled: false,
          ),
          items: _inventory([
            _item('1', SteamInventoryItemDefs.astraUnit, 500),
            _item('2', SteamInventoryItemDefs.echoUnit, 500),
          ]),
        ),
        transactionPort: _FakeSteamInventoryTransactionPort(),
        transactionsEnabled: true,
      );

      final snapshot = await gateway.loadAccount();

      expect(snapshot.state, CommerceAuthorityState.ready);
      expect(snapshot.transactionsEnabled, isFalse);
      expect(snapshot.issueCode, 'steam_overlay_unavailable');
      expect(snapshot.canTransact, isFalse);
      expect(
        gateway.buildSupportReport(),
        allOf(
          contains('overlayEnabled=false'),
          contains('transactionsEnabled=false'),
        ),
      );
    });

    test(
      'requires every approved Astra pack price before transactions',
      () async {
        final gateway = SteamInventoryCommerceGateway(
          port: _FakeSteamInventoryReadPort(
            items: _inventory([
              _item('1', SteamInventoryItemDefs.astraUnit, 500),
              _item('2', SteamInventoryItemDefs.echoUnit, 500),
            ]),
            prices: const SteamInventoryPricesResult(
              status: SteamInventoryReadStatus.success,
              currencyCode: 'USD',
              prices: [
                SteamInventoryPriceRow(
                  itemDefId: SteamInventoryItemDefs.astraPack500,
                  currentAmount: 499,
                ),
              ],
            ),
          ),
          transactionPort: _FakeSteamInventoryTransactionPort(),
          transactionsEnabled: true,
        );

        final snapshot = await gateway.loadAccount();

        expect(snapshot.transactionsEnabled, isFalse);
        expect(snapshot.issueCode, 'steam_purchase_prices_incomplete');
        expect(snapshot.priceIssueCode, 'steam_purchase_prices_incomplete');
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
      'reconciles an overlay-closed purchase as cancelled and retryable',
      () async {
        final inventory = _inventory([
          _item('10', SteamInventoryItemDefs.astraUnit, 100),
          _item('20', SteamInventoryItemDefs.echoUnit, 0),
        ]);
        final transactionPort = _FakeSteamInventoryTransactionPort(
          purchaseResult: const SteamInventoryTransactionResult(
            status: SteamInventoryTransactionStatus.indeterminate,
            providerHandle: 'purchase_overlay_cancelled',
            phase: 'purchase_overlay_closed_grace_elapsed',
            issueCode: 'steam_purchase_overlay_closed',
          ),
        );
        final gateway = SteamInventoryCommerceGateway(
          port: _FakeSteamInventoryReadPort(
            itemSequence: [inventory, inventory, inventory],
          ),
          transactionPort: transactionPort,
          transactionsEnabled: true,
        );
        await gateway.loadAccount();

        final first = await gateway.purchaseAstraPack(
          productId: CommerceCatalog.astraPack500ProductId,
        );
        final retry = await gateway.purchaseAstraPack(
          productId: CommerceCatalog.astraPack500ProductId,
        );

        expect(first.status, CommerceOperationStatus.cancelled);
        expect(first.issueCode, isNull);
        expect(first.snapshot.astraBalance, 100);
        expect(first.snapshot.canTransact, isTrue);
        expect(retry.status, CommerceOperationStatus.cancelled);
        expect(transactionPort.purchaseItemDefIds, [40110, 40110]);
      },
    );

    test('late purchase outcome wins over the overlay-closed hint', () async {
      final transactionPort = _FakeSteamInventoryTransactionPort(
        purchaseResult: const SteamInventoryTransactionResult(
          status: SteamInventoryTransactionStatus.indeterminate,
          providerHandle: 'purchase_overlay_late_success',
          issueCode: 'steam_purchase_overlay_closed',
        ),
      );
      final gateway = SteamInventoryCommerceGateway(
        port: _FakeSteamInventoryReadPort(
          itemSequence: [
            _inventory([_item('10', SteamInventoryItemDefs.astraUnit, 100)]),
            _inventory([_item('10', SteamInventoryItemDefs.astraUnit, 600)]),
          ],
        ),
        transactionPort: transactionPort,
        transactionsEnabled: true,
      );
      await gateway.loadAccount();

      final result = await gateway.purchaseAstraPack(
        productId: CommerceCatalog.astraPack500ProductId,
      );

      expect(result.status, CommerceOperationStatus.confirmed);
      expect(result.snapshot.astraBalance, 600);
      expect(result.providerHandle, 'purchase_overlay_late_success');
    });

    test(
      'reconciliation failure releases purchase and a later refresh restores retry',
      () async {
        final inventory = _inventory([
          _item('10', SteamInventoryItemDefs.astraUnit, 100),
        ]);
        final readPort = _FakeSteamInventoryReadPort(
          itemSequence: [
            inventory,
            const SteamInventoryItemsResult(
              status: SteamInventoryReadStatus.failed,
              issueCode: 'steam_inventory_read_failed',
            ),
            inventory,
          ],
        );
        final gateway = SteamInventoryCommerceGateway(
          port: readPort,
          transactionPort: _FakeSteamInventoryTransactionPort(
            purchaseResult: const SteamInventoryTransactionResult(
              status: SteamInventoryTransactionStatus.indeterminate,
              providerHandle: 'purchase_reconcile_failed',
              issueCode: 'steam_purchase_overlay_closed',
            ),
          ),
          transactionsEnabled: true,
        );
        await gateway.loadAccount();

        final result = await gateway.purchaseAstraPack(
          productId: CommerceCatalog.astraPack500ProductId,
        );

        expect(result.status, CommerceOperationStatus.indeterminate);
        expect(result.issueCode, 'steam_purchase_reconciliation_failed');
        expect(result.snapshot.canTransact, isFalse);

        final refreshed = await gateway.loadAccount();
        expect(refreshed.canTransact, isTrue);
      },
    );

    test(
      'bounded purchase timeout reconciles without latching retry',
      () async {
        final inventory = _inventory([
          _item('10', SteamInventoryItemDefs.astraUnit, 100),
        ]);
        final transactionPort = _FakeSteamInventoryTransactionPort(
          purchaseResult: const SteamInventoryTransactionResult(
            status: SteamInventoryTransactionStatus.indeterminate,
            providerHandle: 'purchase_timeout',
            issueCode: 'steam_transaction_timeout',
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

        expect(result.status, CommerceOperationStatus.indeterminate);
        expect(result.issueCode, 'steam_transaction_timeout');
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

  group('SteamInventoryCommerceGateway playtime rewards', () {
    test('confirms ten Echo only after inventory reconciliation', () async {
      final readPort = _FakeSteamInventoryReadPort(
        itemSequence: [
          _inventory([
            _item('1', SteamInventoryItemDefs.astraUnit, 0),
            _item('2', SteamInventoryItemDefs.echoUnit, 40),
          ]),
          _inventory([
            _item('1', SteamInventoryItemDefs.astraUnit, 0),
            _item('2', SteamInventoryItemDefs.echoUnit, 50),
          ]),
        ],
      );
      final rewardPort = _FakeSteamInventoryRewardPort(
        result: const SteamInventoryRewardResult(
          status: SteamInventoryRewardStatus.granted,
          providerHandle: 'drop_1',
          reportedGrantQuantity: 10,
        ),
      );
      final gateway = SteamInventoryCommerceGateway(
        port: readPort,
        rewardPort: rewardPort,
        playtimeRewardsEnabled: true,
      );

      final initial = await gateway.loadAccount();
      final result = await gateway.claimPlaytimeReward();

      expect(initial.canClaimPlaytimeReward, isTrue);
      expect(result.status, CommerceOperationStatus.confirmed);
      expect(result.snapshot.echoBalance, 50);
      expect(result.providerHandle, 'drop_1');
      expect(rewardPort.generatorItemDefIds, [40220]);
      expect(rewardPort.expectedItemDefIds, [40002]);
    });

    test('empty eligible result is a safe no-change outcome', () async {
      final inventory = _inventory([
        _item('1', SteamInventoryItemDefs.astraUnit, 0),
        _item('2', SteamInventoryItemDefs.echoUnit, 40),
      ]);
      final gateway = SteamInventoryCommerceGateway(
        port: _FakeSteamInventoryReadPort(itemSequence: [inventory, inventory]),
        rewardPort: _FakeSteamInventoryRewardPort(
          result: const SteamInventoryRewardResult(
            status: SteamInventoryRewardStatus.notEligible,
            providerHandle: 'drop_2',
            issueCode: 'steam_reward_not_eligible',
          ),
        ),
        playtimeRewardsEnabled: true,
      );
      await gateway.loadAccount();

      final result = await gateway.claimPlaytimeReward();

      expect(result.status, CommerceOperationStatus.noChange);
      expect(result.snapshot.echoBalance, 40);
      expect(result.snapshot.canClaimPlaytimeReward, isTrue);
    });

    test('reported grant without Echo delta blocks repeat mutations', () async {
      final inventory = _inventory([
        _item('1', SteamInventoryItemDefs.astraUnit, 500),
        _item('2', SteamInventoryItemDefs.echoUnit, 40),
      ]);
      final rewardPort = _FakeSteamInventoryRewardPort(
        result: const SteamInventoryRewardResult(
          status: SteamInventoryRewardStatus.granted,
          providerHandle: 'drop_3',
          reportedGrantQuantity: 10,
        ),
      );
      final gateway = SteamInventoryCommerceGateway(
        port: _FakeSteamInventoryReadPort(itemSequence: [inventory, inventory]),
        transactionPort: _FakeSteamInventoryTransactionPort(),
        rewardPort: rewardPort,
        transactionsEnabled: true,
        playtimeRewardsEnabled: true,
      );
      await gateway.loadAccount();

      final result = await gateway.claimPlaytimeReward();
      final retry = await gateway.claimPlaytimeReward();
      final purchase = await gateway.purchaseAstraPack(
        productId: CommerceCatalog.astraPack500ProductId,
      );

      expect(result.status, CommerceOperationStatus.indeterminate);
      expect(result.snapshot.canClaimPlaytimeReward, isFalse);
      expect(result.snapshot.canTransact, isFalse);
      expect(retry.issueCode, 'steam_reconciliation_required');
      expect(purchase.issueCode, 'steam_reconciliation_required');
      expect(rewardPort.generatorItemDefIds, [40220]);
    });
  });

  group('MethodChannelSteamInventoryRewardPort', () {
    const channel = MethodChannel('akasha/test/steam_rewards');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'rejects retired or mismatched reward ItemDefs before native call',
      () async {
        var nativeCalls = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              nativeCalls += 1;
              return null;
            });
        const port = MethodChannelSteamInventoryRewardPort(channel: channel);

        final retired = await port.triggerPlaytimeReward(
          generatorItemDefId: 10020,
          expectedItemDefId: 10002,
        );
        final mismatched = await port.triggerPlaytimeReward(
          generatorItemDefId: 40220,
          expectedItemDefId: 10002,
        );

        expect(retired.status, SteamInventoryRewardStatus.rejected);
        expect(retired.issueCode, 'steam_reward_itemdef_not_allowed');
        expect(mismatched.status, SteamInventoryRewardStatus.rejected);
        expect(mismatched.issueCode, 'steam_reward_itemdef_not_allowed');
        expect(nativeCalls, 0);
      },
    );

    test('maps a matching Echo grant from ResultReady', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'triggerItemDrop') {
              expect(call.arguments, {'generatorDefId': 40220});
              return <String, Object?>{
                'ok': true,
                'status': 'pending',
                'handle': 'playtimeDrop_1',
              };
            }
            return <String, Object?>{
              'ok': true,
              'ops': [
                {
                  'status': 'success',
                  'handle': 'playtimeDrop_1',
                  'steamResultName': 'k_EResultOK',
                  'grantedItems': [
                    {'itemDefId': 40002, 'quantity': 10},
                  ],
                },
              ],
            };
          });
      const port = MethodChannelSteamInventoryRewardPort(
        channel: channel,
        pollInterval: Duration.zero,
        completionTimeout: Duration(seconds: 1),
      );

      final result = await port.triggerPlaytimeReward(
        generatorItemDefId: 40220,
        expectedItemDefId: 40002,
      );

      expect(result.status, SteamInventoryRewardStatus.granted);
      expect(result.reportedGrantQuantity, 10);
      expect(result.providerHandle, 'playtimeDrop_1');
    });

    test('maps a successful empty result to not eligible', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'triggerItemDrop') {
              return <String, Object?>{
                'ok': true,
                'status': 'pending',
                'handle': 'playtimeDrop_2',
              };
            }
            return <String, Object?>{
              'ok': true,
              'ops': [
                {
                  'status': 'success',
                  'handle': 'playtimeDrop_2',
                  'steamResultName': 'k_EResultOK',
                  'grantedItems': const [],
                },
              ],
            };
          });
      const port = MethodChannelSteamInventoryRewardPort(
        channel: channel,
        pollInterval: Duration.zero,
        completionTimeout: Duration(seconds: 1),
      );

      final result = await port.triggerPlaytimeReward(
        generatorItemDefId: 40220,
        expectedItemDefId: 40002,
      );

      expect(result.status, SteamInventoryRewardStatus.notEligible);
      expect(result.reportedGrantQuantity, 0);
    });
  });

  group('MethodChannelSteamInventoryTransactionPort', () {
    const channel = MethodChannel('akasha/test/steam_transactions');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('rejects raw currency and POC ItemDefs before native call', () async {
      var nativeCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            nativeCalls += 1;
            return null;
          });
      const port = MethodChannelSteamInventoryTransactionPort(channel: channel);

      final currencyUnit = await port.startPurchase(itemDefId: 40001);
      final retiredPack = await port.startPurchase(itemDefId: 10010);
      final retiredExchange = await port.exchangeItems(
        generateItemDefId: 20010,
        destroyItems: const [
          SteamInventoryDestroyItem(instanceId: '1', quantity: 100),
        ],
      );

      expect(currencyUnit.status, SteamInventoryTransactionStatus.rejected);
      expect(currencyUnit.issueCode, 'steam_purchase_itemdef_not_allowed');
      expect(retiredPack.status, SteamInventoryTransactionStatus.rejected);
      expect(retiredPack.issueCode, 'steam_purchase_itemdef_not_allowed');
      expect(retiredExchange.status, SteamInventoryTransactionStatus.rejected);
      expect(retiredExchange.issueCode, 'steam_exchange_itemdef_not_allowed');
      expect(nativeCalls, 0);
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
                        'phase': 'start_purchase_callback',
                        'apiCallHandle': '70010',
                        'steamResultCode': 1,
                        'steamResultName': 'k_EResultOK',
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
                      'phase': 'inventory_result_ready',
                      'steamResultCode': 1,
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
        expect(result.phase, 'inventory_result_ready');
        expect(result.apiCallHandle, '70010');
        expect(result.providerResultCode, 1);
        expect(result.providerResultName, 'k_EResultOK');
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

    test('preserves immediate StartPurchase rejection evidence', () {
      final rejected =
          MethodChannelSteamInventoryTransactionPort.parseOperation({
            'ok': false,
            'status': 'failed',
            'phase': 'start_purchase_api',
            'code': 'k_uAPICallInvalid',
            'steamResultCode': 0,
            'steamResultName': 'k_uAPICallInvalid',
            'apiCallHandle': '0',
            'handle': 'purchase_13',
            'detail': 'StartPurchase returned k_uAPICallInvalid',
          });

      expect(rejected.status, SteamInventoryTransactionStatus.failed);
      expect(rejected.issueCode, 'steam_api_call_invalid');
      expect(rejected.phase, 'start_purchase_api');
      expect(rejected.apiCallHandle, '0');
      expect(rejected.providerResultCode, 0);
      expect(rejected.providerResultName, 'k_uAPICallInvalid');
    });

    test('immediate StartPurchase failure never enters polling', () async {
      var pollCalls = 0;
      var releaseCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'startPurchase') {
              return <String, Object?>{
                'ok': false,
                'status': 'failed',
                'phase': 'start_purchase_api',
                'code': 'k_uAPICallInvalid',
                'steamResultName': 'k_uAPICallInvalid',
                'handle': 'purchase_not_started',
              };
            }
            if (call.method == 'poll') pollCalls += 1;
            if (call.method == 'releasePurchaseOperation') releaseCalls += 1;
            return null;
          });
      const port = MethodChannelSteamInventoryTransactionPort(channel: channel);

      final result = await port.startPurchase(itemDefId: 40110);

      expect(result.status, SteamInventoryTransactionStatus.failed);
      expect(result.issueCode, 'steam_api_call_invalid');
      expect(pollCalls, 0);
      expect(releaseCalls, 0);
    });

    test('timeout after API acceptance is indeterminate', () async {
      var releaseCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'startPurchase') {
              return <String, Object?>{
                'ok': true,
                'status': 'pending',
                'handle': 'purchase_12',
              };
            }
            if (call.method == 'releasePurchaseOperation') {
              releaseCalls += 1;
              return <String, Object?>{'ok': true, 'released': true};
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
      expect(releaseCalls, 1);
    });

    test(
      'overlay close waits for grace then returns a reconciliation hint',
      () async {
        final fakeTime = _FakeOperationTime();
        var pollCount = 0;
        var releaseCalls = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'startPurchase') {
                return <String, Object?>{
                  'ok': true,
                  'status': 'pending',
                  'handle': 'purchase_cancel',
                };
              }
              if (call.method == 'releasePurchaseOperation') {
                releaseCalls += 1;
                expect(call.arguments, {'handle': 'purchase_cancel'});
                return <String, Object?>{'ok': true, 'released': true};
              }
              pollCount += 1;
              final ops = switch (pollCount) {
                1 => <Object?>[
                  {
                    'kind': 'purchase',
                    'status': 'pending',
                    'handle': 'purchase_cancel',
                    'phase': 'purchase_overlay_active',
                    'overlayActive': true,
                  },
                ],
                2 => <Object?>[
                  {
                    'kind': 'purchase',
                    'status': 'pending',
                    'handle': 'purchase_cancel',
                    'phase': 'purchase_overlay_closed',
                    'overlayActive': false,
                  },
                ],
                _ => const <Object?>[],
              };
              return <String, Object?>{'ok': true, 'ops': ops};
            });
        final port = MethodChannelSteamInventoryTransactionPort(
          channel: channel,
          pollInterval: const Duration(seconds: 1),
          overlayCloseGracePeriod: const Duration(seconds: 3),
          completionTimeout: const Duration(seconds: 30),
          clock: fakeTime.now,
          delay: fakeTime.delay,
        );

        final result = await port.startPurchase(itemDefId: 40110);

        expect(result.status, SteamInventoryTransactionStatus.indeterminate);
        expect(result.issueCode, 'steam_purchase_overlay_closed');
        expect(result.phase, 'purchase_overlay_closed_grace_elapsed');
        expect(pollCount, 5);
        expect(releaseCalls, 1);
      },
    );

    test(
      'correlated overlay close recovers when the opening callback was missed',
      () async {
        final fakeTime = _FakeOperationTime();
        var pollCount = 0;
        var releaseCalls = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'startPurchase') {
                return <String, Object?>{
                  'ok': true,
                  'status': 'pending',
                  'handle': 'purchase_missed_open',
                };
              }
              if (call.method == 'releasePurchaseOperation') {
                releaseCalls += 1;
                return <String, Object?>{'ok': true, 'released': true};
              }
              pollCount += 1;
              return <String, Object?>{
                'ok': true,
                'ops': pollCount == 1
                    ? <Object?>[
                        {
                          'kind': 'purchase',
                          'status': 'pending',
                          'handle': 'purchase_missed_open',
                          'phase': 'purchase_overlay_closed',
                          'overlayActive': false,
                        },
                      ]
                    : const <Object?>[],
              };
            });
        final port = MethodChannelSteamInventoryTransactionPort(
          channel: channel,
          pollInterval: const Duration(seconds: 1),
          overlayCloseGracePeriod: const Duration(seconds: 3),
          completionTimeout: const Duration(seconds: 30),
          clock: fakeTime.now,
          delay: fakeTime.delay,
        );

        final result = await port.startPurchase(itemDefId: 40110);

        expect(result.issueCode, 'steam_purchase_overlay_closed');
        expect(result.phase, 'purchase_overlay_closed_grace_elapsed');
        expect(pollCount, 4);
        expect(releaseCalls, 1);
      },
    );

    test(
      'late terminal success after overlay close wins during grace',
      () async {
        final fakeTime = _FakeOperationTime();
        var pollCount = 0;
        var releaseCalls = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'startPurchase') {
                return <String, Object?>{
                  'ok': true,
                  'status': 'pending',
                  'handle': 'purchase_late',
                };
              }
              if (call.method == 'releasePurchaseOperation') {
                releaseCalls += 1;
                return <String, Object?>{'ok': true};
              }
              pollCount += 1;
              final ops = switch (pollCount) {
                1 => <Object?>[
                  {
                    'status': 'pending',
                    'handle': 'purchase_late',
                    'overlayActive': true,
                  },
                ],
                2 => <Object?>[
                  {
                    'status': 'pending',
                    'handle': 'purchase_late',
                    'overlayActive': false,
                  },
                ],
                _ => <Object?>[
                  {
                    'status': 'success',
                    'handle': 'purchase_late',
                    'phase': 'inventory_result_ready',
                    'steamResultName': 'k_EResultOK',
                  },
                ],
              };
              return <String, Object?>{'ok': true, 'ops': ops};
            });
        final port = MethodChannelSteamInventoryTransactionPort(
          channel: channel,
          pollInterval: const Duration(seconds: 1),
          overlayCloseGracePeriod: const Duration(seconds: 3),
          completionTimeout: const Duration(seconds: 30),
          clock: fakeTime.now,
          delay: fakeTime.delay,
        );

        final result = await port.startPurchase(itemDefId: 40110);

        expect(result.status, SteamInventoryTransactionStatus.confirmed);
        expect(result.phase, 'inventory_result_ready');
        expect(pollCount, 3);
        expect(releaseCalls, 0);
      },
    );

    test(
      'stale callback cannot complete or release a newer purchase',
      () async {
        final fakeTime = _FakeOperationTime();
        var pollCount = 0;
        String? releasedHandle;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'startPurchase') {
                return <String, Object?>{
                  'ok': true,
                  'status': 'pending',
                  'handle': 'purchase_new',
                };
              }
              if (call.method == 'releasePurchaseOperation') {
                releasedHandle = (call.arguments as Map)['handle'] as String;
                return <String, Object?>{'ok': true, 'released': true};
              }
              pollCount += 1;
              final ops = switch (pollCount) {
                1 => <Object?>[
                  {'status': 'success', 'handle': 'purchase_old'},
                  {
                    'status': 'pending',
                    'handle': 'purchase_new',
                    'overlayActive': true,
                  },
                ],
                2 => <Object?>[
                  {'status': 'canceled', 'handle': 'purchase_old'},
                  {
                    'status': 'pending',
                    'handle': 'purchase_new',
                    'overlayActive': false,
                  },
                ],
                _ => const <Object?>[],
              };
              return <String, Object?>{'ok': true, 'ops': ops};
            });
        final port = MethodChannelSteamInventoryTransactionPort(
          channel: channel,
          pollInterval: const Duration(seconds: 1),
          overlayCloseGracePeriod: const Duration(seconds: 2),
          completionTimeout: const Duration(seconds: 30),
          clock: fakeTime.now,
          delay: fakeTime.delay,
        );

        final result = await port.startPurchase(itemDefId: 40110);

        expect(result.issueCode, 'steam_purchase_overlay_closed');
        expect(releasedHandle, 'purchase_new');
      },
    );
  });

  test('native ResultReady remains the only DestroyResult owner', () {
    final source = File(
      'windows/runner/steam_inventory_poc_channel.cpp',
    ).readAsStringSync();
    final purchaseBlock = source.substring(
      source.indexOf('if (method == "startPurchase")'),
      source.indexOf('if (method == "consumeItem")'),
    );

    expect(
      RegExp(r'SteamInventory\(\)->DestroyResult\(').allMatches(source),
      hasLength(1),
    );
    expect(source, contains('if (method == "releasePurchaseOperation")'));
    expect(source, contains('pending.erase(pending_it)'));
    expect(
      purchaseBlock.indexOf('impl_->pending[corr] = p;'),
      lessThan(purchaseBlock.indexOf('SteamInventory()->StartPurchase(')),
    );
  });

  group('MethodChannelSteamInventoryReadPort parsing', () {
    test('preserves production Steam runtime capability fields', () {
      final result = MethodChannelSteamInventoryReadPort.parseDiagnostic({
        'ok': true,
        'initialized': true,
        'loggedOn': true,
        'subscribedApp': true,
        'overlayEnabled': true,
        'overlayActive': false,
        'processUptimeMs': 15000,
        'overlayFirstSampleEnabled': false,
        'overlayFirstSampleElapsedMs': 20,
        'overlayFirstTrueElapsedMs': 9000,
        'overlayEnabledSampleCount': 10,
        'overlayEnabledTransitionCount': 1,
        'overlayActivatedCallbackCount': 2,
        'overlayDeactivatedCallbackCount': 2,
        'overlayLastCallbackElapsedMs': 14000,
        'initializationAttempted': true,
        'restartRequested': false,
        'appId': 4677560,
        'steamBuildId': 24271481,
        'gitCommit': 'f9d0b94b00c77feb6483f4df4e13886c78aa8175',
        'buildMode': 'Release',
        'executablePath': r'D:\SteamLibrary\steamapps\common\Akasha\akasha.exe',
        'currentWorkingDirectory': r'D:\SteamLibrary\steamapps\common\Akasha',
        'steamTimerTickCount': 123,
        'overlayNeedsPresentTrueCount': 4,
        'overlayForceRedrawCount': 3,
      });

      expect(result.status, SteamInventoryReadStatus.success);
      expect(result.transactionCapabilityIssueCode, isNull);
      expect(result.subscribedApp, isTrue);
      expect(result.overlayEnabled, isTrue);
      expect(result.processUptimeMs, 15000);
      expect(result.overlayFirstSampleEnabled, isFalse);
      expect(result.overlayFirstSampleElapsedMs, 20);
      expect(result.overlayFirstTrueElapsedMs, 9000);
      expect(result.overlayEnabledSampleCount, 10);
      expect(result.overlayEnabledTransitionCount, 1);
      expect(result.overlayActivatedCallbackCount, 2);
      expect(result.overlayDeactivatedCallbackCount, 2);
      expect(result.overlayLastCallbackElapsedMs, 14000);
      expect(result.initializationAttempted, isTrue);
      expect(result.steamBuildId, 24271481);
      expect(result.gitCommit, 'f9d0b94b00c77feb6483f4df4e13886c78aa8175');
      expect(result.buildMode, 'Release');
      expect(
        result.executionEnvironment,
        SteamRuntimeExecutionEnvironment.steamInstall,
      );
      expect(result.executablePath, contains('SteamLibrary'));
      expect(result.steamTimerTickCount, 123);
      expect(result.overlayNeedsPresentTrueCount, 4);
      expect(result.overlayForceRedrawCount, 3);
    });

    test('normalizes a Steam BuildID of zero to unavailable', () {
      final result = MethodChannelSteamInventoryReadPort.parseDiagnostic({
        'ok': true,
        'initialized': true,
        'loggedOn': false,
        'steamBuildId': 0,
      });

      expect(result.steamBuildId, isNull);
    });

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
      initialized: true,
      loggedOn: true,
      subscribedApp: true,
      overlayEnabled: true,
    ),
    this.items = const SteamInventoryItemsResult(
      status: SteamInventoryReadStatus.success,
    ),
    this.itemSequence,
    this.prices = const SteamInventoryPricesResult(
      status: SteamInventoryReadStatus.success,
      currencyCode: 'USD',
      prices: [
        SteamInventoryPriceRow(itemDefId: 40110, currentAmount: 499),
        SteamInventoryPriceRow(itemDefId: 40111, currentAmount: 999),
        SteamInventoryPriceRow(itemDefId: 40112, currentAmount: 2499),
      ],
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

class _FakeSteamInventoryRewardPort implements SteamInventoryRewardPort {
  _FakeSteamInventoryRewardPort({required this.result});

  final SteamInventoryRewardResult result;
  final List<int> generatorItemDefIds = [];
  final List<int> expectedItemDefIds = [];

  @override
  Future<SteamInventoryRewardResult> triggerPlaytimeReward({
    required int generatorItemDefId,
    required int expectedItemDefId,
  }) async {
    generatorItemDefIds.add(generatorItemDefId);
    expectedItemDefIds.add(expectedItemDefId);
    return result;
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

class _FakeOperationTime {
  DateTime _value = DateTime.utc(2026, 7, 18);

  DateTime now() => _value;

  Future<void> delay(Duration duration) async {
    _value = _value.add(duration);
  }
}
