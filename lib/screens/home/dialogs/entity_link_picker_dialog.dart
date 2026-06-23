import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_link_picker_candidates.dart';
import '../../../services/entity_seed_catalog_promotion.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../services/link_candidate_service.dart';
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
}) {
  return showDialog<EntityLinkSelection>(
    context: context,
    builder: (ctx) => EntityLinkPickerDialog(
      userCatalog: userCatalog,
      entityLoader: entityLoader,
      initialQuery: initialQuery,
      anchorTypeFilter: anchorTypeFilter,
      workContext: workContext,
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
  });

  final UserCatalogPort userCatalog;
  final EntityVaultLoader? entityLoader;
  final String? initialQuery;
  final EntityAnchorType? anchorTypeFilter;
  final AkashaItem? workContext;

  @override
  State<EntityLinkPickerDialog> createState() => _EntityLinkPickerDialogState();
}

class _EntityLinkPickerDialogState extends State<EntityLinkPickerDialog> {
  late final TextEditingController _queryCtrl;
  List<EntityLinkPickerCandidate> _candidates = const [];
  List<LinkCandidate> _recommendations = const [];
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

  @override
  Widget build(BuildContext context) {
    final hasRecommendations = _recommendations.isNotEmpty;
    final hasCandidates = _candidates.isNotEmpty;
    final showEmpty = !hasRecommendations && !hasCandidates;

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
              _subtitleText(),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                              color: Colors.grey[500],
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
          color: Colors.grey[400],
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
        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
        color: candidate.isArchived ? Colors.tealAccent : Colors.grey,
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
      EntityAnchorType.place => Icons.place_outlined,
      EntityAnchorType.organization => Icons.groups_outlined,
      _ => Icons.category_outlined,
    };
  }
}
