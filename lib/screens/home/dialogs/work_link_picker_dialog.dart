import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../theme/akasha_colors.dart';

/// 서재 작품 검색 — 워크벤치 「작품 추가」용.
Future<EntityLinkSelection?> showWorkLinkPickerDialog(
  BuildContext context, {
  required List<AkashaItem> vaultItems,
  required String excludeWorkId,
  String? initialQuery,
}) {
  return showDialog<EntityLinkSelection>(
    context: context,
    builder: (ctx) => WorkLinkPickerDialog(
      vaultItems: vaultItems,
      excludeWorkId: excludeWorkId,
      initialQuery: initialQuery,
    ),
  );
}

class WorkLinkPickerDialog extends StatefulWidget {
  const WorkLinkPickerDialog({
    super.key,
    required this.vaultItems,
    required this.excludeWorkId,
    this.initialQuery,
  });

  final List<AkashaItem> vaultItems;
  final String excludeWorkId;
  final String? initialQuery;

  @override
  State<WorkLinkPickerDialog> createState() => _WorkLinkPickerDialogState();
}

class _WorkLinkPickerDialogState extends State<WorkLinkPickerDialog> {
  late final TextEditingController _queryCtrl;
  List<AkashaItem> _matches = const [];

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialQuery ?? '');
    _queryCtrl.addListener(_rebuildMatches);
    _rebuildMatches();
  }

  @override
  void dispose() {
    _queryCtrl.removeListener(_rebuildMatches);
    _queryCtrl.dispose();
    super.dispose();
  }

  void _rebuildMatches() {
    final q = _queryCtrl.text.trim().toLowerCase();
    final pool = widget.vaultItems
        .where((w) => w.workId != widget.excludeWorkId)
        .toList();

    if (q.isEmpty) {
      setState(() {
        _matches = pool.take(40).toList();
      });
      return;
    }

    final scored = <({AkashaItem item, int score})>[];
    for (final item in pool) {
      final title = item.title.toLowerCase();
      final creator = item.creator.toLowerCase();
      final id = item.workId.toLowerCase();
      var score = 0;
      if (title == q) {
        score += 100;
      } else if (title.startsWith(q)) {
        score += 60;
      } else if (title.contains(q)) {
        score += 40;
      }
      if (creator.contains(q)) score += 20;
      if (id.contains(q)) score += 10;
      if (score > 0) scored.add((item: item, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    setState(() {
      _matches = scored.map((e) => e.item).take(40).toList();
    });
  }

  void _select(AkashaItem work) {
    Navigator.pop(
      context,
      EntityLinkSelection(
        entityId: work.workId,
        title: work.title,
        entityType: UserCatalogEntity.entityTypeWork,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryCtrl.text.trim();

    return AlertDialog(
      title: const Text('작품 추가'),
      content: SizedBox(
        width: 420,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '제목 · 작가 · work_id 검색',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '서재에 저장된 작품을 본문에 [[링크]]로 연결합니다.',
              style: TextStyle(fontSize: 11, color: AkashaColors.textMuted),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _matches.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty
                            ? '연결할 다른 작품이 없습니다.'
                            : '「$query」과(와) 일치하는 작품이 없습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AkashaColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _matches.length,
                      itemBuilder: (context, index) {
                        final work = _matches[index];
                        return _WorkTile(work: work, onTap: () => _select(work));
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

class _WorkTile extends StatelessWidget {
  const _WorkTile({required this.work, required this.onTap});

  final AkashaItem work;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      work.category.label,
      if (work.creator.isNotEmpty) work.creator,
      if (work.releaseYear != null) '${work.releaseYear}',
    ].join(' · ');

    return ListTile(
      dense: true,
      onTap: onTap,
      leading: const Icon(
        Icons.menu_book_outlined,
        size: 20,
        color: AkashaColors.accent,
      ),
      title: Text(
        work.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 10, color: AkashaColors.textMuted),
      ),
      trailing: const Icon(Icons.link, size: 14, color: Colors.tealAccent),
    );
  }
}
