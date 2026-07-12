import 'channel_steam_inventory_client.dart';
import 'fake_steam_inventory_client.dart';
import 'steam_inventory_client.dart';
import 'steam_inventory_poc_controller.dart';

export 'channel_steam_inventory_client.dart';
export 'fake_steam_inventory_client.dart';
export 'steam_inventory_client.dart';
export 'steam_inventory_models.dart';
export 'steam_inventory_poc_controller.dart';
export 'steam_inventory_poc_ids.dart';

/// Debug-only factory: prefer native channel when available, else fake.
Future<SteamInventoryPocController> createSteamInventoryPocController({
  bool forceFake = false,
  SteamInventoryClient? override,
}) async {
  if (override != null) {
    final c = SteamInventoryPocController(override);
    await c.initialize();
    return c;
  }
  if (forceFake) {
    final fake = FakeSteamInventoryClient();
    final c = SteamInventoryPocController(fake);
    await c.initialize();
    await c.refreshInventory();
    return c;
  }
  // Lazy import avoided — channel client is safe when plugin missing.
  final channel = ChannelSteamInventoryClient();
  await channel.initialize();
  if (await channel.isAvailable) {
    final c = SteamInventoryPocController(channel);
    await c.refreshInventory();
    return c;
  }
  final fake = FakeSteamInventoryClient();
  final c = SteamInventoryPocController(fake);
  await c.initialize();
  await c.refreshInventory();
  return c;
}
