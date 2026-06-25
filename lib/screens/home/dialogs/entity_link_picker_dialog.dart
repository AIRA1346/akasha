import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/catalog_entity_add_result.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_archive_service.dart';
import '../../../services/entity_vault_path_conflict.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../services/file_service.dart';
import '../../../services/entity_link_picker_candidates.dart';
import '../../../services/entity_seed_catalog_promotion.dart';
import '../../../services/link_candidate_service.dart';
import '../../../utils/entity_tag_validation.dart';
import '../../../theme/akasha_colors.dart';
import 'add_catalog_entity_dialog.dart';

/// R2-B — Work Sanctum Entity link picker (선택만 · markdown 삽입은 Step 2).
Future<EntityLinkSelection?> showEntityLinkPickerDialog(
  BuildContext context, {
  required UserCatalogPort userCatalog,
  EntityVaultLoader? entityLoader,
  String? initialQuery,
  EntityAnchorType? anchorTypeFilter,
  AkashaItem? workContext,
  List<AkashaItem> vaultItems = const [],
}) {
  return showDialog<EntityLinkSelection>(
    context: context,
    builder: (ctx) => EntityLinkPickerDialog(
      userCatalog: userCatalog,
      entityLoader: entityLoader,
      initialQuery: initialQuery,
      anchorTypeFilter: anchorTypeFilter,
      workContext: workContext,
      vaultItems: vaultItems,
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
    this.workContext,
    this.vaultItems = const [],
  });

  final UserCatalogPort userCatalog;
  final EntityVaultLoader? entityLoader;
  final String? initialQuery;
  final EntityAnchorType? anchorTypeFilter;
  final AkashaItem? workContext;
  final List<AkashaItem> vaultItems;

  @override
  State<EntityLinkPickerDialog> createState() => _EntityLinkPickerDialogState();
}

class _EntityLinkPickerDialogState extends State<EntityLinkPickerDialog> {
  late final TextEditingController _queryCtrl;
  List<EntityLinkPickerCandidate> _candidates = const [];
  List<LinkCandidate> _recommendations = const [];
  var _loading = true;
  var _tab = 0;
  var _creating = false;

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

    final query = _queryCtrl.text;
    final work = widget.workContext;

    List<LinkCandidate> recommendations = const [];
    if (work != null) {
      recommendations = await LinkCandidateService.candidatesForWork(
        work: work,
        userCatalog: widget.userCatalog,
        typeFilter: widget.anchorTypeFilter,
        limit: 6,
      );
      final q = query.trim().toLowerCase();
      if (q.isNotEmpty) {
        recommendations = recommendations
            .where(
              (c) =>
                  c.title.toLowerCase().contains(q) ||
                  (c.matchDetail?.toLowerCase().contains(q) ?? false),
            )
            .toList();
      }
    }

    final list = await EntityLinkPickerCandidates.build(
      userCatalog: widget.userCatalog,
      query: query,
      loader: widget.entityLoader,
      anchorTypeFilter: widget.anchorTypeFilter,
    );

    final recommendedIds = recommendations
        .map((c) => c.entityId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final filtered = list
        .where((c) => !recommendedIds.contains(c.entity.entityId))
        .toList();

    if (!mounted) return;
    setState(() {
      _recommendations = recommendations;
      _candidates = filtered;
      _loading = false;
    });
  }

  Future<void> _select(EntityLinkPickerCandidate candidate) async {
    UserCatalogEntity entity = candidate.entity;
    if (candidate.isSeed && candidate.seedFact != null) {
      entity = await EntitySeedCatalogPromotion.ensureInCatalog(
        userCatalog: widget.userCatalog,
        fact: candidate.seedFact!,
      );
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      EntityLinkSelection(
        entityId: entity.entityId,
        title: entity.title,
        entityType: entity.entityType,
      ),
    );
  }

