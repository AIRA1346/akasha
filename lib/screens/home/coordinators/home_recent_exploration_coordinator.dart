import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/recent_exploration_resolver.dart';
import '../../../services/recent_exploration_store.dart';

/// 사이드바 「최근 탐색」 기록·해석.
class HomeRecentExplorationCoordinator {
  HomeRecentExplorationCoordinator({
    required this.isMounted,
    required this.rebuild,
    required this.getVaultItems,
    required this.userCatalog,
  }) {
    store = RecentExplorationStore(onChanged: _onStoreChanged);
  }

  final bool Function() isMounted;
  final void Function() rebuild;
  final List<AkashaItem> Function() getVaultItems;
  final UserCatalogPort userCatalog;

  late final RecentExplorationStore store;
  List<AkashaItem> items = [];

  void _onStoreChanged() {
    if (!isMounted()) return;
    refresh();
  }

  Future<void> load() async {
    await store.load();
    await refresh();
  }

  Future<void> refresh() async {
    items = resolveRecentExplorationItems(
      itemKeys: store.itemKeys,
      vaultItems: getVaultItems(),
      userCatalog: userCatalog,
    );
    rebuild();
  }

  void openItem(
    AkashaItem item, {
    required void Function(UserCatalogEntity entity) openEntityPreview,
    required void Function(AkashaItem work) openWorkPreview,
  }) {
    if (item is EntityItem) {
      final entity = userCatalog.getById(item.entityId);
      if (entity != null) {
        openEntityPreview(entity);
        return;
      }
    }
    openWorkPreview(item);
  }
}
