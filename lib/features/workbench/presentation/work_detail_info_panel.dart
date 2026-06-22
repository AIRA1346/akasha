import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/archiving/record_kind.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../models/enums.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import 'work_detail_info_form.dart';
import 'work_detail_info_poster.dart';

/// 워크벤치 좌측 작품정보 패널 (E2-6).
class WorkDetailInfoPanel extends StatelessWidget {
  const WorkDetailInfoPanel({
    super.key,
    required this.item,
    required this.preview,
    required this.panelWidth,
    required this.infoPanelLocked,
    required this.vaultLinked,
    required this.titleCtrl,
    required this.posterUrlCtrl,
    required this.draftRating,
    required this.draftWorkStatus,
    required this.draftMyStatus,
    required this.draftHallOfFame,
    required this.draftTags,
    required this.registryTags,
    required this.isSaving,
    required this.isArchived,
    required this.showAddToLibrary,
    required this.loadingIncoming,
    required this.incomingPaths,
    required this.staleLabelRecordCount,
    required this.onRefreshIncoming,
    required this.loadingSameDay,
    required this.sameDayRefs,
    required this.onOpenIncoming,
    required this.onOpenSameDay,
    required this.onInfoWidthChanged,
    required this.onToggleInfoLock,
    required this.onMarkDirty,
    required this.onDraftRatingChanged,
    required this.onDraftWorkStatusChanged,
    required this.onDraftMyStatusChanged,
    required this.onDraftHallOfFameChanged,
    required this.onDraftTagsChanged,
    required this.onPosterTap,
    required this.onResetToDefaults,
    required this.onSaveArchive,
    required this.onAddToLibrary,
    this.canDeleteMd = false,
    this.onDeleteArchive,
    this.onClose,
    this.linkNeighbors = const WorkLinkNeighbors(),
    this.loadingLinkNeighbors = false,
    this.onOpenLinkedEntity,
    this.onOpenLinkedWork,
  });

  final AkashaItem item;
  final AkashaItem preview;
  final double panelWidth;
  final bool infoPanelLocked;
  final bool vaultLinked;
  final TextEditingController titleCtrl;
  final TextEditingController posterUrlCtrl;
  final double draftRating;
  final String draftWorkStatus;
  final String draftMyStatus;
  final bool draftHallOfFame;
  final List<String> draftTags;
  final Set<String> registryTags;
  final bool isSaving;
  final bool isArchived;
  final bool showAddToLibrary;
  final bool loadingIncoming;
  final List<String> incomingPaths;
  final int staleLabelRecordCount;
  final VoidCallback? onRefreshIncoming;
  final bool loadingSameDay;
  final List<SameDayRecordRef> sameDayRefs;
  final ValueChanged<String> onOpenIncoming;
  final ValueChanged<SameDayRecordRef> onOpenSameDay;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final VoidCallback onMarkDirty;
  final ValueChanged<double> onDraftRatingChanged;
  final ValueChanged<String> onDraftWorkStatusChanged;
  final ValueChanged<String> onDraftMyStatusChanged;
  final ValueChanged<bool> onDraftHallOfFameChanged;
  final ValueChanged<List<String>> onDraftTagsChanged;
  final VoidCallback onPosterTap;
  final VoidCallback onResetToDefaults;
  final VoidCallback onSaveArchive;
  final VoidCallback onAddToLibrary;
  final bool canDeleteMd;
  final VoidCallback? onDeleteArchive;
  final VoidCallback? onClose;
  final WorkLinkNeighbors linkNeighbors;
  final bool loadingLinkNeighbors;
  final void Function(UserCatalogEntity entity)? onOpenLinkedEntity;
  final void Function(AkashaItem work)? onOpenLinkedWork;