  Future<void> _selectRecommendation(LinkCandidate candidate) async {
    final selection = await LinkCandidateService.resolveSelection(
      candidate: candidate,
      userCatalog: widget.userCatalog,
    );
    if (!mounted) return;
    Navigator.pop(context, selection);
  }

  Future<void> _createNewEntity() async {
    final type = widget.anchorTypeFilter;
    if (type == null || _creating) return;

    setState(() => _creating = true);
    try {
      await widget.userCatalog.load();
      if (!mounted) return;
      final workTitleIndex = EntityTagValidation.buildWorkTitleIndex(
        catalogEntities: widget.userCatalog.all,
        vaultItems: widget.vaultItems,
      );

      final addResult = await showAddCatalogEntityDialog(
        context,
        entityType: type,
        initialTitle: _queryCtrl.text.trim(),
        workTitleIndex: workTitleIndex,
      );
      if (!mounted || addResult == null) return;

      final entity = await _persistAddResult(addResult);
      if (!mounted || entity == null) return;

      Navigator.pop(
        context,
        EntityLinkSelection(
          entityId: entity.entityId,
          title: entity.title,
          entityType: entity.entityType,
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<UserCatalogEntity?> _persistAddResult(
    CatalogEntityAddResult addResult,
  ) async {
    final vault = AkashaFileService().vaultPath;
    if (vault != null && vault.isNotEmpty) {
      try {
        final saved = await EntityArchiveService.saveFromAddResult(
          result: addResult,
          vaultPath: vault,
          userCatalog: widget.userCatalog,
        );
        return saved.entity;
      } on EntityVaultPathConflict catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.userMessage)),
          );
        }
        return null;
      }
    }

    await widget.userCatalog.upsert(addResult.entity);
    return addResult.entity;
  }

  bool get _canCreateNew =>
      widget.anchorTypeFilter != null &&
      widget.anchorTypeFilter != EntityAnchorType.work;

  @override
  Widget build(BuildContext context) {
    final hasRecommendations = _recommendations.isNotEmpty;
    final hasCandidates = _candidates.isNotEmpty;
    final showEmpty = !hasRecommendations && !hasCandidates;

    return AlertDialog(
      title: Text(_dialogTitle()),
      content: SizedBox(
        width: 420,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_canCreateNew) ...[
              Row(
                children: [
                  _PickerTab(
                    label: '기존 연결',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 8),
                  _PickerTab(
                    label: '새로 만들기',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (_tab == 0 || !_canCreateNew) ...[
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
                _subtitleText(),
                style: TextStyle(fontSize: 11, color: AkashaColors.textMuted),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : showEmpty
                        ? Center(
                            child: Text(
                              _queryCtrl.text.trim().isEmpty
                                  ? '연결할 Entity가 없습니다.'
                                  : '「${_queryCtrl.text.trim()}」과(와) 일치하는 항목이 없습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AkashaColors.textMuted,
                              ),
                            ),
                          )
                        : ListView(
                            children: [
                              if (hasRecommendations) ...[
                                const _SectionLabel('이 작품과 관련'),
                                ..._recommendations.map(
                                  (item) => _RecommendationTile(
                                    candidate: item,
                                    onTap: () => _selectRecommendation(item),
                                  ),
                                ),
                                if (hasCandidates) ...[
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  const _SectionLabel('검색 결과'),
                                ],
                              ],
                              ..._candidates.map(
                                (item) => _CandidateTile(
                                  candidate: item,
                                  onTap: () => _select(item),
                                ),
                              ),
                            ],
                          ),
              ),
            ] else
              Expanded(child: _buildCreateTab()),
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

  Widget _buildCreateTab() {
    final type = widget.anchorTypeFilter!;
    final typeLabel = entityTypeBadgeLabel(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '카탈로그에 없는 $typeLabel을(를) 새로 등록하고, 이 작품 본문에 바로 연결합니다.',
          style: TextStyle(fontSize: 12, color: AkashaColors.textSecondary),
        ),
        const SizedBox(height: 16),
        if (_queryCtrl.text.trim().isNotEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(_iconFor(type), size: 20, color: AkashaColors.accent),
            title: Text(
              _queryCtrl.text.trim(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '검색어를 이름으로 사용',
              style: TextStyle(fontSize: 10, color: AkashaColors.textMuted),
            ),
          ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _creating ? null : _createNewEntity,
          icon: _creating
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add, size: 16),
          label: Text('$typeLabel 새로 만들기'),
        ),
      ],
    );
  }

  static IconData _iconFor(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.person => Icons.person_outline,
      EntityAnchorType.event => Icons.event_outlined,
      EntityAnchorType.concept => Icons.lightbulb_outline,
      EntityAnchorType.place => Icons.place_outlined,
      EntityAnchorType.organization => Icons.groups_outlined,
      _ => Icons.category_outlined,
    };
  }

  String _dialogTitle() {
    return switch (widget.anchorTypeFilter) {
      EntityAnchorType.person => '인물 추가',
      EntityAnchorType.event => '사건 추가',
      EntityAnchorType.concept => '개념 추가',
      EntityAnchorType.place => '장소 추가',
      EntityAnchorType.organization => '조직 추가',
      _ => 'Entity 연결',
    };
  }

  String _subtitleText() {
    if (_recommendations.isNotEmpty) {
      return '추천 후보 · Person · Event · Concept · Place · Org';
    }
    if (_candidates.any((c) => c.isSeed)) {
      return '내 카탈로그에 없습니다 · 사전 인물에서 연결할 수 있습니다';
    }
    return '카탈로그 · Person · Event · Concept · Place · Org';
  }
}

