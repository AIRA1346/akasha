import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/entity_link_selection.dart';
import '../../../services/entity_link_picker_candidates.dart';
import '../../../services/entity_vault_loader.dart';
import 'add_catalog_entity_dialog.dart';

/// R2-B — Work Sanctum Entity link picker (선택만 · markdown 삽입은 Step 2).
Future<EntityLinkSelection?> showEntityLinkPickerDialog(
  BuildContext context, {
  required UserCatalogPort userCatalog,
  EntityVaultLoader? entityLoader,
  String? initialQuery,
  EntityAnchorType? anchorTypeFilter,
}) {
  return showDialog<EntityLinkSelection>(
    context: context,
    builder: (ctx) => EntityLinkPickerDialog(
      userCatalog: userCatalog,
      entityLoader: entityLoader,
      initialQuery: initialQuery,
      anchorTypeFilter: anchorTypeFilter,
    ),
  );
}

class EntityLinkPickerDialog extends StatefulWidget {
  const EntityLinkPickerDialog({
    super.key,
    required this.userCatalog,
    this.entityLoader,
    this.initialQuery,
    this.anchorTypeFilter,
  });

  final UserCatalogPort userCatalog;
  final EntityVaultLoader? entityLoader;
  final String? initialQuery;
  final EntityAnchorType? anchorTypeFilter;

  @override
  State<EntityLinkPickerDialog> createState() => _EntityLinkPickerDialogState();
}

class _EntityLinkPickerDialogState extends State<EntityLinkPickerDialog> {
  late final TextEditingController _queryCtrl;
  List<EntityLinkPickerCandidate> _candidates = const [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialQuery ?? '');
    _queryCtrl.addListener(_onQueryChanged);
    _reload();
  }

  @override
  void dispose() {
    _queryCtrl.removeListener(_onQueryChanged);
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() => _reload();

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await EntityLinkPickerCandidates.build(
      userCatalog: widget.userCatalog,
      query: _queryCtrl.text,
      loader: widget.entityLoader,
      anchorTypeFilter: widget.anchorTypeFilter,
    );
    if (!mounted) return;
    setState(() {
      _candidates = list;
      _loading = false;
    });
  }

  void _select(EntityLinkPickerCandidate candidate) {
    final entity = candidate.entity;
    Navigator.pop(
      context,
      EntityLinkSelection(
        entityId: entity.entityId,
        title: entity.title,
        entityType: entity.entityType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entity 연결'),
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
                hintText: '이름 · 별칭 검색',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '아카이브된 Person · Event · Concept',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _candidates.isEmpty
                      ? Center(
                          child: Text(
                            _queryCtrl.text.trim().isEmpty
                                ? '연결할 Entity가 없습니다.'
                                : '「${_queryCtrl.text.trim()}」과(와) 일치하는 Entity가 없습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _candidates.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _candidates[index];
                            return _CandidateTile(
                              candidate: item,
                              onTap: () => _select(item),
                            );
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

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.onTap,
  });

  final EntityLinkPickerCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entity = candidate.entity;
    final badge = entityTypeBadgeLabel(entity.anchorType);

    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(
        _iconFor(entity.anchorType),
        size: 20,
        color: candidate.isArchived ? Colors.tealAccent : Colors.grey,
      ),
      title: Text(
        entity.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          badge,
          if (candidate.isArchived) '아카이브',
          entity.entityId,
        ].join(' · '),
        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
      ),
      trailing: entity.aliases.isNotEmpty
          ? Text(
              entity.aliases.take(2).join(', '),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }

  static IconData _iconFor(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.person => Icons.person_outline,
      EntityAnchorType.event => Icons.event_outlined,
      EntityAnchorType.concept => Icons.lightbulb_outline,
      _ => Icons.category_outlined,
    };
  }
}
