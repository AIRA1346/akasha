import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../services/record_link_stale_label.dart';
import '../../../services/same_day_record_service.dart';
import 'workbench_vault.dart';

class WorkbenchIncomingLinksSnapshot {
  const WorkbenchIncomingLinksSnapshot({
    required this.paths,
    required this.staleLabelRecordCount,
  });

  final List<String> paths;
  final int staleLabelRecordCount;
}

/// Incoming·sameDay 링크 데이터 로드 (Work·Entity 워크벤치 공통).
abstract final class WorkbenchRecordLinksLoader {
  static Future<WorkbenchIncomingLinksSnapshot> loadIncoming({
    required RecordLinkPort linkIndex,
    required String recordEntityId,
    required String currentTitle,
  }) async {
    final paths = await linkIndex.incomingRecordPaths(recordEntityId);
    final uniquePaths = paths.toSet().toList()..sort();
    final stale = await RecordLinkStaleLabel.countForEntity(
      linkIndex: linkIndex,
      entityId: recordEntityId,
      currentTitle: currentTitle,
    );
    return WorkbenchIncomingLinksSnapshot(
      paths: uniquePaths,
      staleLabelRecordCount: stale.staleRecordCount,
    );
  }

  static Future<List<SameDayRecordRef>> loadSameDay({
    required DateTime anchor,
    String? excludePath,
  }) =>
      SameDayRecordService.findForAnchor(
        vaultPath: WorkbenchVault.port.vaultPath,
        anchor: anchor,
        excludePath: excludePath,
      );
}
