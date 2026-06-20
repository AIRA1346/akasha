import '../core/archiving/record_link.dart';
import '../core/ports/record_link_port.dart';

/// R2-D — explicitId wiki label vs current Entity title drift.
class StaleLabelStats {
  const StaleLabelStats({
    required this.incomingRecordCount,
    required this.staleLinkCount,
    required this.staleRecordCount,
  });

  final int incomingRecordCount;
  final int staleLinkCount;
  final int staleRecordCount;
}

abstract final class RecordLinkStaleLabel {
  /// `[[entityId|Label]]` where [Label] ≠ [currentTitle] (trimmed, exact).
  ///
  /// `[[entityId]]` (no pipe label) and titleOnly links are not stale.
  static bool isStaleExplicitLabel({
    required RecordLink link,
    required String entityId,
    required String currentTitle,
  }) {
    if (link.kind != RecordLinkKind.explicitId) return false;
    if (link.targetEntityId != entityId) return false;

    final label = link.displayLabel?.trim();
    if (label == null || label.isEmpty) return false;

    return label != currentTitle.trim();
  }

  /// Uses [incomingRecordPaths] + per-path [outgoingLinks] from link index only.
  /// Does not read or modify vault `.md` files.
  static Future<StaleLabelStats> countForEntity({
    required RecordLinkPort linkIndex,
    required String entityId,
    required String currentTitle,
  }) async {
    final rawPaths = await linkIndex.incomingRecordPaths(entityId);
    final paths = rawPaths.toSet().toList()..sort();
    var staleLinkCount = 0;
    final staleRecordPaths = <String>{};

    for (final path in paths) {
      final outgoing = await linkIndex.outgoingLinks(path);
      for (final link in outgoing) {
        if (!isStaleExplicitLabel(
          link: link,
          entityId: entityId,
          currentTitle: currentTitle,
        )) {
          continue;
        }
        staleLinkCount++;
        staleRecordPaths.add(path);
      }
    }

    return StaleLabelStats(
      incomingRecordCount: paths.length,
      staleLinkCount: staleLinkCount,
      staleRecordCount: staleRecordPaths.length,
    );
  }
}
