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

  @override
  Future<void> initialize() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, Object?>('initialize') ??
              await _channel.invokeMapMethod<String, Object?>('init');
      _available = result?['ok'] == true;
      _online = result?['online'] == true;
      if (!_available) {
        debugPrint(
          'SteamInventoryPOC: initialize failed '
          '(${result?['code'] ?? 'unknown'}).',
        );
        return;
      }
      await _eventSub?.cancel();
      _eventSub = _events.receiveBroadcastStream().listen(
        (dynamic raw) {
          final op = opFromMap(Map<String, Object?>.from(raw as Map));
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
        return SteamInventorySnapshot.emptyFailed(
          '${raw?['code'] ?? raw?['status'] ?? 'getInventory_failed'}',
        );
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
    if (raw == null || raw['ok'] != true) {
      throw StateError('${raw?['code'] ?? 'exchange_failed'}');
    }
    // Acceptance ≠ theme unlock.
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
    return SteamInventoryOperation(
      kind: kind,
      status: parseNativeStatus('${m['status']}'),
      detail: m['detail'] as String?,
      resultHandle: m['handle'] as String?,
    );
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
