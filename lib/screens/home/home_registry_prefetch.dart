import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/ports/registry_port.dart';
import '../../models/enums.dart';
import 'home_browse_filter_controller.dart';

/// 윈도우 prefetch 후 UI에 전달할 카탈로그 진행 상태
typedef CatalogWindowState = ({int browseOffset, int totalEntries});

/// 필터·대시보드 범위에 맞는 lazy 샤드 프리페치
Future<void> prefetchRegistryForFilters({
  required RegistryPort registry,
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
      await registry.prefetchForFilters(
        domain: filters.domain,
        categories: filters.categories.isEmpty
            ? null
            : Set<MediaCategory>.from(filters.categories),
      );
      _emitCatalogWindowState(
        registry,
        filters,
        browseOffset,
        onCatalogWindowState,
      );
      if (isMounted()) onDataChanged();
      return;
    }

    if (!append && isMounted()) onCatalogLoadingChanged(true);
    await registry.prefetchBrowseWindow(
      offset: browseOffset,
      limit: registry.browsePrefetchWindowSize,
    );
    _emitCatalogWindowState(
      registry,
      filters,
      browseOffset,
      onCatalogWindowState,
      fullCatalogAtOffsetZero: !append && browseOffset == 0,
    );
    if (!append && isMounted()) {
      onCatalogLoadingChanged(false);
    }
    if (isMounted()) onDataChanged();

    final remotePrefetch = registry
        .prefetchBrowseWindow(
          offset: browseOffset,
          limit: registry.browsePrefetchWindowSize,
          fetchRemote: true,
        )
        .then((_) {
      if (isMounted()) onDataChanged();
    });
    if (append) {
      await remotePrefetch;
    } else {
      unawaited(remotePrefetch);
    }
    return;
  }

  if (filters.domain == null && filters.categories.isEmpty) {
    if (isMounted()) onDataChanged();
    return;
  }

  await registry.prefetchForFilters(
    domain: filters.domain,
    categories: filters.categories.isEmpty
        ? null
        : Set<MediaCategory>.from(filters.categories),
  );

  if (isMounted()) onDataChanged();
}

void _emitCatalogWindowState(
  RegistryPort registry,
  HomeBrowseFilterController filters,
  int browseOffset,
  void Function(CatalogWindowState state)? onCatalogWindowState, {
  bool fullCatalogAtOffsetZero = false,
}) {
  if (onCatalogWindowState == null) return;
  final limit = registry.browsePrefetchWindowSize;
  final total = registry.catalogIndexEntryCount(
    domain: filters.domain,
    category: filters.categories.length == 1 ? filters.categories.first : null,
  );
  final hasActiveIndexFilters =
      filters.domain != null || filters.categories.isNotEmpty;
  final useFullCatalog = fullCatalogAtOffsetZero &&
      filters.domain == null &&
      filters.categories.isEmpty &&
      total > 0 &&
      total <= registry.browseFullCatalogThreshold;
  onCatalogWindowState((
    browseOffset: useFullCatalog || hasActiveIndexFilters
        ? total
        : (browseOffset + limit).clamp(0, total),
    totalEntries: total,
  ));
}
