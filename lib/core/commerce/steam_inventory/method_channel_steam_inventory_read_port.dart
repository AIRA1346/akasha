import 'package:flutter/services.dart';

import 'steam_inventory_channel_contract.dart';
import 'steam_inventory_read_port.dart';

/// Production read facade over the existing Windows Steam Inventory bridge.
///
/// This class exposes no mutating channel method. Purchase, exchange, promo,
/// consume, and playtime-drop calls remain outside the production read path.
class MethodChannelSteamInventoryReadPort implements SteamInventoryReadPort {
  const MethodChannelSteamInventoryReadPort({
    MethodChannel channel = const MethodChannel(
      SteamInventoryChannelContract.methods,
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<SteamInventoryDiagnostic> diagnostic() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('diagnostic');
      return parseDiagnostic(raw);
    } on MissingPluginException {
      return const SteamInventoryDiagnostic(
        status: SteamInventoryReadStatus.unavailable,
        issueCode: 'steam_missing_plugin',
      );
    } on PlatformException catch (error) {
      return SteamInventoryDiagnostic(
        status: SteamInventoryReadStatus.unavailable,
        issueCode: 'steam_${error.code}',
      );
    }
  }

  @override
  Future<SteamInventoryItemsResult> getAllItems() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'getInventory',
      );
      return parseItems(raw);
    } on MissingPluginException {
      return const SteamInventoryItemsResult(
        status: SteamInventoryReadStatus.unavailable,
        issueCode: 'steam_missing_plugin',
      );
    } on PlatformException catch (error) {
      return SteamInventoryItemsResult(
        status: SteamInventoryReadStatus.failed,
        issueCode: 'steam_${error.code}',
      );
    }
  }

  @override
  Future<SteamInventoryPricesResult> requestPrices() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'requestPrices',
      );
      return parsePrices(raw);
    } on MissingPluginException {
      return const SteamInventoryPricesResult(
        status: SteamInventoryReadStatus.unavailable,
        issueCode: 'steam_missing_plugin',
      );
    } on PlatformException catch (error) {
      return SteamInventoryPricesResult(
        status: SteamInventoryReadStatus.failed,
        issueCode: 'steam_${error.code}',
      );
    }
  }

  static SteamInventoryDiagnostic parseDiagnostic(Map<String, Object?>? raw) {
    if (raw == null || raw['ok'] != true) {
      return SteamInventoryDiagnostic(
        status: SteamInventoryReadStatus.unavailable,
        appId: _asInt(raw?['appId']),
        initialized: raw?['initialized'] == true,
        loggedOn: raw?['loggedOn'] == true || raw?['online'] == true,
        subscribedApp:
            raw?['subscribedApp'] == true || raw?['subscribed'] == true,
        overlayEnabled: raw?['overlayEnabled'] == true,
        overlayActive: raw?['overlayActive'] == true,
        processUptimeMs: _asInt(raw?['processUptimeMs']),
        overlayFirstSampleEnabled: raw?['overlayFirstSampleEnabled'] == true,
        overlayFirstSampleElapsedMs: _asInt(
          raw?['overlayFirstSampleElapsedMs'],
        ),
        overlayFirstTrueElapsedMs: _asInt(raw?['overlayFirstTrueElapsedMs']),
        overlayEnabledSampleCount: _asInt(raw?['overlayEnabledSampleCount']),
        overlayEnabledTransitionCount: _asInt(
          raw?['overlayEnabledTransitionCount'],
        ),
        overlayActivatedCallbackCount: _asInt(
          raw?['overlayActivatedCallbackCount'],
        ),
        overlayDeactivatedCallbackCount: _asInt(
          raw?['overlayDeactivatedCallbackCount'],
        ),
        overlayLastCallbackElapsedMs: _asInt(
          raw?['overlayLastCallbackElapsedMs'],
        ),
        initializationAttempted: raw?['initializationAttempted'] == true,
        restartRequested: raw?['restartRequested'] == true,
        buildMode: _stringOrNull(raw?['buildMode']),
        executablePath: _stringOrNull(raw?['executablePath']),
        currentWorkingDirectory: _stringOrNull(raw?['currentWorkingDirectory']),
        steamTimerTickCount: _asInt(raw?['steamTimerTickCount']),
        overlayNeedsPresentTrueCount: _asInt(
          raw?['overlayNeedsPresentTrueCount'],
        ),
        overlayForceRedrawCount: _asInt(raw?['overlayForceRedrawCount']),
        issueCode: _issue(raw, 'steam_unavailable'),
      );
    }
    final online = raw['loggedOn'] == true || raw['online'] == true;
    return SteamInventoryDiagnostic(
      status: online
          ? SteamInventoryReadStatus.success
          : SteamInventoryReadStatus.offline,
      appId: _asInt(raw['appId']),
      initialized: raw['initialized'] == true,
      loggedOn: online,
      subscribedApp: raw['subscribedApp'] == true || raw['subscribed'] == true,
      overlayEnabled: raw['overlayEnabled'] == true,
      overlayActive: raw['overlayActive'] == true,
      processUptimeMs: _asInt(raw['processUptimeMs']),
      overlayFirstSampleEnabled: raw['overlayFirstSampleEnabled'] == true,
      overlayFirstSampleElapsedMs: _asInt(raw['overlayFirstSampleElapsedMs']),
      overlayFirstTrueElapsedMs: _asInt(raw['overlayFirstTrueElapsedMs']),
      overlayEnabledSampleCount: _asInt(raw['overlayEnabledSampleCount']),
      overlayEnabledTransitionCount: _asInt(
        raw['overlayEnabledTransitionCount'],
      ),
      overlayActivatedCallbackCount: _asInt(
        raw['overlayActivatedCallbackCount'],
      ),
      overlayDeactivatedCallbackCount: _asInt(
        raw['overlayDeactivatedCallbackCount'],
      ),
      overlayLastCallbackElapsedMs: _asInt(raw['overlayLastCallbackElapsedMs']),
      initializationAttempted: raw['initializationAttempted'] == true,
      restartRequested: raw['restartRequested'] == true,
      buildMode: _stringOrNull(raw['buildMode']),
      executablePath: _stringOrNull(raw['executablePath']),
      currentWorkingDirectory: _stringOrNull(raw['currentWorkingDirectory']),
      steamTimerTickCount: _asInt(raw['steamTimerTickCount']),
      overlayNeedsPresentTrueCount: _asInt(raw['overlayNeedsPresentTrueCount']),
      overlayForceRedrawCount: _asInt(raw['overlayForceRedrawCount']),
      issueCode: online ? null : 'steam_offline',
    );
  }

  static SteamInventoryItemsResult parseItems(Map<String, Object?>? raw) {
    if (raw == null || raw['ok'] != true) {
      final issue = _issue(raw, 'steam_inventory_read_failed');
      return SteamInventoryItemsResult(
        status: issue == 'offline'
            ? SteamInventoryReadStatus.offline
            : SteamInventoryReadStatus.failed,
        issueCode: 'steam_$issue',
      );
    }

    final items = <SteamInventoryReadItem>[];
    for (final value in raw['items'] as List<dynamic>? ?? const []) {
      if (value is! Map) continue;
      final row = Map<Object?, Object?>.from(value);
      final instanceId = '${row['instanceId'] ?? ''}'.trim();
      final itemDefId = _asInt(row['itemDefId']);
      final quantity = _asInt(row['quantity']);
      if (instanceId.isEmpty ||
          !_instanceIdPattern.hasMatch(instanceId) ||
          itemDefId == null ||
          quantity == null ||
          quantity < 0) {
        continue;
      }
      items.add(
        SteamInventoryReadItem(
          instanceId: instanceId,
          itemDefId: itemDefId,
          quantity: quantity,
        ),
      );
    }
    return SteamInventoryItemsResult(
      status: SteamInventoryReadStatus.success,
      items: items,
      observedAt: DateTime.now().toUtc(),
    );
  }

  static SteamInventoryPricesResult parsePrices(Map<String, Object?>? raw) {
    if (raw == null || raw['ok'] != true) {
      final issue = _issue(raw, 'steam_prices_failed');
      return SteamInventoryPricesResult(
        status: issue == 'offline'
            ? SteamInventoryReadStatus.offline
            : SteamInventoryReadStatus.failed,
        issueCode: 'steam_$issue',
      );
    }

    final currencyCode = '${raw['currencyCode'] ?? ''}'.trim().toUpperCase();
    if (currencyCode.isEmpty) {
      return const SteamInventoryPricesResult(
        status: SteamInventoryReadStatus.failed,
        issueCode: 'steam_currency_code_missing',
      );
    }

    final prices = <SteamInventoryPriceRow>[];
    for (final value in raw['prices'] as List<dynamic>? ?? const []) {
      if (value is! Map) continue;
      final row = Map<Object?, Object?>.from(value);
      final itemDefId = _asInt(row['itemDefId']);
      final currentAmount =
          _asInt(row['priceAmount']) ?? _asInt(row['priceMicro']);
      final baseAmount = _asInt(row['basePriceAmount']);
      if (itemDefId == null || currentAmount == null || currentAmount < 0) {
        continue;
      }
      prices.add(
        SteamInventoryPriceRow(
          itemDefId: itemDefId,
          currentAmount: currentAmount,
          baseAmount: baseAmount,
        ),
      );
    }
    return SteamInventoryPricesResult(
      status: SteamInventoryReadStatus.success,
      currencyCode: currencyCode,
      prices: prices,
    );
  }

  static int? _asInt(Object? value) => switch (value) {
    final int value => value,
    final num value => value.toInt(),
    _ => null,
  };

  static final RegExp _instanceIdPattern = RegExp(r'^[0-9]+$');

  static String? _stringOrNull(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static String _issue(Map<String, Object?>? raw, String fallback) {
    final value = '${raw?['code'] ?? raw?['status'] ?? fallback}'.trim();
    return value.isEmpty ? fallback : value;
  }
}
