import 'package:flutter/foundation.dart';

import 'steam_inventory_client.dart';
import 'steam_inventory_models.dart';
import 'steam_inventory_poc_ids.dart';

/// Orchestrates POC flows. Steam inventory snapshot is the only authority.
///
/// Never writes Astra/Echo/theme ownership to SharedPreferences or Vault.
class SteamInventoryPocController {
  SteamInventoryPocController(this.client);

  final SteamInventoryClient client;

  SteamInventorySnapshot? lastSnapshot;
  SteamInventoryOperation activeOp = const SteamInventoryOperation(
    kind: SteamInventoryOpKind.load,
    status: SteamInventoryOpStatus.idle,
  );
  final Set<String> _seenCompletedHandles = {};
  List<SteamItemPrice> prices = const [];

  /// True while GetAllItems re-query runs after a mutating ResultReady.
  bool _authorityRefreshInFlight = false;

  int get astra => lastSnapshot?.quantityOf(SteamInventoryPocIds.astraUnit) ?? 0;
  int get echo => lastSnapshot?.quantityOf(SteamInventoryPocIds.echoUnit) ?? 0;
  bool get ownsNocturne =>
      lastSnapshot?.ownsTheme(SteamInventoryPocIds.themeNocturne) ?? false;

  /// Confirmed balances only — never while a post-mutation re-query is in flight.
  bool get hasConfirmedInventory =>
      lastSnapshot != null &&
      !lastSnapshot!.loadFailed &&
      !_authorityRefreshInFlight;

  bool get canMutate => hasConfirmedInventory;

  /// Purchase / exchange / consume accepted and awaiting ResultReady (+ re-query).
  bool get isMutationPending {
    if (_authorityRefreshInFlight) return true;
    return activeOp.status == SteamInventoryOpStatus.pending &&
        (activeOp.kind == SteamInventoryOpKind.purchase ||
            activeOp.kind == SteamInventoryOpKind.exchange ||
            activeOp.kind == SteamInventoryOpKind.consume);
  }

  Future<void> initialize() => client.initialize();

  Future<SteamInventorySnapshot> refreshInventory() async {
    _authorityRefreshInFlight = true;
    activeOp = const SteamInventoryOperation(
      kind: SteamInventoryOpKind.load,
      status: SteamInventoryOpStatus.pending,
    );
    try {
      final snap = await client.getAllItems();
      lastSnapshot = snap;
      activeOp = SteamInventoryOperation(
        kind: SteamInventoryOpKind.load,
        status: snap.loadFailed
            ? SteamInventoryOpStatus.failed
            : SteamInventoryOpStatus.ok,
        detail: snap.loadFailed
            ? snap.loadError
            : (kDebugMode ? formatInventoryAudit() : null),
      );
      return snap;
    } finally {
      _authorityRefreshInFlight = false;
    }
  }

  /// Structured GetAllItems audit for Astra/Theme instance IDs (POC log).
  String formatInventoryAudit() {
    final snap = lastSnapshot;
    if (snap == null || snap.loadFailed) {
      return 'inventory_not_confirmed';
    }
    final astraItems = snap.instancesOf(SteamInventoryPocIds.astraUnit);
    final themeItems = snap.instancesOf(SteamInventoryPocIds.themeNocturne);
    final themeTotal =
        snap.quantityOf(SteamInventoryPocIds.themeNocturne);
    final lines = <String>[
      'Astra total=${snap.quantityOf(SteamInventoryPocIds.astraUnit)}',
      for (final i in astraItems)
        'Astra instanceId=${i.instanceId} qty=${i.quantity}',
      if (astraItems.isEmpty) 'Astra instances=(none)',
      'Theme20001 total=$themeTotal '
          'owned=${themeTotal >= 1} '
          'instanceCount=${themeItems.length}',
      for (final i in themeItems)
        'Theme instanceId=${i.instanceId} qty=${i.quantity}',
      if (themeItems.isEmpty) 'Theme instances=(none)',
      if (themeItems.length > 1 || themeTotal > 1)
        'Theme DUPLICATE_OR_MULTI totalQty=$themeTotal '
            'instanceCount=${themeItems.length}',
    ];
    return lines.join(' | ');
  }

