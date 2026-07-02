import 'package:flutter/material.dart';

import '../../../../../core/archiving/entity_anchor.dart';
import '../../../../../core/ports/user_catalog_port.dart';
import '../../../../../models/akasha_item.dart';
import '../../../../../models/enums.dart';
import '../../../../../models/sanctum_cast_entry.dart';
import '../../../../../theme/akasha_colors.dart';
import '../../../../../theme/akasha_palette.dart';
import '../../../../../theme/akasha_radius.dart';
import '../../../../../theme/akasha_spacing.dart';
import '../../../../../theme/akasha_typography.dart';
import '../../../../../widgets/poster_image.dart';
import '../../../../../utils/app_l10n.dart';

/// Sanctum 기록 탭 — `# 👥 출연` 편집 UI.
class SanctumCastSectionEditor extends StatelessWidget {
  const SanctumCastSectionEditor({
    super.key,
    required this.entries,
    this.userCatalog,
    required this.onRoleChanged,
    required this.onRemove,
  });

  final List<SanctumCastEntry> entries;
  final UserCatalogPort? userCatalog;
  final void Function(int index, String role) onRoleChanged;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.workbenchTile,
        borderRadius: AkashaRadius.mdBorder,
        border: Border.all(color: palette.borderSubtle(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AkashaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: palette.accent),
                const SizedBox(width: AkashaSpacing.sm),
                Text(
                  l10n != null
                      ? l10n.workbenchCastSectionTitle
                            .replaceAll('👥', '')
                            .trim()
                      : '출연',
                  style: AkashaTypography.sectionTitle,
                ),
              ],
            ),
            const SizedBox(height: AkashaSpacing.sm),
            if (entries.isEmpty)
              Text(
                l10n?.helpWorkbenchCastEditorEmpty ??
                    '우측 「인물 추가」로 출연진을 넣으면 미리보기 상단에 카드로 표시됩니다.',
                style: AkashaTypography.bodySecondary,
              )
            else
              ...List.generate(entries.length, (index) {
                final entry = entries[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == entries.length - 1 ? 0 : AkashaSpacing.sm,
                  ),
                  child: _CastEntryRow(
                    entry: entry,
                    userCatalog: userCatalog,
                    onRoleChanged: (role) => onRoleChanged(index, role),
                    onRemove: () => onRemove(index),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CastEntryRow extends StatefulWidget {
  const _CastEntryRow({
    required this.entry,
    this.userCatalog,
    required this.onRoleChanged,
    required this.onRemove,
  });

  final SanctumCastEntry entry;
  final UserCatalogPort? userCatalog;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onRemove;

  @override
  State<_CastEntryRow> createState() => _CastEntryRowState();
}

class _CastEntryRowState extends State<_CastEntryRow> {
  late final TextEditingController _roleCtrl;

  @override
  void initState() {
    super.initState();
    _roleCtrl = TextEditingController(text: widget.entry.role ?? '');
  }

  @override
  void didUpdateWidget(covariant _CastEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.role != widget.entry.role &&
        _roleCtrl.text != (widget.entry.role ?? '')) {
      _roleCtrl.text = widget.entry.role ?? '';
    }
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final catalogEntity = widget.userCatalog?.getById(widget.entry.entityId);
    final avatarItem = catalogEntity != null
        ? EntityItem(
            entityType: catalogEntity.anchorType,
            entityId: catalogEntity.entityId,
            title: catalogEntity.title,
            category: catalogEntity.subtype,
            domain: catalogEntity.domain,
            creator: catalogEntity.creator,
            releaseYear: catalogEntity.releaseYear,
            posterPath: catalogEntity.posterPath,
            tags: catalogEntity.tags,
            addedAt: catalogEntity.addedAt,
          )
        : EntityItem(
            entityType: EntityAnchorType.person,
            entityId: widget.entry.entityId,
            title: widget.entry.title,
            category: MediaCategory.book,
            domain: AppDomain.subculture,
            addedAt: DateTime.now(),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.workbenchEditor,
        borderRadius: AkashaRadius.smBorder,
        border: Border.all(color: palette.borderSubtle(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 36,
                height: 36,
                child: PosterImage(item: avatarItem, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.title,
                    style: AkashaTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _roleCtrl,
                    onChanged: widget.onRoleChanged,
                    style: AkashaTypography.caption,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n?.hintCastRole ?? '역할 (예: 주인공)',
                      hintStyle: AkashaTypography.bodySecondary,
                      border: OutlineInputBorder(
                        borderRadius: AkashaRadius.smBorder,
                        borderSide: BorderSide(
                          color: palette.borderSubtle(0.18),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(
                Icons.close,
                size: 16,
                color: AkashaColors.textMuted,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}
