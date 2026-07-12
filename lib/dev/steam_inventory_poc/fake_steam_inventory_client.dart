import 'steam_inventory_client.dart';
import 'steam_inventory_models.dart';
import 'steam_inventory_poc_ids.dart';

/// In-process Steam Inventory stand-in for POC logic tests.
///
/// Does not claim live Steamworks success.
class FakeSteamInventoryClient implements SteamInventoryClient {
  FakeSteamInventoryClient({
    this.online = true,
    Map<int, int>? initialStacks,
  }) {
    if (initialStacks != null) {
      for (final e in initialStacks.entries) {
        _setStack(e.key, e.value);
      }
    }
  }

  bool online;
  bool failNextLoad = false;
  bool delayPurchase = false;
  bool delayExchange = false;
  final Map<String, _Pending> _pending = {};
  final Map<int, _Stack> _stacks = {};
  final Set<String> _destroyedHandles = {};
  final List<String> completedHandleLog = [];
  var _seq = 0;
  var _instanceSeq = 0;

  void _setStack(int defId, int qty) {
    if (qty <= 0) {
      _stacks.remove(defId);
      return;
    }
    _stacks[defId] = _Stack(
      instanceId: 'inst_${defId}_${++_instanceSeq}',
      quantity: qty,
    );
  }

  int stackQty(int defId) => _stacks[defId]?.quantity ?? 0;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> get isOnline async => online;

  @override
  Future<void> initialize() async {}

