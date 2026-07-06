import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/catalog_entity_add_result.dart';
import '../../../models/entity_id_codec.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_archive_service.dart';
import '../../../utils/app_l10n.dart';
import '../../../utils/entity_tag_validation.dart';
import '../../../widgets/editable_tag_chips.dart';
import '../../../theme/akasha_colors.dart';

/// R1 — Person · Event · Concept Archive-First 추가 (Work parity).
Future<CatalogEntityAddResult?> showAddCatalogEntityDialog(
  BuildContext context, {
  required EntityAnchorType entityType,
  String? initialTitle,
  Set<String> workTitleIndex = const {},
}) async {
  final titleCtrl = TextEditingController(text: initialTitle ?? '');
  final aliasesCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final archiveFirst = EntityArchiveService.usesArchiveFirstFlow(entityType);
  var nameOnly = false;
  var tags = <String>[];

  final typeLabel = _typeLabel(entityType);

  final result = await showDialog<CatalogEntityAddResult>(
    context: context,
    builder: (ctx) {
      final l10n = lookupAppL10n(ctx);
      final resolvedTypeLabel = l10n != null ? _localizedEntityType(entityType, l10n) : typeLabel;

      return StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n?.archiveTitle(resolvedTypeLabel) ?? '$resolvedTypeLabel 아카이브'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n?.archiveNameLabel(resolvedTypeLabel) ?? '$resolvedTypeLabel 이름',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aliasesCtrl,
                    decoration: InputDecoration(
                      labelText: l10n?.archiveAliasesLabel ?? '별칭 (쉼표로 구분, 선택)',
                      hintText: l10n?.archiveAliasesHint ?? '호랑이, 백호',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.archiveTagsLabel ?? '태그 (감상 축 · semantic)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AkashaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  EditableTagChips(
                    tags: tags,
                    onChanged: (next) => setLocal(() => tags = next),
                  ),
                  if (archiveFirst && !nameOnly) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyCtrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: l10n?.archiveMemoLabel ?? '메모 (선택)',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                  if (archiveFirst) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n?.archiveNameOnly ?? '이름만 등록 (고급)'),
                      subtitle: Text(
                        l10n?.archiveNameOnlyHelp ?? 'journal 없이 링크용 ID만 — 기본 아카이브 flow 아님',
                      ),
                      value: nameOnly,
                      onChanged: (v) => setLocal(() => nameOnly = v ?? false),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n?.actionCancel ?? '취소'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n?.validationInputName ?? '이름을 입력해 주세요.')),
                  );
                  return;
                }
                final aliases = aliasesCtrl.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                EntityTagValidation.showWorkTitleWarningIfNeeded(
                  ctx,
                  tags: tags,
                  workTitles: workTitleIndex,
                );
                Navigator.pop(
                  ctx,
                  CatalogEntityAddResult(
                    entity: UserCatalogEntity.userLocal(
                      entityId: EntityIdCodec.buildUserLocal(entityType),
                      type: entityType,
                      title: title,
                      aliases: aliases,
                      tags: tags,
                    ),
                    nameOnly: archiveFirst && nameOnly,
                    journalBody: bodyCtrl.text.trim(),
                  ),
                );
              },
              child: Text(
                archiveFirst
                    ? (l10n?.archiveAdd ?? '아카이브에 추가')
                    : (l10n?.actionAdd ?? '추가'),
              ),
            ),
          ],
        ),
      );
    },
  );

  titleCtrl.dispose();
  aliasesCtrl.dispose();
  bodyCtrl.dispose();
  return result;
}

Future<EntityAnchorType?> showCustomEntityTypePicker(
  BuildContext context, {
  String? initialTitle,
}) async {
  return showDialog<EntityAnchorType>(
    context: context,
    builder: (ctx) {
      final l10n = lookupAppL10n(ctx);
      return AlertDialog(
        title: Text(l10n?.archiveChooseType ?? '추가할 대상 유형'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (initialTitle != null && initialTitle.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '「${initialTitle.trim()}」',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              _TypeTile(
                icon: Icons.movie_outlined,
                label: l10n != null ? '${l10n.entityTypeWork} (Work)' : 'Work (작품)',
                subtitle: l10n?.archiveDescWork ?? '볼트에 .md 아카이브',
                onTap: () => Navigator.pop(ctx, EntityAnchorType.work),
              ),
              _TypeTile(
                icon: Icons.person_outline,
                label: l10n?.entityTypePerson ?? 'Person',
                subtitle: l10n?.archiveDescEntity('person') ?? 'entities/person/*.md 아카이브',
                onTap: () => Navigator.pop(ctx, EntityAnchorType.person),
              ),
              _TypeTile(
                icon: Icons.lightbulb_outline,
                label: l10n?.entityTypeConcept ?? 'Concept',
                subtitle: l10n?.archiveDescEntity('concept') ?? 'entities/concept/*.md 아카이브',
                onTap: () => Navigator.pop(ctx, EntityAnchorType.concept),
              ),
              _TypeTile(
                icon: Icons.event_outlined,
                label: l10n?.entityTypeEvent ?? 'Event',
                subtitle: l10n?.archiveDescEntity('event') ?? 'entities/event/*.md 아카이브',
                onTap: () => Navigator.pop(ctx, EntityAnchorType.event),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.actionCancel ?? '취소'),
          ),
        ],
      );
    },
  );
}

String _localizedEntityType(EntityAnchorType type, AppLocalizations l10n) {
  return switch (type) {
    EntityAnchorType.work => l10n.entityTypeWork,
    EntityAnchorType.person => l10n.entityTypePerson,
    EntityAnchorType.concept => l10n.entityTypeConcept,
    EntityAnchorType.event => l10n.entityTypeEvent,
    EntityAnchorType.place => l10n.entityTypePlace,
    EntityAnchorType.organization => l10n.entityTypeOrganization,
    EntityAnchorType.object => l10n.entityTypeObject,
    // ignore: deprecated_member_use_from_same_package
    EntityAnchorType.custom => l10n.entityTypeCustom,
    EntityAnchorType.phenomenon => l10n.entityTypePhenomenon,
  };
}

String _typeLabel(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.person => 'Person',
    EntityAnchorType.concept => 'Concept',
    EntityAnchorType.event => 'Event',
    EntityAnchorType.place => 'Place',
    EntityAnchorType.organization => 'Organization',
    EntityAnchorType.object => 'Object',
    // ignore: deprecated_member_use_from_same_package
    EntityAnchorType.custom => 'Custom',
    EntityAnchorType.work => 'Work',
    EntityAnchorType.phenomenon => 'Legacy',
  };
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      onTap: onTap,
    );
  }
}

String entityTypeBadgeLabel(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.work => 'Work',
    EntityAnchorType.person => 'Person',
    EntityAnchorType.concept => 'Concept',
    EntityAnchorType.event => 'Event',
    EntityAnchorType.place => 'Place',
    EntityAnchorType.organization => 'Org',
    EntityAnchorType.object => 'Object',
    // ignore: deprecated_member_use_from_same_package
    EntityAnchorType.custom => 'Custom',
    EntityAnchorType.phenomenon => 'Legacy',
  };
}

String entityTypeArchiveSectionLabel(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.person => 'Person',
    EntityAnchorType.concept => 'Concept',
    EntityAnchorType.event => 'Event',
    _ => entityTypeBadgeLabel(type),
  };
}