class _PickerTab extends StatelessWidget {
  const _PickerTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AkashaColors.accent.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AkashaColors.accent : AkashaColors.textCaption,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AkashaColors.accent : AkashaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AkashaColors.textSecondary,
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.candidate,
    required this.onTap,
  });

  final LinkCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(
        _iconFor(candidate.anchorType),
        size: 20,
        color: AkashaColors.accent,
      ),
      title: Text(
        candidate.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          _reasonLabel(candidate.reason),
          if (candidate.matchDetail != null) candidate.matchDetail!,
        ].join(' · '),
        style: TextStyle(fontSize: 10, color: AkashaColors.textMuted),
      ),
      trailing: const Icon(Icons.north_west, size: 14, color: Colors.tealAccent),
    );
  }

  static String _reasonLabel(LinkCandidateReason reason) {
    return switch (reason) {
      LinkCandidateReason.creator => 'creator',
      LinkCandidateReason.tag => 'tag',
      LinkCandidateReason.seed => 'seed',
      LinkCandidateReason.catalog => 'catalog',
    };
  }

  static IconData _iconFor(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.person => Icons.person_outline,
      EntityAnchorType.event => Icons.event_outlined,
      EntityAnchorType.concept => Icons.lightbulb_outline,
      EntityAnchorType.place => Icons.place_outlined,
      EntityAnchorType.organization => Icons.groups_outlined,
      _ => Icons.category_outlined,
    };
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
        color: candidate.isArchived ? Colors.tealAccent : AkashaColors.textMuted,
      ),
      title: Text(
        entity.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          badge,
          if (candidate.isSeed) '사전 인물',
          if (candidate.isArchived) '아카이브',
          if (!candidate.isSeed) entity.entityId,
        ].join(' · '),
        style: TextStyle(fontSize: 10, color: AkashaColors.textMuted),
      ),
      trailing: entity.aliases.isNotEmpty
          ? Text(
              entity.aliases.take(2).join(', '),
              style: TextStyle(fontSize: 10, color: AkashaColors.textCaption),
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
      EntityAnchorType.place => Icons.place_outlined,
      EntityAnchorType.organization => Icons.groups_outlined,
      _ => Icons.category_outlined,
    };
  }
}
