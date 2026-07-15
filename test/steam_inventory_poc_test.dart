import 'dart:convert';
import 'dart:io';

import 'package:akasha/dev/steam_inventory_poc/steam_inventory_poc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSteamInventoryClient fake;
  late SteamInventoryPocController poc;

  setUp(() async {
    fake = FakeSteamInventoryClient();
    poc = SteamInventoryPocController(fake);
    await poc.initialize();
    await poc.refreshInventory();
  });

  test('published POC Echo generator weight maps to one Echo', () {
    final schema =
        jsonDecode(
              File(
                'docs/active/steam_inventory_poc/itemdefs_poc.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final items = schema['items']! as List<Object?>;
    final generator = items.cast<Map<String, Object?>>().singleWhere(
      (item) => item['itemdefid'] == '10020',
    );

    expect(generator['type'], 'playtimegenerator');
    expect(generator['bundle'], '10002x5');
    expect(SteamInventoryPocIds.echoPlaytimeGrantAmount, 1);
  });

  test('load failure does not invent local balances', () async {
    fake.failNextLoad = true;
    final snap = await poc.refreshInventory();
    expect(snap.loadFailed, isTrue);
    expect(poc.astra, 0);
    expect(poc.echo, 0);
    expect(poc.ownsNocturne, isFalse);
    expect(poc.hasConfirmedInventory, isFalse);
  });

  test(
    'purchase grants Astra via inventory refresh only once per handle',
    () async {
      final h = await poc.buyAstraPack100();
      expect(poc.activeOp.status, SteamInventoryOpStatus.pending);
      expect(poc.astra, 0); // not granted until poll completes

      await poc.pump();
      expect(poc.astra, 100);

      // Duplicate completion of same handle must not double-grant.
      fake.completedHandleLog.clear();
      await poc.pump();
      expect(poc.astra, 100);
      expect(h, isNotNull);
    },
  );

  test(
    'support purchase forwards itemDef and completes through refresh',
    () async {
      final h = await poc.buySupport();
      expect(h, isNotNull);
      expect(poc.activeOp.kind, SteamInventoryOpKind.purchase);
      expect(poc.activeOp.status, SteamInventoryOpStatus.pending);
      expect(poc.activeOp.resultHandle, h);
      expect(fake.stackQty(SteamInventoryPocIds.supportAkasha), 0);

      final completed = await poc.pump();
      expect(completed, hasLength(1));
      expect(completed.single.kind, SteamInventoryOpKind.purchase);
      expect(completed.single.status, SteamInventoryOpStatus.ok);
      expect(completed.single.resultHandle, h);
      expect(fake.stackQty(SteamInventoryPocIds.supportAkasha), 1);
      expect(
        poc.lastSnapshot!.quantityOf(SteamInventoryPocIds.supportAkasha),
        1,
      );
      expect(poc.activeOp.status, SteamInventoryOpStatus.ok);
    },
  );

  test('delayed purchase stays pending until complete', () async {
    fake.delayPurchase = true;
    final h = await poc.buyAstraPack100();
    final pending = await poc.pump();
    expect(pending.single.status, SteamInventoryOpStatus.pending);
    expect(poc.astra, 0);

    fake.complete(h!);
    await poc.pump();
    expect(poc.astra, 100);
  });

  test('does not request theme exchange when already owned', () async {
    fake = FakeSteamInventoryClient(
      initialStacks: {SteamInventoryPocIds.themeNocturne: 1},
    );
    poc = SteamInventoryPocController(fake);
    await poc.refreshInventory();
    expect(poc.ownsNocturne, isTrue);
    final h = await poc.unlockNocturneTheme(preferAstra: true);
    expect(h, isNull);
    expect(poc.activeOp.detail, 'theme_already_owned');
  });

  test(
    'ExchangeItems spends Astra and grants theme atomically (fake)',
    () async {
      fake = FakeSteamInventoryClient(
        initialStacks: {SteamInventoryPocIds.astraUnit: 300},
      );
      poc = SteamInventoryPocController(fake);
      await poc.refreshInventory();
      final h = await poc.unlockNocturneTheme(preferAstra: true);
      expect(h, isNotNull);
      expect(poc.activeOp.detail, contains('exchangeApiAccepted=true'));
      expect(
        poc.activeOp.detail,
        contains('generate=${SteamInventoryPocIds.themeNocturneExchange}x1'),
      );
      await poc.pump();
      expect(poc.astra, 200);
      expect(poc.ownsNocturne, isTrue);
    },
  );

  test(
    'duplicate exchange after own is blocked; inventory re-query converges',
    () async {
      fake = FakeSteamInventoryClient(
        initialStacks: {SteamInventoryPocIds.astraUnit: 200},
      );
      poc = SteamInventoryPocController(fake);
      await poc.refreshInventory();
      await poc.unlockNocturneTheme(preferAstra: true);
      await poc.pump();
      expect(poc.ownsNocturne, isTrue);

      final again = await poc.unlockNocturneTheme(preferAstra: true);
      expect(again, isNull);
      await poc.refreshInventory();
      expect(poc.ownsNocturne, isTrue);
      expect(poc.astra, 100); // only one exchange spent 100
    },
  );

  test(
    'offline blocks purchase and exchange; confirmed theme still applicable',
    () async {
      fake = FakeSteamInventoryClient(
        initialStacks: {SteamInventoryPocIds.themeNocturne: 1},
      );
      poc = SteamInventoryPocController(fake);
      await poc.refreshInventory();
      expect(
        poc.themeApplicableOffline(SteamInventoryPocIds.themeNocturne),
        isTrue,
      );

      fake.online = false;
      expect(await poc.buyAstraPack100(), isNull);
      expect(poc.activeOp.detail, 'offline');
      expect(await poc.unlockNocturneTheme(preferAstra: true), isNull);
    },
  );

  test('Echo playtime requires TriggerItemDrop path', () async {
    final h = await poc.claimEchoPlaytimeDrop();
    await poc.pump();
    expect(h, isNotNull);
    expect(poc.echo, SteamInventoryPocIds.echoPlaytimeGrantAmount);
  });

  test(
    'Consume Theme Reset removes theme and leaves Astra untouched',
    () async {
      fake = FakeSteamInventoryClient(
        initialStacks: {
          SteamInventoryPocIds.astraUnit: 370,
          SteamInventoryPocIds.themeNocturne: 1,
        },
      );
      poc = SteamInventoryPocController(fake);
      await poc.refreshInventory();
      expect(poc.astra, 370);
      expect(poc.ownsNocturne, isTrue);
      expect(poc.formatInventoryAudit(), contains('Astra total=370'));
      expect(poc.formatInventoryAudit(), contains('Theme20001 total=1'));

      final h = await poc.consumeThemeReset();
      expect(h, isNotNull);
      expect(poc.activeOp.detail, contains('quantity=1'));
      expect(poc.activeOp.detail, contains('Astra untouched'));
      await poc.pump();
      expect(poc.astra, 370);
      expect(poc.ownsNocturne, isFalse);

      final exchange = await poc.unlockNocturneTheme(preferAstra: true);
      expect(exchange, isNotNull);
      await poc.pump();
      expect(poc.astra, 270);
      expect(poc.ownsNocturne, isTrue);
    },
  );

  test('blocks duplicate purchase/exchange while mutation pending', () async {
    fake = FakeSteamInventoryClient(
      initialStacks: {SteamInventoryPocIds.astraUnit: 200},
    )..delayPurchase = true;
    poc = SteamInventoryPocController(fake);
    await poc.refreshInventory();

    final first = await poc.buyAstraPack100();
    expect(first, isNotNull);
    expect(poc.isMutationPending, isTrue);
    expect(await poc.buyAstraPack100(), isNull);
    expect(poc.isMutationPending, isTrue);
    expect(await poc.unlockNocturneTheme(preferAstra: true), isNull);
    expect(poc.isMutationPending, isTrue);
    expect(poc.activeOp.kind, SteamInventoryOpKind.purchase);

    fake.complete(first!);
    await poc.pump();
    expect(poc.hasConfirmedInventory, isTrue);
    expect(poc.astra, 300);
  });

  test('Theme ownership is qty>=1; multi-instance audit shows total', () async {
    poc.lastSnapshot = SteamInventorySnapshot(
      items: const [
        SteamInventoryItem(
          instanceId: 't1',
          itemDefId: SteamInventoryPocIds.themeNocturne,
          quantity: 1,
        ),
        SteamInventoryItem(
          instanceId: 't2',
          itemDefId: SteamInventoryPocIds.themeNocturne,
          quantity: 1,
        ),
      ],
      fetchedAt: DateTime.now().toUtc(),
    );
    expect(poc.ownsNocturne, isTrue);
    expect(poc.lastSnapshot!.quantityOf(SteamInventoryPocIds.themeNocturne), 2);
    final audit = poc.formatInventoryAudit();
    expect(audit, contains('Theme20001 total=2'));
    expect(audit, contains('DUPLICATE_OR_MULTI'));
    expect(audit, contains('instanceCount=2'));
  });

  test(
    'Steam inventory authority survives controller recreate (same client)',
    () async {
      fake = FakeSteamInventoryClient(
        initialStacks: {SteamInventoryPocIds.astraUnit: 200},
      );
      poc = SteamInventoryPocController(fake);
      await poc.refreshInventory();
      await poc.unlockNocturneTheme(preferAstra: true);
      await poc.pump();
      expect(poc.astra, 100);
      expect(poc.ownsNocturne, isTrue);

      final again = SteamInventoryPocController(fake);
      await again.refreshInventory();
      expect(again.hasConfirmedInventory, isTrue);
      expect(again.astra, 100);
      expect(again.ownsNocturne, isTrue);
    },
  );
}
