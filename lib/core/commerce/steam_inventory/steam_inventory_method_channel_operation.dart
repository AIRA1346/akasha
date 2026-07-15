import 'dart:async';

import 'package:flutter/services.dart';

import 'steam_inventory_transaction_port.dart';

class SteamInventoryOperationItem {
  const SteamInventoryOperationItem({
    required this.itemDefId,
    required this.quantity,
  });

  final int itemDefId;
  final int quantity;
}

class SteamInventoryPolledOperation {
  const SteamInventoryPolledOperation({
    required this.result,
    this.grantedItems = const [],
  });

  final SteamInventoryTransactionResult result;
  final List<SteamInventoryOperationItem> grantedItems;
}

/// Shared terminal-result polling for Steam Inventory MethodChannel operations.
///
/// Purchase, exchange, and playtime reward adapters use one correlation and
/// status parser so future provider capabilities do not fork callback rules.
class SteamInventoryMethodChannelOperationPoller {
  const SteamInventoryMethodChannelOperationPoller({
    required MethodChannel channel,
    required this.pollInterval,
    required this.completionTimeout,
  }) : _channel = channel;

  final MethodChannel _channel;
  final Duration pollInterval;
  final Duration completionTimeout;

  Future<SteamInventoryPolledOperation> awaitTerminal(String handle) async {
    final deadline = DateTime.now().add(completionTimeout);
    String? orderId;
    String? transactionId;
    while (DateTime.now().isBefore(deadline)) {
      Map<String, Object?>? raw;
      try {
        raw = await _channel.invokeMapMethod<String, Object?>('poll');
      } on MissingPluginException {
        return _indeterminate(handle, 'steam_missing_plugin_after_acceptance');
      } on PlatformException catch (error) {
        return _indeterminate(handle, 'steam_${error.code}_after_acceptance');
      }
      if (raw == null || raw['ok'] != true) {
        final code = snakeCase('${raw?['code'] ?? 'poll_failed'}');
        return _indeterminate(handle, 'steam_${code}_after_acceptance');
      }

      for (final value in raw['ops'] as List<dynamic>? ?? const []) {
        if (value is! Map) continue;
        final operation = parseOperation(Map<String, Object?>.from(value));
        if (operation.result.providerHandle != handle) continue;
        orderId ??= operation.result.orderId;
        transactionId ??= operation.result.transactionId;
        if (!operation.result.isTerminal) continue;
        return SteamInventoryPolledOperation(
          result: SteamInventoryTransactionResult(
            status: operation.result.status,
            providerHandle: operation.result.providerHandle,
            orderId: operation.result.orderId ?? orderId,
            transactionId: operation.result.transactionId ?? transactionId,
            issueCode: operation.result.issueCode,
          ),
          grantedItems: operation.grantedItems,
        );
      }
      if (pollInterval > Duration.zero) {
        await Future<void>.delayed(pollInterval);
      }
    }
    return SteamInventoryPolledOperation(
      result: SteamInventoryTransactionResult(
        status: SteamInventoryTransactionStatus.indeterminate,
        providerHandle: handle,
        orderId: orderId,
        transactionId: transactionId,
        issueCode: 'steam_transaction_timeout',
      ),
    );
  }

  static SteamInventoryPolledOperation parseOperation(
    Map<String, Object?>? raw,
  ) {
    final handle = stringOrNull(raw?['handle']);
    final orderId = stringOrNull(raw?['orderId']);
    final transactionId = stringOrNull(
      raw?['transactionId'] ?? raw?['transId'],
    );
    if (raw?['steamIdOk'] == false) {
      return SteamInventoryPolledOperation(
        result: SteamInventoryTransactionResult(
          status: SteamInventoryTransactionStatus.failed,
          providerHandle: handle,
          orderId: orderId,
          transactionId: transactionId,
          issueCode: 'steam_id_mismatch',
        ),
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
      _ when isProviderRejection(resultName) =>
        SteamInventoryTransactionStatus.rejected,
      _ => SteamInventoryTransactionStatus.failed,
    };
    return SteamInventoryPolledOperation(
      result: SteamInventoryTransactionResult(
        status: status,
        providerHandle: handle,
        orderId: orderId,
        transactionId: transactionId,
        issueCode:
            status == SteamInventoryTransactionStatus.confirmed ||
                status == SteamInventoryTransactionStatus.pending
            ? null
            : 'steam_${snakeCase(issueSource)}',
      ),
      grantedItems: _parseItems(raw?['grantedItems']),
    );
  }

  static bool isProviderRejection(String name) => const {
    'k_EResultInsufficientFunds',
    'k_EResultInvalidParam',
    'k_EResultLimitExceeded',
    'k_EResultAlreadyOwned',
    'k_EResultDuplicateRequest',
    'k_EResultInsufficientPrivilege',
  }.contains(name);

  static String? stringOrNull(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static String snakeCase(String input) {
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

  SteamInventoryPolledOperation _indeterminate(
    String handle,
    String issueCode,
  ) => SteamInventoryPolledOperation(
    result: SteamInventoryTransactionResult(
      status: SteamInventoryTransactionStatus.indeterminate,
      providerHandle: handle,
      issueCode: issueCode,
    ),
  );

  static List<SteamInventoryOperationItem> _parseItems(Object? raw) {
    final items = <SteamInventoryOperationItem>[];
    for (final value in raw as List<dynamic>? ?? const []) {
      if (value is! Map) continue;
      final row = Map<Object?, Object?>.from(value);
      final itemDefId = _asInt(row['itemDefId']);
      final quantity = _asInt(row['quantity']);
      if (itemDefId == null ||
          itemDefId <= 0 ||
          quantity == null ||
          quantity <= 0) {
        continue;
      }
      items.add(
        SteamInventoryOperationItem(itemDefId: itemDefId, quantity: quantity),
      );
    }
    return List.unmodifiable(items);
  }

  static int? _asInt(Object? value) => switch (value) {
    int value => value,
    String value => int.tryParse(value),
    _ => null,
  };
}
