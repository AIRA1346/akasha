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

  int get astra => lastSnapshot?.quantityOf(SteamInventoryPocIds.astraUnit) ?? 0;
  int get echo => lastSnapshot?.quantityOf(SteamInventoryPocIds.echoUnit) ?? 0;
  bool get ownsNocturne =>
      lastSnapshot?.ownsTheme(SteamInventoryPocIds.themeNocturne) ?? false;
  bool get hasConfirmedInventory =>
      lastSnapshot != null && !lastSnapshot!.loadFailed;
  bool get canMutate => hasConfirmedInventory;

  Future<void> initialize() => client.initialize();

  Future<SteamInventorySnapshot> refreshInventory() async {
    activeOp = const SteamInventoryOperation(
      kind: SteamInventoryOpKind.load,
      status: SteamInventoryOpStatus.pending,
    );
    final snap = await client.getAllItems();
    lastSnapshot = snap;
    activeOp = SteamInventoryOperation(
      kind: SteamInventoryOpKind.load,
      status: snap.loadFailed
          ? SteamInventoryOpStatus.failed
          : SteamInventoryOpStatus.ok,
      detail: snap.loadError,
    );
    // On failure: do not invent balances — keep failed snapshot empty.
    return snap;
  }

  Future<void> refreshPrices() async {
    if (!await client.isOnline) return;
    prices = await client.requestPrices();
  }

  Future<String?> buyAstraPack100() async {
    if (!await client.isOnline) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.purchase,
        status: SteamInventoryOpStatus.failed,
        detail: 'offline',
      );
      return null;
    }
    if (!canMutate && lastSnapshot?.loadFailed == true) {
      // Still allow purchase attempt only when online; refresh after.
    }
    activeOp = const SteamInventoryOperation(
      kind: SteamInventoryOpKind.purchase,
      status: SteamInventoryOpStatus.pending,
    );
    final handle = await client.startPurchase(
      itemDefIds: const [SteamInventoryPocIds.astraPack100],
      quantities: const [1],
    );
    activeOp = SteamInventoryOperation(
      kind: SteamInventoryOpKind.purchase,
      status: SteamInventoryOpStatus.pending,
      resultHandle: handle,
    );
    return handle;
  }

  Future<String?> buySupport() async {
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
    final handle = await client.startPurchase(
      itemDefIds: const [SteamInventoryPocIds.supportAkasha],
      quantities: const [1],
    );
    activeOp = SteamInventoryOperation(
      kind: SteamInventoryOpKind.purchase,
      status: SteamInventoryOpStatus.pending,
      resultHandle: handle,
    );
    return handle;
  }

  /// Exchange using Astra recipe when possible, else Echo. No-op if theme owned.
  Future<String?> unlockNocturneTheme({required bool preferAstra}) async {
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

    final useAstra = preferAstra && astra >= SteamInventoryPocIds.themeAstraCost;
    final useEcho = !useAstra && echo >= SteamInventoryPocIds.themeEchoCost;
    if (!useAstra && !useEcho) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.exchange,
        status: SteamInventoryOpStatus.failed,
        detail: 'insufficient_currency',
      );
      return null;
    }

    final defId =
        useAstra ? SteamInventoryPocIds.astraUnit : SteamInventoryPocIds.echoUnit;
    final cost = useAstra
        ? SteamInventoryPocIds.themeAstraCost
        : SteamInventoryPocIds.themeEchoCost;
    final instances = lastSnapshot!.instancesOf(defId);
    if (instances.isEmpty) {
      activeOp = const SteamInventoryOperation(
        kind: SteamInventoryOpKind.exchange,
        status: SteamInventoryOpStatus.failed,
        detail: 'missing_currency_instance',
      );
      return null;
    }
    final material = instances.first;

    activeOp = const SteamInventoryOperation(
      kind: SteamInventoryOpKind.exchange,
      status: SteamInventoryOpStatus.pending,
    );
    final handle = await client.exchangeItems(
      generateItemDefId: SteamInventoryPocIds.themeNocturne,
      generateQuantity: 1,
      destroyInstanceIds: [material.instanceId],
      destroyQuantities: [cost],
    );
    activeOp = SteamInventoryOperation(
      kind: SteamInventoryOpKind.exchange,
      status: SteamInventoryOpStatus.pending,
      resultHandle: handle,
    );
    return handle;
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
        // Re-query is the authority convergence step.
        await refreshInventory();
      } else if (op.status == SteamInventoryOpStatus.failed) {
        // Do not invent balances after failure.
        activeOp = op;
      }
      activeOp = op;
      out.add(op);
    }
    return out;
  }

  /// Themes that may be applied offline: only if last **successful** snapshot owned them.
  bool themeApplicableOffline(int themeDefId) {
    final snap = lastSnapshot;
    if (snap == null || snap.loadFailed) return false;
    return snap.ownsTheme(themeDefId);
  }
}
