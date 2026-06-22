import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/record_kind.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../../../utils/entity_link_neighbors.dart';
import '../../../widgets/editable_tag_chips.dart';
import '../../../widgets/entity_link_neighbors_sections.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import 'work_detail_info_poster.dart';

/// Entity collectible — Workbench 좌측 정보 패널 (Phase 6).
class EntityDetailInfoPanel extends StatelessWidget {
  const EntityDetailInfoPanel({
    super.key,
    required this.item,
    required this.preview,
    required this.aliases,
    required this.hasJournal,
    required this.panelWidth,
    required this.infoPanelLocked,
    required this.draftTags,
    required this.isSaving,
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
    required this.onDraftTagsChanged,
    required this.onSave,
    required this.onPosterTap,
    required this.posterUrlCtrl,
    required this.showAddToLibrary,
    required this.onAddToLibrary,
    this.canDeleteMd = false,
    this.onDeleteArchive,
    this.onClose,
    this.onGoKnowledgeGraph,
    this.linkNeighbors = const EntityLinkNeighbors(),
    this.loadingLinkNeighbors = false,
    this.onOpenLinkedEntity,
    this.onOpenLinkedWork,
    this.onFocusSanctumForLinks,
  });

  final AkashaItem item;
  final AkashaItem preview;
  final List<String> aliases;
  final bool hasJournal;
  final double panelWidth;
  final bool infoPanelLocked;
  final List<String> draftTags;
  final bool isSaving;
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
  final ValueChanged<List<String>> onDraftTagsChanged;
  final VoidCallback onSave;
  final VoidCallback onPosterTap;
  final TextEditingController posterUrlCtrl;
  final bool showAddToLibrary;
  final VoidCallback onAddToLibrary;
  final bool canDeleteMd;
  final VoidCallback? onDeleteArchive;
  final VoidCallback? onClose;
  final VoidCallback? onGoKnowledgeGraph;
  final EntityLinkNeighbors linkNeighbors;
  final bool loadingLinkNeighbors;
  final void Function(UserCatalogEntity entity)? onOpenLinkedEntity;
  final void Function(AkashaItem work)? onOpenLinkedWork;
  final VoidCallback? onFocusSanctumForLinks;

  @override
  Widget build(BuildContext context) {
    final entityItem = item as EntityItem;
    final badge = entityTypeBadgeLabel(entityItem.entityType);

    return WorkbenchResizablePanel(
      width: panelWidth,
      minWidth: 220,
      maxWidth: 400,
      locked: infoPanelLocked,
      onWidthChanged: onInfoWidthChanged,
      onToggleLock: onToggleInfoLock,
      child: ColoredBox(
        color: const Color(0xFF1A1A26),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: WorkDetailInfoPoster(
                  preview: preview,
                  posterUrlCtrl: posterUrlCtrl,
                  gradColors: categoryGradient(item.category),
                  maxWidth: panelWidth,
                  maxHeight: 180,
                  onPosterTap: onPosterTap,
                  onClose: onClose,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.workId,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (aliases.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '별칭: ${aliases.join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    hasJournal ? Icons.inventory_2_outlined : Icons.cloud_outlined,
                    size: 14,
                    color: hasJournal ? Colors.greenAccent : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasJournal ? '아카이브됨' : 'catalog only',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasJournal ? Colors.greenAccent : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // —— 연결 (탐험 허브) ——
              EntityLinkNeighborsSections(
                neighbors: linkNeighbors,
                entityTags: draftTags,
                loading: loadingLinkNeighbors,
                onOpenEntity: onOpenLinkedEntity,
                onOpenWork: onOpenLinkedWork,
                onRecordCta: onFocusSanctumForLinks,
                sectionTitleStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                ),
              ),
              if (onGoKnowledgeGraph != null) ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: 30,
                  child: OutlinedButton.icon(
                    onPressed: onGoKnowledgeGraph,
                    icon: const Icon(Icons.hub_outlined, size: 14, color: Color(0xFF6C63FF)),
                    label: const Text(
                      '연결 맵에서 보기',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 24),
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
              const Divider(height: 24),
              Text(
                '태그',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              EditableTagChips(
                tags: draftTags,
                onChanged: onDraftTagsChanged,
                compact: false,
              ),
              const SizedBox(height: 20),
              if (showAddToLibrary) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAddToLibrary,
                    icon: const Icon(Icons.collections_bookmark_outlined, size: 16),
                    label: Text(hasJournal ? '서재에 담기' : '저장하고 서재에 담기'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(hasJournal ? 'md 저장' : 'journal 생성'),
              ),
              if (canDeleteMd && onDeleteArchive != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onDeleteArchive,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('md 삭제'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(EntityAnchorType type) => switch (type) {
        EntityAnchorType.person => Icons.person_outline,
        EntityAnchorType.concept => Icons.lightbulb_outline,
        EntityAnchorType.event => Icons.event_outlined,
        EntityAnchorType.place => Icons.place_outlined,
        EntityAnchorType.organization => Icons.groups_outlined,
        _ => Icons.category_outlined,
      };
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
                key: const Key('entity_incoming_refresh'),
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
