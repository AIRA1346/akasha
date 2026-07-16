import 'package:flutter/services.dart';

import 'steam_inventory_channel_contract.dart';
import 'steam_inventory_itemdefs.dart';
import 'steam_inventory_method_channel_operation.dart';
import 'steam_inventory_reward_port.dart';
import 'steam_inventory_transaction_port.dart';

/// Guarded playtime reward facade over the Windows Steam Inventory bridge.
///
/// A successful TriggerItemDrop call only starts eligibility evaluation. The
/// port waits for the matching ResultReady event; an empty grant list means
/// Steam found the user ineligible at that moment.
class MethodChannelSteamInventoryRewardPort
    implements SteamInventoryRewardPort {
  const MethodChannelSteamInventoryRewardPort({
    MethodChannel channel = const MethodChannel(
      SteamInventoryChannelContract.methods,
    ),
    this.pollInterval = const Duration(milliseconds: 250),
    this.completionTimeout = const Duration(minutes: 2),
  }) : _channel = channel;

  final MethodChannel _channel;
  final Duration pollInterval;
  final Duration completionTimeout;

  @override
  Future<SteamInventoryRewardResult> triggerPlaytimeReward({
    required int generatorItemDefId,
    required int expectedItemDefId,
  }) async {
    if (generatorItemDefId != SteamInventoryItemDefs.echoPlaytimeReward ||
        expectedItemDefId != SteamInventoryItemDefs.echoUnit) {
      return const SteamInventoryRewardResult(
        status: SteamInventoryRewardStatus.rejected,
        issueCode: 'steam_reward_itemdef_not_allowed',
      );
    }

    Map<String, Object?>? raw;
    try {
      raw = await _channel.invokeMapMethod<String, Object?>('triggerItemDrop', {
        'generatorDefId': generatorItemDefId,
      });
    } on MissingPluginException {
      return const SteamInventoryRewardResult(
        status: SteamInventoryRewardStatus.failed,
        issueCode: 'steam_missing_plugin',
      );
    } on PlatformException catch (error) {
      return SteamInventoryRewardResult(
        status: SteamInventoryRewardStatus.failed,
        issueCode: 'steam_${error.code}',
      );
    }

    final immediate = SteamInventoryMethodChannelOperationPoller.parseOperation(
      raw,
    ).result;
    if (raw == null || raw['ok'] != true) {
      return SteamInventoryRewardResult(
        status: _rewardStatus(immediate.status),
        providerHandle: immediate.providerHandle,
        issueCode: immediate.issueCode ?? 'steam_reward_not_started',
      );
    }
    final handle = immediate.providerHandle;
    if (handle == null || handle.isEmpty) {
      return const SteamInventoryRewardResult(
        status: SteamInventoryRewardStatus.failed,
        issueCode: 'steam_reward_handle_missing',
      );
    }

    final operation = await SteamInventoryMethodChannelOperationPoller(
      channel: _channel,
      pollInterval: pollInterval,
      completionTimeout: completionTimeout,
    ).awaitTerminal(handle);
    if (operation.result.status != SteamInventoryTransactionStatus.confirmed) {
      return SteamInventoryRewardResult(
        status: _rewardStatus(operation.result.status),
        providerHandle: handle,
        issueCode: operation.result.issueCode,
      );
    }

    final reportedQuantity = operation.grantedItems
        .where((item) => item.itemDefId == expectedItemDefId)
        .fold<int>(0, (total, item) => total + item.quantity);
    return SteamInventoryRewardResult(
      status: reportedQuantity > 0
          ? SteamInventoryRewardStatus.granted
          : SteamInventoryRewardStatus.notEligible,
      providerHandle: handle,
      reportedGrantQuantity: reportedQuantity,
      issueCode: reportedQuantity > 0 ? null : 'steam_reward_not_eligible',
    );
  }

  static SteamInventoryRewardStatus _rewardStatus(
    SteamInventoryTransactionStatus status,
  ) => switch (status) {
    SteamInventoryTransactionStatus.confirmed =>
      SteamInventoryRewardStatus.notEligible,
    SteamInventoryTransactionStatus.cancelled ||
    SteamInventoryTransactionStatus.rejected =>
      SteamInventoryRewardStatus.rejected,
    SteamInventoryTransactionStatus.failed => SteamInventoryRewardStatus.failed,
    SteamInventoryTransactionStatus.pending ||
    SteamInventoryTransactionStatus.indeterminate =>
      SteamInventoryRewardStatus.indeterminate,
  };
}
