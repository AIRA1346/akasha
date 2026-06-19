import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../models/catalog_entity_add_result.dart';
import '../../../models/entity_id_codec.dart';
import '../../../models/user_catalog_entity.dart';

/// Wave 4 — Person · Concept · Event 등 catalog-only Fact 추가.
Future<CatalogEntityAddResult?> showAddCatalogEntityDialog(
  BuildContext context, {
  required EntityAnchorType entityType,
  String? initialTitle,
}) async {
  final titleCtrl = TextEditingController(text: initialTitle ?? '');
  final aliasesCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  var createJournal = false;

  final typeLabel = _typeLabel(entityType);

  final result = await showDialog<CatalogEntityAddResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text('$typeLabel 추가 (catalog)'),
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
                    labelText: '$typeLabel 이름',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aliasesCtrl,
                  decoration: const InputDecoration(
                    labelText: '별칭 (쉼표로 구분, 선택)',
                    hintText: '호랑이, 백호',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('entities journal 생성'),
                  subtitle: const Text('vault/entities/{type}/ 에 .md 저장'),
                  value: createJournal,
                  onChanged: (v) => setLocal(() => createJournal = v ?? false),
                ),
                if (createJournal) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: bodyCtrl,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: '메모 (선택)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('이름을 입력해 주세요.')),
                );
                return;
              }
              final aliases = aliasesCtrl.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              Navigator.pop(
                ctx,
                CatalogEntityAddResult(
                  entity: UserCatalogEntity.userLocal(
                    entityId: EntityIdCodec.buildUserLocal(entityType),
                    type: entityType,
                    title: title,
                    aliases: aliases,
                  ),
                  createJournal: createJournal,
                  journalBody: bodyCtrl.text.trim(),
                ),
              );
            },
            child: const Text('catalog에 추가'),
          ),
        ],
      ),
    ),
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
    builder: (ctx) => AlertDialog(
      title: const Text('추가할 대상 유형'),
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
              label: 'Work (작품)',
              subtitle: '볼트에 .md 아카이브',
              onTap: () => Navigator.pop(ctx, EntityAnchorType.work),
            ),
            _TypeTile(
              icon: Icons.person_outline,
              label: 'Person',
              subtitle: '개별 존재 — 나비, 캐릭터',
              onTap: () => Navigator.pop(ctx, EntityAnchorType.person),
            ),
            _TypeTile(
              icon: Icons.lightbulb_outline,
              label: 'Concept',
              subtitle: '종·상징·개념 — Tiger',
              onTap: () => Navigator.pop(ctx, EntityAnchorType.concept),
            ),
            _TypeTile(
              icon: Icons.event_outlined,
              label: 'Event',
              subtitle: '사건·행사',
              onTap: () => Navigator.pop(ctx, EntityAnchorType.event),
            ),
            _TypeTile(
              icon: Icons.place_outlined,
              label: 'Place',
              subtitle: '장소 — 카페·도시',
              onTap: () => Navigator.pop(ctx, EntityAnchorType.place),
            ),
            _TypeTile(
              icon: Icons.groups_outlined,
              label: 'Organization',
              subtitle: '조직·팀·브랜드',
              onTap: () => Navigator.pop(ctx, EntityAnchorType.organization),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
      ],
    ),
  );
}

String _typeLabel(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.person => 'Person',
    EntityAnchorType.concept => 'Concept',
    EntityAnchorType.event => 'Event',
    EntityAnchorType.place => 'Place',
    EntityAnchorType.organization => 'Organization',
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
    EntityAnchorType.custom => 'Custom',
    EntityAnchorType.phenomenon => 'Legacy',
  };
}
