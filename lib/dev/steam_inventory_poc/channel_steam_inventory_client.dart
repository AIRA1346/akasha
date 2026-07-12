import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'steam_inventory_client.dart';
import 'steam_inventory_models.dart';

/// MethodChannel + EventChannel bridge to Windows Steam Inventory C++ glue.
///
/// Never treats StartPurchase / ExchangeItems acceptance as a grant.
/// Authority is always a subsequent successful [getAllItems] snapshot.
class ChannelSteamInventoryClient implements SteamInventoryClient {
  ChannelSteamInventoryClient({
    MethodChannel? channel,
    EventChannel? events,
  })  : _channel = channel ?? const MethodChannel('akasha/steam_inventory_poc'),
        _events =
            events ?? const EventChannel('akasha/steam_inventory_poc/events');

  final MethodChannel _channel;
  final EventChannel _events;
  StreamSubscription<dynamic>? _eventSub;
  final _eventController =
      StreamController<SteamInventoryOperation>.broadcast();

  bool _available = false;
  bool _online = false;

  /// Live inventory/result events from native (`pending` / `success` / …).
  Stream<SteamInventoryOperation> get inventoryEvents => _eventController.stream;

  @override
  Future<bool> get isAvailable async => _available;

  @override
  Future<bool> get isOnline async => _online && _available;

  Future<Map<String, Object?>> diagnostic() async {
    try {
      final raw =
          await _channel.invokeMapMethod<String, Object?>('diagnostic') ??
              await _channel.invokeMapMethod<String, Object?>('diagnostics') ??
              await _channel.invokeMapMethod<String, Object?>('initialize');
      return Map<String, Object?>.from(raw ?? const {});
    } on MissingPluginException {
      return const {'ok': false, 'code': 'missing_plugin'};
    } on PlatformException catch (e) {
      return {'ok': false, 'code': e.code, 'message': e.message};
    }
  }

  @override
  Future<void> initialize() async {
    try {
      final result = await diagnostic();
      _available = result['ok'] == true;
      _online = result['loggedOn'] == true || result['online'] == true;
      if (!_available) {
        debugPrint(
          'SteamInventoryPOC: initialize failed '
          '(${result['code'] ?? 'unknown'}).',
        );
        return;
      }
      await _eventSub?.cancel();
      _eventSub = _events.receiveBroadcastStream().listen(
        (dynamic raw) {
          final map = Map<String, Object?>.from(raw as Map);
          final op = opFromMap(map);
          if (!_eventController.isClosed) {
            _eventController.add(op);
          }
        },
        onError: (Object e) {
          debugPrint('SteamInventoryPOC event error: $e');
        },
      );
    } on MissingPluginException {
      _available = false;
      _online = false;
    } on PlatformException catch (e) {
      _available = false;
      _online = false;
      debugPrint('SteamInventoryPOC init failed: ${e.code} ${e.message}');
    }
  }

  @override
  Future<SteamInventorySnapshot> getAllItems() async {
    if (!_available) {
      return SteamInventorySnapshot.emptyFailed('steam_unavailable');
    }
    try {
      final raw =
          await _channel.invokeMapMethod<String, Object?>('getInventory') ??
              await _channel.invokeMapMethod<String, Object?>('getAllItems');
      if (raw == null || raw['ok'] != true) {
        _online = raw?['code'] != 'offline' ? _online : false;
        final code = raw?['code'] ?? raw?['status'] ?? 'getInventory_failed';
        final steamResult = raw?['steamResult'];
        final defCount = raw?['defCount'];
        final detail = raw?['detail'];
        final subscribed = raw?['subscribed'];
        final parts = <String>[
          '$code',
          if (steamResult != null) 'steamResult=$steamResult',
          if (defCount != null) 'defs=$defCount',
          if (subscribed != null) 'subscribed=$subscribed',
          if (detail != null) '$detail',
        ];
        return SteamInventorySnapshot.emptyFailed(parts.join(' | '));
      }
      final list = (raw['items'] as List<dynamic>? ?? const [])
          .map(_itemFromMap)
          .toList(growable: false);
      _online = true;
      return SteamInventorySnapshot(
        items: list,
        fetchedAt: DateTime.now().toUtc(),
      );
    } on PlatformException catch (e) {
      return SteamInventorySnapshot.emptyFailed(e.code);
    }
  }

  @override
  Future<List<SteamItemPrice>> requestPrices() async {
    if (!_available) return const [];
    final raw =
        await _channel.invokeMapMethod<String, Object?>('requestPrices');
    if (raw == null || raw['ok'] != true) return const [];
    final list = raw['prices'] as List<dynamic>? ?? const [];
    return [
      for (final e in list)
        SteamItemPrice(
          itemDefId: (e as Map)['itemDefId'] as int,
          priceMicro: (e['priceMicro'] as num).toInt(),
        ),
    ];
  }

  @override
  Future<String> startPurchase({
    required List<int> itemDefIds,
    required List<int> quantities,
  }) async {
    final raw = await _channel.invokeMapMethod<String, Object?>('startPurchase', {
      'itemDefIds': itemDefIds,
      'quantities': quantities,
    });
    if (raw == null || raw['ok'] != true) {
      throw StateError('${raw?['code'] ?? 'startPurchase_failed'}');
    }
    // Acceptance ≠ grant.
    return '${raw['handle']}';
  }

