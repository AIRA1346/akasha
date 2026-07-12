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

  test('load failure does not invent local balances', () async {
    fake.failNextLoad = true;
    final snap = await poc.refreshInventory();
    expect(snap.loadFailed, isTrue);
    expect(poc.astra, 0);
    expect(poc.echo, 0);
    expect(poc.ownsNocturne, isFalse);
    expect(poc.hasConfirmedInventory, isFalse);
  });

  test('purchase grants Astra via inventory refresh only once per handle', () async {
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
  });

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

  test('ExchangeItems spends Astra and grants theme atomically (fake)', () async {
    fake = FakeSteamInventoryClient(
      initialStacks: {SteamInventoryPocIds.astraUnit: 10},
    );
    poc = SteamInventoryPocController(fake);
    await poc.refreshInventory();
    final h = await poc.unlockNocturneTheme(preferAstra: true);
    await poc.pump();
    expect(h, isNotNull);
    expect(poc.astra, 0);
    expect(poc.ownsNocturne, isTrue);
  });

  test('duplicate exchange after own is blocked; inventory re-query converges', () async {
    fake = FakeSteamInventoryClient(
      initialStacks: {SteamInventoryPocIds.astraUnit: 20},
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
    expect(poc.astra, 10); // only one exchange spent 10
  });

  test('offline blocks purchase and exchange; confirmed theme still applicable', () async {
    fake = FakeSteamInventoryClient(
      initialStacks: {SteamInventoryPocIds.themeNocturne: 1},
    );
    poc = SteamInventoryPocController(fake);
    await poc.refreshInventory();
    expect(poc.themeApplicableOffline(SteamInventoryPocIds.themeNocturne), isTrue);

    fake.online = false;
    expect(await poc.buyAstraPack100(), isNull);
    expect(poc.activeOp.detail, 'offline');
    expect(await poc.unlockNocturneTheme(preferAstra: true), isNull);
  });

  test('Echo playtime requires TriggerItemDrop path', () async {
    final h = await poc.claimEchoPlaytimeDrop();
    await poc.pump();
    expect(h, isNotNull);
    expect(poc.echo, 5);
  });
}