  @override
  Future<SteamInventorySnapshot> getAllItems() async {
    if (failNextLoad) {
      failNextLoad = false;
      return SteamInventorySnapshot.emptyFailed('inventory_unavailable');
    }
    if (!online) {
      return SteamInventorySnapshot.emptyFailed('offline');
    }
    final items = <SteamInventoryItem>[
      for (final e in _stacks.entries)
        SteamInventoryItem(
          instanceId: e.value.instanceId,
          itemDefId: e.key,
          quantity: e.value.quantity,
        ),
    ];
    return SteamInventorySnapshot(
      items: items,
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<SteamItemPrice>> requestPrices() async {
    if (!online) return const [];
    return const [
      SteamItemPrice(itemDefId: SteamInventoryPocIds.astraPack100, priceMicro: 990000),
      SteamItemPrice(itemDefId: SteamInventoryPocIds.supportAkasha, priceMicro: 990000),
    ];
  }

  @override
  Future<String> startPurchase({
    required List<int> itemDefIds,
    required List<int> quantities,
  }) async {
    if (!online) {
      throw StateError('offline');
    }
    final handle = 'purchase_${++_seq}';
    _pending[handle] = _Pending(
      kind: SteamInventoryOpKind.purchase,
      apply: () {
        for (var i = 0; i < itemDefIds.length; i++) {
          final def = itemDefIds[i];
          final q = quantities[i];
          if (def == SteamInventoryPocIds.astraPack100) {
            _setStack(
              SteamInventoryPocIds.astraUnit,
              stackQty(SteamInventoryPocIds.astraUnit) + 100 * q,
            );
          } else if (def == SteamInventoryPocIds.supportAkasha) {
            _setStack(
              SteamInventoryPocIds.supportAkasha,
              stackQty(SteamInventoryPocIds.supportAkasha) + q,
            );
          } else {
            _setStack(def, stackQty(def) + q);
          }
        }
      },
      autoComplete: !delayPurchase,
    );
    return handle;
  }

  @override
  Future<String> exchangeItems({
    required int generateItemDefId,
    required int generateQuantity,
    required List<String> destroyInstanceIds,
    required List<int> destroyQuantities,
  }) async {
    if (!online) throw StateError('offline');
    final handle = 'exchange_${++_seq}';
    _pending[handle] = _Pending(
      kind: SteamInventoryOpKind.exchange,
      apply: () {
        for (var i = 0; i < destroyInstanceIds.length; i++) {
          final id = destroyInstanceIds[i];
          final need = destroyQuantities[i];
          MapEntry<int, _Stack>? entry;
          for (final e in _stacks.entries) {
            if (e.value.instanceId == id) {
              entry = e;
              break;
            }
          }
          if (entry == null || entry.value.quantity < need) {
            throw StateError('insufficient_materials');
          }
          _setStack(entry.key, entry.value.quantity - need);
        }
        // Bundle 20010 expands to Theme 20001 (matches Steam ItemDef).
        final grantDef =
            generateItemDefId == SteamInventoryPocIds.themeNocturneExchange
            ? SteamInventoryPocIds.themeNocturne
            : generateItemDefId;
        final grantQty =
            generateItemDefId == SteamInventoryPocIds.themeNocturneExchange
            ? 1
            : generateQuantity;
        _setStack(grantDef, stackQty(grantDef) + grantQty);
      },
      autoComplete: !delayExchange,
    );
    return handle;
  }

  @override
  Future<String> consumeItem({
    required String instanceId,
    required int quantity,
  }) async {
    if (!online) throw StateError('offline');
    if (quantity != 1) throw StateError('invalid_consume_quantity');
    final handle = 'consume_${++_seq}';
    _pending[handle] = _Pending(
      kind: SteamInventoryOpKind.consume,
      apply: () {
        MapEntry<int, _Stack>? entry;
        for (final e in _stacks.entries) {
          if (e.value.instanceId == instanceId) {
            entry = e;
            break;
          }
        }
        if (entry == null || entry.value.quantity < quantity) {
          throw StateError('consume_missing_instance');
        }
        // POC reset must only hit Theme; refuse other defs in fake too.
        if (entry.key != SteamInventoryPocIds.themeNocturne) {
          throw StateError('refuse_non_theme_consume');
        }
        _setStack(entry.key, entry.value.quantity - quantity);
      },
      autoComplete: true,
    );
    return handle;
  }

  @override
  Future<String> addPromoItem(int itemDefId) async {
    final handle = 'promo_${++_seq}';
    _pending[handle] = _Pending(
      kind: SteamInventoryOpKind.promo,
      apply: () {
        if (itemDefId == SteamInventoryPocIds.echoStarterPromo) {
          _setStack(
            SteamInventoryPocIds.echoUnit,
            stackQty(SteamInventoryPocIds.echoUnit) + 25,
          );
        } else {
          _setStack(itemDefId, stackQty(itemDefId) + 1);
        }
      },
      autoComplete: true,
    );
    return handle;
  }

  @override
  Future<String> triggerItemDrop(int playtimeGeneratorDefId) async {
    final handle = 'drop_${++_seq}';
    _pending[handle] = _Pending(
      kind: SteamInventoryOpKind.playtimeDrop,
      apply: () {
        if (playtimeGeneratorDefId == SteamInventoryPocIds.echoPlaytimeGenerator) {
          _setStack(
            SteamInventoryPocIds.echoUnit,
            stackQty(SteamInventoryPocIds.echoUnit) + 5,
          );
        }
      },
      autoComplete: true,
    );
    return handle;
  }

  /// Complete a delayed handle (tests).
  void complete(String handle) {
    final p = _pending[handle];
    if (p == null) return;
    p.autoComplete = true;
  }

  @override
  Future<List<SteamInventoryOperation>> poll() async {
    final done = <SteamInventoryOperation>[];
    final keys = _pending.keys.toList();
    for (final h in keys) {
      if (_destroyedHandles.contains(h)) {
        _pending.remove(h);
        continue;
      }
      final p = _pending[h]!;
      if (!p.autoComplete) {
        done.add(
          SteamInventoryOperation(
            kind: p.kind,
            status: SteamInventoryOpStatus.pending,
            resultHandle: h,
          ),
        );
        continue;
      }
      try {
        p.apply();
        completedHandleLog.add(h);
        done.add(
          SteamInventoryOperation(
            kind: p.kind,
            status: SteamInventoryOpStatus.ok,
            resultHandle: h,
          ),
        );
      } catch (e) {
        done.add(
          SteamInventoryOperation(
            kind: p.kind,
            status: SteamInventoryOpStatus.failed,
            detail: e.toString(),
            resultHandle: h,
          ),
        );
      }
      _pending.remove(h);
    }
    return done;
  }

  @override
  Future<void> destroyResult(String resultHandle) async {
    _destroyedHandles.add(resultHandle);
    _pending.remove(resultHandle);
  }

  @override
  Future<void> dispose() async {
    _pending.clear();
  }
}

class _Stack {
  _Stack({required this.instanceId, required this.quantity});
  final String instanceId;
  int quantity;
}

class _Pending {
  _Pending({
    required this.kind,
    required this.apply,
    required this.autoComplete,
  });
  final SteamInventoryOpKind kind;
  final void Function() apply;
  bool autoComplete;
}