  /// POC-only: ConsumeItem on Theme 20001 instance(s). Never touches Astra.
  /// Debug builds only — refused in Release even when POC harness is enabled.
  Future<String?> consumeThemeReset() async {
    if (!kDebugMode) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.consume,
        status: SteamInventoryOpStatus.failed,
        detail: 'dev_reset_disabled',
      );
      return null;
    }
    if (isMutationPending) return null;
    if (!await client.isOnline) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.consume,
        status: SteamInventoryOpStatus.failed,
        detail: 'offline',
      );
      return null;
    }
    if (!hasConfirmedInventory) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.consume,
        status: SteamInventoryOpStatus.failed,
        detail: 'inventory_not_confirmed',
      );
      return null;
    }
    final themes =
        lastSnapshot!.instancesOf(SteamInventoryPocIds.themeNocturne);
    SteamInventoryItem? target;
    for (final i in themes) {
      if (i.quantity > 0 && i.instanceId.isNotEmpty) {
        target = i;
        break;
      }
    }
    if (target == null) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.consume,
        status: SteamInventoryOpStatus.failed,
        detail: 'theme_not_owned',
      );
      return null;
    }
    // Hard guard: only Theme 20001 instance IDs.
    if (target.itemDefId != SteamInventoryPocIds.themeNocturne) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.consume,
        status: SteamInventoryOpStatus.failed,
        detail: 'refuse_non_theme_consume',
      );
      return null;
    }

    activeOp = const SteamInventoryOperation(
      kind: SteamInventoryOpKind.consume,
      status: SteamInventoryOpStatus.pending,
    );
    try {
      final handle = await client.consumeItem(
        instanceId: target.instanceId,
        quantity: 1,
      );
      activeOp = SteamInventoryOperation(
        kind: SteamInventoryOpKind.consume,
        status: SteamInventoryOpStatus.pending,
        resultHandle: handle,
        detail:
            'consumeApiAccepted=true '
            'themeDef=${SteamInventoryPocIds.themeNocturne} '
            'instanceId=${target.instanceId} quantity=1 '
            '(Astra untouched)',
      );
      return handle;
    } catch (e) {
      activeOp = SteamInventoryOperation(
        kind: SteamInventoryOpKind.consume,
        status: SteamInventoryOpStatus.failed,
        detail: 'consumeApiAccepted=false $e',
      );
      return null;
    }
  }

  Future<void> refreshPrices() async {
    if (!await client.isOnline) return;
    prices = await client.requestPrices();
  }

  Future<String?> buyAstraPack100() =>
      _startPurchase(SteamInventoryPocIds.astraPack100);

  Future<String?> buySupport() =>
      _startPurchase(SteamInventoryPocIds.supportAkasha);

  Future<String?> _startPurchase(int itemDefId) async {
    if (isMutationPending) return null;
    if (!await client.isOnline) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.purchase,
        status: SteamInventoryOpStatus.failed,
        detail: 'offline',
      );
      return null;
    }
    activeOp = const SteamInventoryOperation(
      kind: SteamInventoryOpKind.purchase,
      status: SteamInventoryOpStatus.pending,
    );
    try {
      final handle = await client.startPurchase(
        itemDefIds: [itemDefId],
        quantities: const [1],
      );
      activeOp = SteamInventoryOperation(
        kind: SteamInventoryOpKind.purchase,
        status: SteamInventoryOpStatus.pending,
        resultHandle: handle,
      );
      return handle;
    } catch (e) {
      activeOp = SteamInventoryOperation(
        kind: SteamInventoryOpKind.purchase,
        status: SteamInventoryOpStatus.failed,
        detail: '$e',
      );
      return null;
    }
  }

  /// Exchange Astra×100 for Theme Nocturne via ItemDef 20010.
  /// Generate target is the exchange bundle; ownership is still [themeNocturne].
  Future<String?> unlockNocturneTheme({required bool preferAstra}) async {
    if (isMutationPending) return null;
    if (ownsNocturne) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.exchange,
        status: SteamInventoryOpStatus.failed,
        detail: 'theme_already_owned',
      );
      return null;
    }
    if (!await client.isOnline) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.exchange,
        status: SteamInventoryOpStatus.failed,
        detail: 'offline',
      );
      return null;
    }
    if (!hasConfirmedInventory) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.exchange,
        status: SteamInventoryOpStatus.failed,
        detail: 'inventory_not_confirmed',
      );
      return null;
    }

    // Live recipe on 20010 is Astra-only (`10001x100`).
    if (!preferAstra || astra < SteamInventoryPocIds.themeAstraCost) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.exchange,
        status: SteamInventoryOpStatus.failed,
        detail: 'insufficient_currency',
      );
      return null;
    }

    final destroy = _allocateDestroyInstances(
      lastSnapshot!.instancesOf(SteamInventoryPocIds.astraUnit),
      SteamInventoryPocIds.themeAstraCost,
    );
    if (destroy == null) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.exchange,
        status: SteamInventoryOpStatus.failed,
        detail: 'missing_currency_instance',
      );
      return null;
    }

    activeOp = const SteamInventoryOperation(
      kind: SteamInventoryOpKind.exchange,
      status: SteamInventoryOpStatus.pending,
    );
    try {
      final handle = await client.exchangeItems(
        generateItemDefId: SteamInventoryPocIds.themeNocturneExchange,
        generateQuantity: 1,
        destroyInstanceIds: [for (final e in destroy) e.instanceId],
        destroyQuantities: [for (final e in destroy) e.quantity],
      );
      activeOp = SteamInventoryOperation(
        kind: SteamInventoryOpKind.exchange,
        status: SteamInventoryOpStatus.pending,
        resultHandle: handle,
        detail:
            'exchangeApiAccepted=true '
            'generate=${SteamInventoryPocIds.themeNocturneExchange}x1 '
            'generateArrayLength=1 '
            'destroyAstra=${SteamInventoryPocIds.themeAstraCost} '
            'instances=${destroy.map((e) => '${e.instanceId}x${e.quantity}').join(',')}',
      );
      return handle;
    } catch (e) {
      activeOp = SteamInventoryOperation(
        kind: SteamInventoryOpKind.exchange,
        status: SteamInventoryOpStatus.failed,
        detail: 'exchangeApiAccepted=false $e',
      );
      return null;
    }
  }

  /// Split [need] across real Steam item instance IDs (never ItemDef IDs).
  static List<({String instanceId, int quantity})>? _allocateDestroyInstances(
    List<SteamInventoryItem> instances,
    int need,
  ) {
    if (need <= 0) return const [];
    final out = <({String instanceId, int quantity})>[];
    var remaining = need;
    for (final item in instances) {
      if (remaining <= 0) break;
      if (item.instanceId.isEmpty || item.quantity <= 0) continue;
      final take =
          item.quantity < remaining ? item.quantity : remaining;
      out.add((instanceId: item.instanceId, quantity: take));
      remaining -= take;
    }
    if (remaining > 0) return null;
    return out;
  }

  Future<String?> claimEchoPromo() async {
    if (!await client.isOnline) return null;
    return client.addPromoItem(SteamInventoryPocIds.echoStarterPromo);
  }

  Future<String?> claimEchoPlaytimeDrop() async {
    if (!await client.isOnline) return null;
    // Contract: playtime grants require TriggerItemDrop from the app.
    return client.triggerItemDrop(SteamInventoryPocIds.echoPlaytimeGenerator);
  }

  /// Resolve pending Steam results; refresh inventory on success.
  /// Duplicate completed handles do not apply local grants again.
  ///
  /// Success means Steam reported OK — balances/themes update only via
  /// [refreshInventory], never from the result payload alone.
  /// Every completed handle is [destroyResult]'d (native also DestroyResult
  /// in OnResultReady; Dart call is idempotent bookkeeping).
  Future<List<SteamInventoryOperation>> pump() async {
    final ops = await client.poll();
    final out = <SteamInventoryOperation>[];
    for (final op in ops) {
      final h = op.resultHandle;
      if (op.status == SteamInventoryOpStatus.pending) {
        activeOp = op;
        out.add(op);
        continue;
      }
      if (h != null && _seenCompletedHandles.contains(h)) {
        await client.destroyResult(h);
        out.add(op);
        continue;
      }
      if (h != null) {
        _seenCompletedHandles.add(h);
        await client.destroyResult(h);
      }
      if (op.status == SteamInventoryOpStatus.ok) {
        // Mark unconfirmed immediately so stale balances are not shown as final.
        _authorityRefreshInFlight = true;
        activeOp = SteamInventoryOperation(
          kind: op.kind,
          status: SteamInventoryOpStatus.pending,
          resultHandle: h,
          detail: kDebugMode
              ? '${op.detail ?? ''} | awaiting_getAllItems_requery'
              : 'awaiting_getAllItems_requery',
        );
        await refreshInventory();
        activeOp = SteamInventoryOperation(
          kind: op.kind,
          status: SteamInventoryOpStatus.ok,
          resultHandle: h,
          detail: kDebugMode ? op.detail : null,
        );
      } else if (op.status == SteamInventoryOpStatus.failed) {
        activeOp = op;
      } else {
        activeOp = op;
      }
      out.add(op);
    }
    return out;
  }

  /// Themes that may be applied offline: only if last **successful** snapshot owned them.
  bool themeApplicableOffline(int themeDefId) {
    final snap = lastSnapshot;
    if (snap == null || snap.loadFailed || _authorityRefreshInFlight) {
      return false;
    }
    return snap.ownsTheme(themeDefId);
  }
}
