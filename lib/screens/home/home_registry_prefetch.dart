import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/enums.dart';
import '../../services/works_registry.dart';
import 'home_browse_filter_controller.dart';

/// 윈도우 prefetch 후 UI에 전달할 카탈로그 진행 상태
typedef CatalogWindowState = ({int browseOffset, int totalEntries});

/// 필터·대시보드 범위에 맞는 lazy 샤드 프리페치
Future<void> prefetchRegistryForFilters({
  required String? activeDashboardId,
  required HomeBrowseFilterController filters,
  required void Function(bool loading) onCatalogLoadingChanged,
  required bool Function() isMounted,
  required VoidCallback onDataChanged,
  void Function(CatalogWindowState state)? onCatalogWindowState,
  int browseOffset = 0,
  bool append = false,
}) async {
  if (activeDashboardId == 'master_index') {
    if (filters.domain != null || filters.categories.isNotEmpty) {
      await WorksRegistry.prefetchForFilters(
        domain: filters.domain,
        categories: filters.categories.isEmpty
            ? null
            : Set<MediaCategory>.from(filters.categories),
      );
      if (isMounted()) onDataChanged();
      return;
    }

    if (!append && isMounted()) onCatalogLoadingChanged(true);
    await WorksRegistry.prefetchBrowseWindow(
      offset: browseOffset,
      limit: WorksRegistry.browsePrefetchWindowSize,
    );
    _emitCatalogWindowState(filters, browseOffset, onCatalogWindowState);
    if (!append && isMounted()) {
      onCatalogLoadingChanged(false);
    }
    if (isMounted()) onDataChanged();

    if (!append) {
      unawaited(
        WorksRegistry.prefetchBrowseWindow(
          offset: browseOffset,
          limit: WorksRegistry.browsePrefetchWindowSize,
          fetchRemote: true,
        ).then((_) {
          if (isMounted()) onDataChanged();
        }),
      );
    }
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

void _emitCatalogWindowState(
  HomeBrowseFilterController filters,
  int browseOffset,
  void Function(CatalogWindowState state)? onCatalogWindowState,
) {
  if (onCatalogWindowState == null) return;
  final limit = WorksRegistry.browsePrefetchWindowSize;
  final total = WorksRegistry.catalogIndexEntryCount(
    domain: filters.domain,
    category: filters.categories.length == 1 ? filters.categories.first : null,
  );
  onCatalogWindowState((
    browseOffset: (browseOffset + limit).clamp(0, total),
    totalEntries: total,
  ));
}
