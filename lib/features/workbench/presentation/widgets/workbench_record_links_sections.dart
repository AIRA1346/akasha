import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../core/archiving/record_kind.dart';
import '../../../../core/archiving/same_day_record_ref.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_radius.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';

/// Workbench 공통 — Incoming Record · 같은 날 기록 (R14-A).
class WorkbenchIncomingLinksSection extends StatelessWidget {
  const WorkbenchIncomingLinksSection({
    super.key,
    required this.loading,
    required this.paths,
    required this.staleLabelRecordCount,
    this.refreshKey,
    this.onRefresh,
    this.onOpen,
  });

  final bool loading;
  final List<String> paths;
  final int staleLabelRecordCount;
  final Key? refreshKey;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AkashaSpacing.xs),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '연결된 Record ${paths.length}개',
                    style: AkashaTypography.bodyEmphasis,
                  ),
                  if (staleLabelRecordCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '제목 갱신 필요 $staleLabelRecordCount개',
                      style: AkashaTypography.bodySecondary.copyWith(
                        color: AkashaColors.statusDirty,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRefresh != null)
              IconButton(
                key: refreshKey,
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Incoming Links 새로고침',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onRefresh,
              ),
          ],
        ),
        if (paths.isNotEmpty) ...[
          const SizedBox(height: AkashaSpacing.sm),
          ...paths.map((path) {
            final label = p.basename(path);
            return Padding(
              padding: const EdgeInsets.only(bottom: AkashaSpacing.sm),
              child: Material(
                color: AkashaColors.workbenchListTile,
                borderRadius: AkashaRadius.smBorder,
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.link, size: 16),
                  title: Text(label, style: AkashaTypography.body),
                  subtitle: Text(
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AkashaTypography.caption,
                  ),
                  onTap: onOpen != null ? () => onOpen!(path) : null,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class WorkbenchSameDayRecordsSection extends StatelessWidget {
  const WorkbenchSameDayRecordsSection({
    super.key,
    required this.loading,
    required this.refs,
    required this.anchor,
    required this.onOpen,
  });

  final bool loading;
  final List<SameDayRecordRef> refs;
  final DateTime anchor;
  final ValueChanged<SameDayRecordRef> onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.only(top: AkashaSpacing.sm),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (refs.isEmpty) return const SizedBox.shrink();

    final local = anchor.toLocal();
    final dateLabel =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AkashaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '같은 날 기록 · $dateLabel (${refs.length})',
            style: AkashaTypography.bodyEmphasis,
          ),
          const SizedBox(height: AkashaSpacing.sm),
          ...refs.map((ref) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AkashaSpacing.sm),
              child: Material(
                color: AkashaColors.workbenchListTile,
                borderRadius: AkashaRadius.smBorder,
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    ref.kind == RecordKind.timelineEntry
                        ? Icons.timeline
                        : Icons.notes,
                    size: 16,
                  ),
                  title: Text(ref.title, style: AkashaTypography.body),
                  subtitle: Text(ref.kindLabel, style: AkashaTypography.caption),
                  onTap: () => onOpen(ref),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
