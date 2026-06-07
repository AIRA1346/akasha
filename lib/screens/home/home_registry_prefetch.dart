import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/enums.dart';
import '../../services/works_registry.dart';
import 'home_browse_filter_controller.dart';

/// 필터·대시보드 범위에 맞는 lazy 샤드 프리페치
Future<void> prefetchRegistryForFilters({
  required String? activeDashboardId,
  required HomeBrowseFilterController filters,
  required void Function(bool loading) onCatalogLoadingChanged,
  required bool Function() isMounted,
  required VoidCallback onDataChanged,
}) async {
  if (activeDashboardId == 'master_index') {
    if (isMounted()) onCatalogLoadingChanged(true);
    await WorksRegistry.prefetchMasterCatalog();
    if (isMounted()) {
      onCatalogLoadingChanged(false);
    }
    unawaited(
      WorksRegistry.prefetchMasterCatalog(fetchRemote: true).then((_) {
        if (isMounted()) onDataChanged();
      }),
    );
    return;
  }

  if (filters.domain == null && filters.categories.isEmpty) {
    if (isMounted()) onDataChanged();
    return;
  }

  await WorksRegistry.prefetchForFilters(
    domain: filters.domain,
    categories: filters.categories.isEmpty
        ? null
        : Set<MediaCategory>.from(filters.categories),
  );

  if (isMounted()) onDataChanged();
}
