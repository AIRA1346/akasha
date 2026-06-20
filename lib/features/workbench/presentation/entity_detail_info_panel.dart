import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../../../widgets/editable_tag_chips.dart';
import '../../../widgets/workbench_resizable_panel.dart';

/// Entity collectible — Workbench 좌측 정보 패널 (Phase 6).
class EntityDetailInfoPanel extends StatelessWidget {
  const EntityDetailInfoPanel({
    super.key,
    required this.entity,
    required this.hasJournal,
    required this.panelWidth,
    required this.infoPanelLocked,
    required this.draftTags,
    required this.isSaving,
    required this.onInfoWidthChanged,
    required this.onToggleInfoLock,
    required this.onDraftTagsChanged,
    required this.onSave,
    this.canDeleteMd = false,
    this.onDeleteArchive,
  });

  final UserCatalogEntity entity;
  final bool hasJournal;
  final double panelWidth;
  final bool infoPanelLocked;
  final List<String> draftTags;
  final bool isSaving;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final ValueChanged<List<String>> onDraftTagsChanged;
  final VoidCallback onSave;
  final bool canDeleteMd;
  final VoidCallback? onDeleteArchive;

  @override
  Widget build(BuildContext context) {
    final badge = entityTypeBadgeLabel(entity.anchorType);

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
              Text(
                'Entity 정보',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.withValues(alpha: 0.25),
                      const Color(0xFF252535),
                    ],
                  ),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.35)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _iconFor(entity.anchorType),
                      size: 36,
                      color: Colors.tealAccent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                entity.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entity.entityId,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (entity.aliases.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '별칭: ${entity.aliases.join(', ')}',
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
