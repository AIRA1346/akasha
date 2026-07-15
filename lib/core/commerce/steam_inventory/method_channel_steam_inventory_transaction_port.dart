import 'package:flutter/services.dart';

import 'steam_inventory_channel_contract.dart';
import 'steam_inventory_method_channel_operation.dart';
import 'steam_inventory_transaction_port.dart';

/// Guarded transaction facade over the Windows Steam Inventory bridge.
///
/// Immediate MethodChannel acceptance is never returned as confirmation. The
/// port polls until the matching native correlation handle reaches a terminal
/// `SteamInventoryResultReady_t` state. Inventory reconciliation belongs to
/// the commerce gateway.
class MethodChannelSteamInventoryTransactionPort
    implements SteamInventoryTransactionPort {
  const MethodChannelSteamInventoryTransactionPort({
    MethodChannel channel = const MethodChannel(
      SteamInventoryChannelContract.methods,
    ),
    this.pollInterval = const Duration(milliseconds: 250),
    this.completionTimeout = const Duration(minutes: 5),
  }) : _channel = channel;

  final MethodChannel _channel;
  final Duration pollInterval;
  final Duration completionTimeout;

  @override
  Future<SteamInventoryTransactionResult> startPurchase({
    required int itemDefId,
    int quantity = 1,
  }) async {
    if (itemDefId <= 0 || quantity != 1) {
      return const SteamInventoryTransactionResult(
        status: SteamInventoryTransactionStatus.rejected,
        issueCode: 'steam_invalid_purchase_request',
      );
    }
    return _startAndAwait(
      method: 'startPurchase',
      arguments: {
        'itemDefIds': [itemDefId],
        'quantities': [quantity],
      },
      acceptedKey: null,
    );
  }

  @override
  Future<SteamInventoryTransactionResult> exchangeItems({
    required int generateItemDefId,
    required List<SteamInventoryDestroyItem> destroyItems,
  }) async {
    if (generateItemDefId <= 0 ||
        destroyItems.isEmpty ||
        destroyItems.any(
          (item) =>
              item.instanceId.isEmpty ||
              !_instanceIdPattern.hasMatch(item.instanceId) ||
              item.quantity <= 0,
        )) {
      return const SteamInventoryTransactionResult(
        status: SteamInventoryTransactionStatus.rejected,
        issueCode: 'steam_invalid_exchange_request',
      );
    }
    return _startAndAwait(
      method: 'exchangeItems',
      arguments: {
        'generateItemDefId': generateItemDefId,
        'generateQuantity': 1,
        'destroyInstanceIds': [
          for (final item in destroyItems) item.instanceId,
        ],
        'destroyQuantities': [for (final item in destroyItems) item.quantity],
      },
      acceptedKey: 'exchangeApiAccepted',
    );
  }

  Future<SteamInventoryTransactionResult> _startAndAwait({
    required String method,
    required Map<String, Object> arguments,
    required String? acceptedKey,
  }) async {
    Map<String, Object?>? raw;
    try {
      raw = await _channel.invokeMapMethod<String, Object?>(method, arguments);
    } on MissingPluginException {
      return const SteamInventoryTransactionResult(
        status: SteamInventoryTransactionStatus.failed,
        issueCode: 'steam_missing_plugin',
      );
    } on PlatformException catch (error) {
      return SteamInventoryTransactionResult(
        status: SteamInventoryTransactionStatus.failed,
        issueCode: 'steam_${error.code}',
      );
    }

    final immediate = parseOperation(raw);
    if (raw == null ||
        raw['ok'] != true ||
        (acceptedKey != null && raw[acceptedKey] != true)) {
      return immediate.status == SteamInventoryTransactionStatus.pending
          ? SteamInventoryTransactionResult(
              status: SteamInventoryTransactionStatus.failed,
              providerHandle: immediate.providerHandle,
              issueCode: immediate.issueCode ?? 'steam_transaction_not_started',
            )
          : immediate;
    }
    final handle = immediate.providerHandle;
    if (handle == null || handle.isEmpty) {
      return const SteamInventoryTransactionResult(
        status: SteamInventoryTransactionStatus.failed,
        issueCode: 'steam_transaction_handle_missing',
      );
    }
    return _awaitTerminal(handle);
  }

  Future<SteamInventoryTransactionResult> _awaitTerminal(String handle) async {
    final operation = await SteamInventoryMethodChannelOperationPoller(
      channel: _channel,
      pollInterval: pollInterval,
      completionTimeout: completionTimeout,
    ).awaitTerminal(handle);
    return operation.result;
  }

  static SteamInventoryTransactionResult parseOperation(
    Map<String, Object?>? raw,
  ) => SteamInventoryMethodChannelOperationPoller.parseOperation(raw).result;

  static final RegExp _instanceIdPattern = RegExp(r'^[0-9]+$');
}
