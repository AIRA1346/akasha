import 'dart:async';

import 'package:flutter/services.dart';

import 'steam_inventory_channel_contract.dart';
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
    final deadline = DateTime.now().add(completionTimeout);
    String? orderId;
    String? transactionId;
    while (DateTime.now().isBefore(deadline)) {
      Map<String, Object?>? raw;
      try {
        raw = await _channel.invokeMapMethod<String, Object?>('poll');
      } on MissingPluginException {
        return SteamInventoryTransactionResult(
          status: SteamInventoryTransactionStatus.indeterminate,
          providerHandle: handle,
          issueCode: 'steam_missing_plugin_after_acceptance',
        );
      } on PlatformException catch (error) {
        return SteamInventoryTransactionResult(
          status: SteamInventoryTransactionStatus.indeterminate,
          providerHandle: handle,
          issueCode: 'steam_${error.code}_after_acceptance',
        );
      }
      if (raw == null || raw['ok'] != true) {
        final code = _snakeCase('${raw?['code'] ?? 'poll_failed'}');
        return SteamInventoryTransactionResult(
          status: SteamInventoryTransactionStatus.indeterminate,
          providerHandle: handle,
          issueCode: 'steam_${code}_after_acceptance',
        );
      }

      for (final value in raw['ops'] as List<dynamic>? ?? const []) {
        if (value is! Map) continue;
        final operation = parseOperation(Map<String, Object?>.from(value));
        if (operation.providerHandle != handle) {
          continue;
        }
        orderId ??= operation.orderId;
        transactionId ??= operation.transactionId;
        if (!operation.isTerminal) continue;
        return SteamInventoryTransactionResult(
          status: operation.status,
          providerHandle: operation.providerHandle,
          orderId: operation.orderId ?? orderId,
          transactionId: operation.transactionId ?? transactionId,
          issueCode: operation.issueCode,
        );
      }
      if (pollInterval > Duration.zero) {
        await Future<void>.delayed(pollInterval);
      }
    }
    return SteamInventoryTransactionResult(
      status: SteamInventoryTransactionStatus.indeterminate,
      providerHandle: handle,
      orderId: orderId,
      transactionId: transactionId,
      issueCode: 'steam_transaction_timeout',
    );
  }

  static SteamInventoryTransactionResult parseOperation(
    Map<String, Object?>? raw,
  ) {
    final handle = _stringOrNull(raw?['handle']);
    final orderId = _stringOrNull(raw?['orderId']);
    final transactionId = _stringOrNull(
      raw?['transactionId'] ?? raw?['transId'],
    );
    if (raw?['steamIdOk'] == false) {
      return SteamInventoryTransactionResult(
        status: SteamInventoryTransactionStatus.failed,
        providerHandle: handle,
        orderId: orderId,
        transactionId: transactionId,
        issueCode: 'steam_id_mismatch',
      );
    }
    final statusName = '${raw?['status'] ?? 'failed'}'.trim();
    final resultName = '${raw?['steamResultName'] ?? ''}'.trim();
    final issueSource = resultName.isNotEmpty ? resultName : statusName;
    final status = switch (statusName) {
      'pending' => SteamInventoryTransactionStatus.pending,
      'success' || 'ok' => SteamInventoryTransactionStatus.confirmed,
      'canceled' || 'cancelled' => SteamInventoryTransactionStatus.cancelled,
      'indeterminate' ||
      'expired' => SteamInventoryTransactionStatus.indeterminate,
      'invalid_param' ||
      'limit_exceeded' => SteamInventoryTransactionStatus.rejected,
      _ when _isProviderRejection(resultName) =>
        SteamInventoryTransactionStatus.rejected,
      _ => SteamInventoryTransactionStatus.failed,
    };
    return SteamInventoryTransactionResult(
      status: status,
      providerHandle: handle,
      orderId: orderId,
      transactionId: transactionId,
      issueCode:
          status == SteamInventoryTransactionStatus.confirmed ||
              status == SteamInventoryTransactionStatus.pending
          ? null
          : 'steam_${_snakeCase(issueSource)}',
    );
  }

  static bool _isProviderRejection(String name) => const {
    'k_EResultInsufficientFunds',
    'k_EResultInvalidParam',
    'k_EResultLimitExceeded',
    'k_EResultAlreadyOwned',
    'k_EResultDuplicateRequest',
    'k_EResultInsufficientPrivilege',
  }.contains(name);

  static String? _stringOrNull(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static String _snakeCase(String input) {
    final withoutPrefix = input.replaceFirst(RegExp(r'^k_EResult'), '');
    final value = withoutPrefix
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .toLowerCase()
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return value.isEmpty ? 'transaction_failed' : value;
  }

  static final RegExp _instanceIdPattern = RegExp(r'^[0-9]+$');
}