  @override
  Widget build(BuildContext context) {
    final gradColors = categoryGradient(item.category);
    final metaLine = [
      if (item.creator.isNotEmpty) item.creator,
      if (item.releaseYear != null) '${item.releaseYear}',
    ].join(' · ');

    return WorkbenchResizablePanel(
      width: panelWidth,
      minWidth: 220,
      maxWidth: 400,
      locked: infoPanelLocked,
      onWidthChanged: onInfoWidthChanged,
      onToggleLock: onToggleInfoLock,
      child: ColoredBox(
        color: const Color(0xFF1A1A28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!vaultLinked)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Row(
                  children: [
                    Icon(Icons.folder_off_outlined,
                        size: 14, color: Colors.amber[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '볼트 미연동 · 임시 저장만',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final posterMaxHeight = constraints.maxHeight * 0.55;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: WorkDetailInfoPoster(
                            preview: preview,
                            posterUrlCtrl: posterUrlCtrl,
                            gradColors: gradColors,
                            maxWidth: constraints.maxWidth,
                            maxHeight: posterMaxHeight,
                            onPosterTap: onPosterTap,
                            onClose: onClose,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              WorkDetailInfoForm(
                                item: item,
                                metaLine: metaLine,
                                titleCtrl: titleCtrl,
                                draftRating: draftRating,
                                draftWorkStatus: draftWorkStatus,
                                draftMyStatus: draftMyStatus,
                                draftHallOfFame: draftHallOfFame,
                                draftTags: draftTags,
                                registryTags: registryTags,
                                isSaving: isSaving,
                                isArchived: isArchived,
                                showAddToLibrary: showAddToLibrary,
                                onMarkDirty: onMarkDirty,
                                onDraftRatingChanged: onDraftRatingChanged,
                                onDraftWorkStatusChanged: onDraftWorkStatusChanged,
                                onDraftMyStatusChanged: onDraftMyStatusChanged,
                                onDraftHallOfFameChanged: onDraftHallOfFameChanged,
                                onDraftTagsChanged: onDraftTagsChanged,
                                onResetToDefaults: onResetToDefaults,
                                onSaveArchive: onSaveArchive,
                                onAddToLibrary: onAddToLibrary,
                                canDeleteMd: canDeleteMd,
                                onDeleteArchive: onDeleteArchive,
                                linkNeighbors: linkNeighbors,
                                loadingLinkNeighbors: loadingLinkNeighbors,
                                onOpenLinkedEntity: onOpenLinkedEntity,
                                onOpenLinkedWork: onOpenLinkedWork,
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 20),
                              _IncomingLinksSection(
                                loading: loadingIncoming,
                                paths: incomingPaths,
                                staleLabelRecordCount: staleLabelRecordCount,
                                onRefresh: onRefreshIncoming,
                                onOpen: onOpenIncoming,
                              ),
                              const SizedBox(height: 24),
                              _SameDaySection(
                                loading: loadingSameDay,
                                refs: sameDayRefs,
                                anchor: item.addedAt,
                                onOpen: onOpenSameDay,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SameDaySection extends StatelessWidget {
  const _SameDaySection({
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
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (refs.isEmpty) return const SizedBox.shrink();

    final local = anchor.toLocal();
    final dateLabel =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '같은 날 기록 · $dateLabel (${refs.length})',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.tealAccent,
            ),
          ),
          const SizedBox(height: 6),
          ...refs.map((ref) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: const Color(0xFF252535),
                borderRadius: BorderRadius.circular(6),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    ref.kind == RecordKind.timelineEntry
                        ? Icons.timeline
                        : Icons.notes,
                    size: 16,
                  ),
                  title: Text(ref.title, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(
                    ref.kindLabel,
                    style: const TextStyle(fontSize: 10),
                  ),
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

class _IncomingLinksSection extends StatelessWidget {
  const _IncomingLinksSection({
    required this.loading,
    required this.paths,
    required this.staleLabelRecordCount,
    this.onRefresh,
    this.onOpen,
  });

  final bool loading;
  final List<String> paths;
  final int staleLabelRecordCount;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.tealAccent,
                    ),
                  ),
                  if (staleLabelRecordCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '제목 갱신 필요 ${staleLabelRecordCount}개',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade200,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRefresh != null)
              IconButton(
                key: const Key('work_incoming_refresh'),
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
          const SizedBox(height: 6),
          ...paths.map((path) {
            final label = p.basename(path);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: const Color(0xFF252535),
                borderRadius: BorderRadius.circular(6),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.link, size: 16),
                  title: Text(label, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
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
