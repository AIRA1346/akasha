import 'package:flutter/foundation.dart';

import '../../models/akasha_item.dart';
import '../../models/enums.dart';
import '../../services/file_service.dart';
import '../../services/registry_visibility_service.dart';
import '../../services/user_preferences.dart';
import '../../services/works_registry.dart' show RegistryWork, WorksRegistry;
import '../../utils/helpers.dart';

/// 사전 작품 자동 .md 아카이빙
class HomeAutoArchive {
  /// 생성된 .md 수. 0이면 신규 없음.
  static Future<int> run({
    required Future<void> Function() prefetchFilters,
    bool showFeedback = false,
    void Function(String message)? showMessage,
  }) async {
    if (!await UserPreferences.isAutoArchiveRegistryEnabled()) return 0;

    final service = AkashaFileService();
    if (service.vaultPath == null) return 0;

    await prefetchFilters();

    final onDisk = await service.loadAllItems();
    final localWorkIds = onDisk
        .map((e) => e.workId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final localKeys = onDisk.map((e) => AkashaFileService.cacheKeyFor(e)).toSet();

    final allRegistryWorks = WorksRegistry.getFilteredWorksSync();
    final pending = allRegistryWorks.where((work) {
      if (localWorkIds.contains(work.workId)) return false;
      final key = work.workId.isNotEmpty
          ? work.workId
          : '${work.category.name}::${work.title}';
      if (localKeys.contains(key)) return false;
      return RegistryVisibilityService.shouldAutoArchiveRegistryWork(
        workId: work.workId,
        userWorkIds: localWorkIds,
      );
    }).toList();

    if (pending.isEmpty) {
      if (showFeedback) {
        showMessage?.call('새로 아카이빙할 사전 작품이 없습니다.');
      }
      return 0;
    }

    var createdCount = 0;
    for (final work in pending) {
      final newItem = itemFromRegistryWork(work);
      await service.saveItem(newItem);
      createdCount++;
    }

    if (createdCount > 0) {
      debugPrint('Auto-archived $createdCount new works from registry.');
      if (showFeedback) {
        showMessage?.call('사전 작품 $createdCount편을 .md로 아카이빙했습니다.');
      }
    }

    return createdCount;
  }

  static AkashaItem itemFromRegistryWork(RegistryWork work) {
    final defaultMyStatus = work.category.isContentType
        ? ContentMyStatus.notStarted.label
        : GameMyStatus.backlog.label;
    final defaultWorkStatus = work.category.isContentType
        ? ContentWorkStatus.completed.label
        : GameWorkStatus.released.label;

    return createItem(
      workId: work.workId,
      title: work.displayTitle(),
      category: work.category,
      domain: work.domain,
      myStatus: defaultMyStatus,
      workStatus: defaultWorkStatus,
      creator: work.creator,
      releaseYear: work.releaseYear,
      rating: 0.0,
      description: work.description,
      tags: work.tags,
    );
  }
}