  @override
  Future<String> exchangeItems({
    required int generateItemDefId,
    required int generateQuantity,
    required List<String> destroyInstanceIds,
    required List<int> destroyQuantities,
  }) async {
    final raw = await _channel.invokeMapMethod<String, Object?>('exchangeItems', {
      'generateItemDefId': generateItemDefId,
      'generateQuantity': generateQuantity,
      'destroyInstanceIds': destroyInstanceIds,
      'destroyQuantities': destroyQuantities,
    });
    final accepted = raw?['exchangeApiAccepted'] == true;
    if (raw == null || raw['ok'] != true || !accepted) {
      throw StateError(
        '${raw?['code'] ?? 'exchange_failed'} '
        'exchangeApiAccepted=$accepted '
        '${raw?['detail'] ?? ''}'.trim(),
      );
    }
    // Acceptance ≠ theme unlock. Immediate bool is recorded by caller detail.
    return '${raw['handle']}';
  }

  @override
  Future<String> consumeItem({
    required String instanceId,
    required int quantity,
  }) async {
    final raw = await _channel.invokeMapMethod<String, Object?>('consumeItem', {
      'instanceId': instanceId,
      'quantity': quantity,
    });
    final accepted = raw?['consumeApiAccepted'] == true;
    if (raw == null || raw['ok'] != true || !accepted) {
      throw StateError(
        '${raw?['code'] ?? 'consume_failed'} '
        'consumeApiAccepted=$accepted '
        '${raw?['detail'] ?? ''}'.trim(),
      );
    }
    return '${raw['handle']}';
  }

  @override
  Future<String> addPromoItem(int itemDefId) async {
    final raw = await _channel.invokeMapMethod<String, Object?>('addPromoItem', {
      'itemDefId': itemDefId,
    });
    if (raw == null || raw['ok'] != true) {
      throw StateError('${raw?['code'] ?? 'promo_failed'}');
    }
    return '${raw['handle']}';
  }

  @override
  Future<String> triggerItemDrop(int playtimeGeneratorDefId) async {
    final raw =
        await _channel.invokeMapMethod<String, Object?>('triggerItemDrop', {
      'generatorDefId': playtimeGeneratorDefId,
    });
    if (raw == null || raw['ok'] != true) {
      throw StateError('${raw?['code'] ?? 'drop_failed'}');
    }
    return '${raw['handle']}';
  }

  @override
  Future<List<SteamInventoryOperation>> poll() async {
    if (!_available) return const [];
    final raw = await _channel.invokeMapMethod<String, Object?>('poll');
    if (raw == null || raw['ok'] != true) return const [];
    final ops = raw['ops'] as List<dynamic>? ?? const [];
    return [
      for (final e in ops)
        opFromMap(Map<String, Object?>.from(e as Map)),
    ];
  }

  @override
  Future<void> destroyResult(String resultHandle) async {
    if (!_available) return;
    await _channel.invokeMethod<void>('destroyResult', {
      'handle': resultHandle,
    });
  }

  @override
  Future<void> dispose() async {
    await _eventSub?.cancel();
    _eventSub = null;
    if (_available) {
      await _channel.invokeMethod<void>('shutdown');
    }
    _available = false;
    _online = false;
  }

  static SteamInventoryItem _itemFromMap(dynamic e) {
    final m = Map<String, Object?>.from(e as Map);
    return SteamInventoryItem(
      instanceId: '${m['instanceId']}',
      itemDefId: m['itemDefId'] as int,
      quantity: m['quantity'] as int,
      flags: (m['flags'] as int?) ?? 0,
    );
  }

  static SteamInventoryOperation opFromMap(Map<String, Object?> m) {
    final kindName = '${m['kind'] ?? 'load'}';
    final kind = SteamInventoryOpKind.values.asNameMap()[kindName] ??
        SteamInventoryOpKind.load;
    final code = m['steamResultCode'];
    final name = m['steamResultName'];
    final order = m['orderId'];
    final tx = m['transactionId'] ?? m['transId'];
    final baseDetail = m['detail'] as String?;
    final removedSummary = _itemListSummary(m['removedItems'], 'removed');
    final grantedSummary = _itemListSummary(m['grantedItems'], 'granted');
    final rich = <String>[
      if (baseDetail != null && baseDetail.isNotEmpty) baseDetail,
      if (code != null) 'steamResultCode=$code',
      if (name != null) 'steamResultName=$name',
      if (order != null) 'orderId=$order',
      if (tx != null) 'transactionId=$tx',
      if (m['apiCallHandle'] != null) 'apiCall=${m['apiCallHandle']}',
      if (m['phase'] != null) 'phase=${m['phase']}',
      if (m['exchangeApiAccepted'] != null)
        'exchangeApiAccepted=${m['exchangeApiAccepted']}',
      if (m['consumeApiAccepted'] != null)
        'consumeApiAccepted=${m['consumeApiAccepted']}',
      ?removedSummary,
      ?grantedSummary,
    ].join(' | ');
    return SteamInventoryOperation(
      kind: kind,
      status: parseNativeStatus('${m['status']}'),
      detail: rich.isEmpty ? baseDetail : rich,
      resultHandle: m['handle'] as String?,
    );
  }

  static String? _itemListSummary(Object? raw, String label) {
    if (raw is! List || raw.isEmpty) return null;
    final parts = <String>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, Object?>.from(e);
      parts.add(
        'def=${m['itemDefId']} id=${m['instanceId']} qty=${m['quantity']}'
        ' flags=${m['flags']}',
      );
    }
    if (parts.isEmpty) return null;
    return '$label=[${parts.join('; ')}]';
  }

  /// Maps native status strings. Unknown/indeterminate/canceled ≠ success.
  static SteamInventoryOpStatus parseNativeStatus(String status) {
    switch (status) {
      case 'success':
      case 'ok':
        return SteamInventoryOpStatus.ok;
      case 'pending':
        return SteamInventoryOpStatus.pending;
      case 'canceled':
      case 'failed':
      case 'indeterminate':
        return SteamInventoryOpStatus.failed;
      default:
        return SteamInventoryOpStatus.failed;
    }
  }
}
