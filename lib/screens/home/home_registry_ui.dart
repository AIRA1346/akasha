import 'package:flutter/material.dart';

import '../../services/works_registry.dart';
import 'dialogs/clear_registry_cache_confirm_dialog.dart';
import 'home_registry_prefetch.dart';
import 'home_browse_filter_controller.dart';
import 'home_dashboard_controller.dart';

/// 글로벌 사전 캐시 삭제·prefetch Presentation glue.
class HomeRegistryUi {
  const HomeRegistryUi();

  Future<void> clearDiskCacheAndReload(
    BuildContext context, {
    required HomeDashboardController dashboardCtrl,
    required HomeBrowseFilterController filterCtrl,
    required void Function(bool loading) onCatalogLoadingChanged,
    required bool Function() isMounted,
    required void Function(void Function()) setState,
    required void Function() onDataChanged,
  }) async {
    final confirmed = await showClearRegistryCacheConfirmDialog(context);
    if (confirmed != true || !context.mounted) return;

    onCatalogLoadingChanged(true);
    setState(() {});
    try {
      await WorksRegistry.clearDiskCacheAndReloadBundle();
      await prefetchRegistryForFilters(
        activeDashboardId: dashboardCtrl.activeDashboardId,
        filters: filterCtrl,
        onCatalogLoadingChanged: onCatalogLoadingChanged,
        isMounted: isMounted,
        onDataChanged: onDataChanged,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사전 캐시를 삭제하고 번들 사전으로 복원했습니다.'),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('캐시 삭제 실패: $e')),
        );
      }
    } finally {
      onCatalogLoadingChanged(false);
      if (context.mounted) setState(() {});
    }
  }
}
