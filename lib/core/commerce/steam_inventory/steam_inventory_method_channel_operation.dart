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
    this.overlayCloseGracePeriod = const Duration(seconds: 3),
    this.recoverAfterOverlayClose = false,
    this.clock,
    this.delay,
  }) : _channel = channel;

  final MethodChannel _channel;
  final Duration pollInterval;
  final Duration completionTimeout;
  final Duration overlayCloseGracePeriod;
  final bool recoverAfterOverlayClose;
  final DateTime Function()? clock;
  final Future<void> Function(Duration duration)? delay;

  Future<SteamInventoryPolledOperation> awaitTerminal(String handle) async {
    final now = clock ?? DateTime.now;
    final wait = delay ?? Future<void>.delayed;
    final deadline = now().add(completionTimeout);
    String? orderId;
    String? transactionId;
    String? phase;
    String? apiCallHandle;
    int? providerResultCode;
    String? providerResultName;
    String? detail;
    DateTime? overlayClosedAt;
    while (now().isBefore(deadline)) {
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
        final event = Map<String, Object?>.from(value);
        final operation = parseOperation(event);
        if (operation.result.providerHandle != handle) continue;
        final overlayActive = event['overlayActive'];
        if (recoverAfterOverlayClose && overlayActive is bool) {
          if (overlayActive) {
            overlayClosedAt = null;
          } else {
            // The opening callback can arrive before Dart starts polling.
            // This event is already correlated by native code to the current
            // purchase, so closure alone may start grace + reconciliation.
            overlayClosedAt ??= now();
          }
        }
        orderId ??= operation.result.orderId;
        transactionId ??= operation.result.transactionId;
        phase = operation.result.phase ?? phase;
        apiCallHandle = operation.result.apiCallHandle ?? apiCallHandle;
        providerResultCode =
            operation.result.providerResultCode ?? providerResultCode;
        providerResultName =
            operation.result.providerResultName ?? providerResultName;
        detail = operation.result.detail ?? detail;
        if (!operation.result.isTerminal) continue;
        return SteamInventoryPolledOperation(
          result: SteamInventoryTransactionResult(
            status: operation.result.status,
            providerHandle: operation.result.providerHandle,
            orderId: operation.result.orderId ?? orderId,
            transactionId: operation.result.transactionId ?? transactionId,
            phase: operation.result.phase ?? phase,
            apiCallHandle: operation.result.apiCallHandle ?? apiCallHandle,
            providerResultCode:
                operation.result.providerResultCode ?? providerResultCode,
            providerResultName:
                operation.result.providerResultName ?? providerResultName,
            detail: operation.result.detail ?? detail,
            issueCode: operation.result.issueCode,
          ),
          grantedItems: operation.grantedItems,
        );
      }

      final closedAt = overlayClosedAt;
      if (closedAt != null &&
          !now().isBefore(closedAt.add(overlayCloseGracePeriod))) {
        return SteamInventoryPolledOperation(
          result: SteamInventoryTransactionResult(
            status: SteamInventoryTransactionStatus.indeterminate,
            providerHandle: handle,
            orderId: orderId,
            transactionId: transactionId,
            phase: 'purchase_overlay_closed_grace_elapsed',
            apiCallHandle: apiCallHandle,
            providerResultCode: providerResultCode,
            providerResultName: providerResultName,
            detail: detail,
            issueCode: 'steam_purchase_overlay_closed',
          ),
        );
      }
      if (pollInterval > Duration.zero) {
        await wait(pollInterval);
      }
    }
    return SteamInventoryPolledOperation(
      result: SteamInventoryTransactionResult(
        status: SteamInventoryTransactionStatus.indeterminate,
        providerHandle: handle,
        orderId: orderId,
        transactionId: transactionId,
        phase: phase,
        apiCallHandle: apiCallHandle,
        providerResultCode: providerResultCode,
        providerResultName: providerResultName,
        detail: detail,
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
    final phase = stringOrNull(raw?['phase']);
    final apiCallHandle = stringOrNull(raw?['apiCallHandle']);
    final providerResultCode = _asInt(raw?['steamResultCode']);
    final providerResultName = stringOrNull(raw?['steamResultName']);
    final detail = stringOrNull(raw?['detail']);
    if (raw?['steamIdOk'] == false) {
      return SteamInventoryPolledOperation(
        result: SteamInventoryTransactionResult(
          status: SteamInventoryTransactionStatus.failed,
          providerHandle: handle,
          orderId: orderId,
          transactionId: transactionId,
          phase: phase,
          apiCallHandle: apiCallHandle,
          providerResultCode: providerResultCode,
          providerResultName: providerResultName,
          detail: detail,
          issueCode: 'steam_id_mismatch',
        ),
      );
    }
    final statusName = '${raw?['status'] ?? 'failed'}'.trim();
    final resultName = providerResultName ?? '';
    final nativeCode = stringOrNull(raw?['code']);
    final issueSource = resultName.isNotEmpty
        ? resultName
        : nativeCode ?? statusName;
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
        phase: phase,
        apiCallHandle: apiCallHandle,
        providerResultCode: providerResultCode,
        providerResultName: providerResultName,
        detail: detail,
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
    'k_EResultAccessDenied',
    'k_EResultInvalidState',
    'k_EResultRegionLocked',
    'k_EResultRestrictedDevice',
    'k_EResultParentalControlRestricted',
  }.contains(name);

  static String? stringOrNull(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static String snakeCase(String input) {
    if (input == 'k_uAPICallInvalid') return 'api_call_invalid';
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
      phase: 'poll',
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
