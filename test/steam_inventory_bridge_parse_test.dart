import 'package:akasha/dev/steam_inventory_poc/channel_steam_inventory_client.dart';
import 'package:akasha/dev/steam_inventory_poc/steam_inventory_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native status mapping never treats canceled/indeterminate as ok', () {
    expect(
      ChannelSteamInventoryClient.parseNativeStatus('success'),
      SteamInventoryOpStatus.ok,
    );
    expect(
      ChannelSteamInventoryClient.parseNativeStatus('pending'),
      SteamInventoryOpStatus.pending,
    );
    expect(
      ChannelSteamInventoryClient.parseNativeStatus('canceled'),
      SteamInventoryOpStatus.failed,
    );
    expect(
      ChannelSteamInventoryClient.parseNativeStatus('indeterminate'),
      SteamInventoryOpStatus.failed,
    );
    expect(
      ChannelSteamInventoryClient.parseNativeStatus('weird'),
      SteamInventoryOpStatus.failed,
    );
  });

  test('opFromMap parses event payload', () {
    final op = ChannelSteamInventoryClient.opFromMap({
      'kind': 'purchase',
      'status': 'pending',
      'handle': 'purchase_1',
      'detail': 'wait',
    });
    expect(op.kind, SteamInventoryOpKind.purchase);
    expect(op.status, SteamInventoryOpStatus.pending);
    expect(op.resultHandle, 'purchase_1');
  });
}
