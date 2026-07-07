import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/akasha_item.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';

class CanvasSearchHit {
  CanvasSearchHit({
    required this.id,
    required this.kind, // 'work' or 'entity'
    required this.title,
    this.subtype,
  });

  final String id;
  final String kind;
  final String title;
  final String? subtype;
}

class CanvasArchiveSearchDialog extends StatefulWidget {
  const CanvasArchiveSearchDialog({
    super.key,
    required this.vaultPath,
    required this.localItems,
  });

  final String vaultPath;
  final List<AkashaItem> localItems;

  @override
  State<CanvasArchiveSearchDialog> createState() => _CanvasArchiveSearchDialogState();
}

class _CanvasArchiveSearchDialogState extends State<CanvasArchiveSearchDialog> {
  final _searchCtrl = TextEditingController();
  List<EntityJournalEntry> _entities = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadEntities();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchCtrl.text.trim().toLowerCase();
    });
  }

  Future<void> _loadEntities() async {
    try {
      final loader = const EntityVaultLoader();
      final entities = await loader.loadFromVault(widget.vaultPath);
      if (mounted) {
        setState(() {
          _entities = entities;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;

    final filteredWorks = widget.localItems.where((work) {
      if (_query.isEmpty) return true;
      return work.title.toLowerCase().contains(_query) ||
          work.creator.toLowerCase().contains(_query);
    }).toList();

    final filteredEntities = _entities.where((entity) {
      if (_query.isEmpty) return true;
      return entity.title.toLowerCase().contains(_query) ||
          entity.tags.any((t) => t.toLowerCase().contains(_query));
    }).toList();

    return Dialog(
      backgroundColor: palette.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AkashaRadius.md),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(AkashaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.archive_outlined, size: 20),
                const SizedBox(width: AkashaSpacing.xs),
                Text(
                  '로컬 아카이브 노드 추가',
                  style: AkashaTypography.headline,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AkashaSpacing.sm),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: AkashaTypography.body,
              decoration: InputDecoration(
                hintText: '작품명 또는 인물·개념 검색...',
                hintStyle: TextStyle(color: palette.border),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: palette.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AkashaRadius.sm),
                  borderSide: BorderSide(color: palette.border.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AkashaRadius.sm),
                  borderSide: BorderSide(color: palette.accent),
                ),
              ),
            ),
            const SizedBox(height: AkashaSpacing.md),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : (filteredWorks.isEmpty && filteredEntities.isEmpty)
                      ? Center(
                          child: Text(
                            '검색 결과가 없습니다.',
                            style: TextStyle(color: AkashaColors.textSecondary),
                          ),
                        )
                      : ListView(
                          children: [
                            if (filteredWorks.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AkashaSpacing.xs,
                                  horizontal: AkashaSpacing.xs,
                                ),
                                child: Text(
                                  '작품 (${filteredWorks.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: palette.accent,
                                  ),
                                ),
                              ),
                              ...filteredWorks.map((work) {
                                return ListTile(
                                  leading: Icon(
                                    Icons.movie_filter_outlined,
                                    color: palette.accent,
                                    size: 18,
                                  ),
                                  title: Text(work.title, style: AkashaTypography.body),
                                  subtitle: Text(
                                    work.creator,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AkashaColors.textSecondary,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                      CanvasSearchHit(
                                        id: work.workId,
                                        kind: 'work',
                                        title: work.title,
                                        subtype: 'work',
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                            if (filteredEntities.isNotEmpty) ...[
                              const SizedBox(height: AkashaSpacing.sm),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AkashaSpacing.xs,
                                  horizontal: AkashaSpacing.xs,
                                ),
                                child: Text(
                                  '엔티티 (${filteredEntities.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                              ),
                              ...filteredEntities.map((entity) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.person_outline,
                                    color: Colors.tealAccent,
                                    size: 18,
                                  ),
                                  title: Text(entity.title, style: AkashaTypography.body),
                                  subtitle: Text(
                                    entity.tags.join(', '),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AkashaColors.textSecondary,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                      CanvasSearchHit(
                                        id: entity.entityId,
                                        kind: 'entity',
                                        title: entity.title,
                                        subtype: entity.entityType.name,
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
