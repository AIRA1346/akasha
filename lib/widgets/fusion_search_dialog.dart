import 'dart:async';
import 'package:flutter/material.dart';
import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../models/akasha_item.dart';
import '../models/franchise_group.dart';
import '../models/enums.dart';
import '../models/registry_work.dart';
import '../core/ports/entity_registry_port.dart';
import '../core/ports/registry_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../services/franchise_fusion_service.dart';
import '../services/franchise_registry.dart';
import '../services/fusion_search_service.dart';
import '../services/fusion_search_sections.dart';
import '../services/registry_visibility_service.dart';
import '../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../services/user_registry_preferences.dart';
import '../services/works_registry.dart';
import '../widgets/star_rating.dart';

/// Fusion: 로컬 아카이브 · user local · 글로벌 사전 · 직접 추가 CTA.
class FusionSearchDialog extends StatefulWidget {
  final List<AkashaItem> localItems;
  final UserCatalogPort userCatalog;
  final RegistryPort registry;
  final EntityRegistryPort? entityRegistry;
  final void Function(AkashaItem item) onSelectLocal;
  final Future<void> Function(RegistryWork work) onSelectRemote;
  final void Function(String query) onCustomAdd;
  final void Function(String query)? onCatalogPropose;
  final Future<void> Function(AkashaItem item)? onAddLocalToLibrary;
  final Future<void> Function(RegistryWork work)? onAddRemoteToLibrary;
  final Future<void> Function(RegistryWork work)? onPromoteCatalogEntity;

  const FusionSearchDialog({
    super.key,
    required this.localItems,
    required this.userCatalog,
    required this.registry,
    this.entityRegistry,
    required this.onSelectLocal,
    required this.onSelectRemote,
    required this.onCustomAdd,
    this.onCatalogPropose,
    this.onAddLocalToLibrary,
    this.onAddRemoteToLibrary,
    this.onPromoteCatalogEntity,
  });

  @override
  State<FusionSearchDialog> createState() => _FusionSearchDialogState();
}

class _RemoteSearchEntry {
  final RegistryWork work;
  final RegistryRemoteHint hint;
  final bool isUserLocal;
  final EntityAnchorType entityType;
  final bool catalogOnly;

  const _RemoteSearchEntry({
    required this.work,
    required this.hint,
    this.isUserLocal = false,
    this.entityType = EntityAnchorType.work,
    this.catalogOnly = false,
  });
}

class _FusionSearchDialogState extends State<FusionSearchDialog> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<AkashaItem> _localWorkResults = [];
  List<EntityJournalEntry> _localEntityResults = [];
  List<FusionRegistryHit> _catalogHits = [];
  List<FusionRegistryHit> _globalHits = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _localWorkResults = [];
        _localEntityResults = [];
        _catalogHits = [];
        _globalHits = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(trimmed);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    String? error;
    FusionSearchResult? result;
    try {
      result = await FusionSearchService.search(
        query: query,
        localItems: widget.localItems,
        userCatalog: widget.userCatalog,
        registry: widget.registry,
        entityRegistry: widget.entityRegistry,
      );
    } catch (e) {
      error = '원격 사전 검색 실패 (오프라인일 수 있습니다)';
    }

    if (!mounted) return;
    final hits = result?.registryHits ?? [];
    setState(() {
      _localWorkResults = result?.localItems ?? [];
      _localEntityResults = result?.localEntityJournals ?? [];
      _catalogHits =
          hits.where((h) => h.source == FusionRegistrySource.userCatalog).toList();
      _globalHits =
          hits.where((h) => h.source == FusionRegistrySource.globalRegistry).toList();
      _isSearching = false;
      _searchError = error;
    });
  }

  _RemoteSearchEntry _entryFromHit(FusionRegistryHit hit) => _RemoteSearchEntry(
        work: hit.work,
        hint: hit.hint,
        isUserLocal: hit.isUserLocalCatalog,
        entityType: hit.entityType,
        catalogOnly: hit.catalogOnly,
      );

  RegistryWork _registryWorkFromEntityEntry(EntityJournalEntry entry) {
    for (final entity in widget.userCatalog.all) {
      if (entity.entityId == entry.entityId) {
        return entity.toRegistryWork();
      }
    }
    return RegistryWork(
      workId: entry.entityId,
      title: entry.title,
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
    );
  }

  FranchiseGroup? _franchiseForWork(RegistryWork work) =>
      FranchiseRegistry.groupFor(work.workId);

  Future<void> _handleRemoteTap(_RemoteSearchEntry entry) async {
    if (entry.entityType != EntityAnchorType.work) {
      if (entry.catalogOnly && widget.onPromoteCatalogEntity != null) {
        if (!mounted) return;
        Navigator.pop(context);
        await widget.onPromoteCatalogEntity!(entry.work);
        return;
      }
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onSelectRemote(entry.work);
      return;
    }

    final work = entry.work;
    final hint = entry.hint;

    if (hint == RegistryRemoteHint.siblingTracked) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('다른 매체 버전'),
          content: Text(
            '「${work.title}」(${work.category.label})은(는) '
            '이미 추적 중인 같은 작품의 다른 매체입니다.\n\n'
            '이 버전도 따로 추가할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('추가'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    if (hint == RegistryRemoteHint.hidden) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('숨긴 항목'),
          content: Text(
            '「${work.title}」은(는) 사전에서 숨긴 항목입니다.\n'
            '복원하고 추가할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('복원 후 추가'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
      await UserRegistryPreferences.instance.unhideWork(work.workId);
    }

    if (!mounted) return;
    Navigator.pop(context);
    await widget.onSelectRemote(work);
  }

  @override
  Widget build(BuildContext context) {
    final query = _ctrl.text.trim();
    final groups = FusionSearchSections.group(
      localWork: _localWorkResults,
      localEntity: _localEntityResults,
      catalogHits: _catalogHits,
      globalHits: _globalHits,
    );
    final showCustomCta = query.isNotEmpty &&
        !_isSearching &&
        !groups.hasAnyHits;

    return AlertDialog(
      title: const Text('🔍 검색'),
      content: SizedBox(
        width: 440,
        height: 460,
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '제목, 작가, 태그, Entity…',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onQueryChanged,
            ),
            if (_searchError != null) ...[
              const SizedBox(height: 8),
              Text(
                _searchError!,
                style: TextStyle(fontSize: 11, color: Colors.orange[300]),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: query.isEmpty
                  ? Center(
                      child: Text(
                        '검색어를 입력하세요.\n로컬 아카이브 · 내 등록 · 글로벌 사전을 함께 검색합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    )
                  : ListView(
                      children: [
                        if (groups.localWork.isNotEmpty) ...[
                          _sectionLabel('📂 내 아카이브 — Work', groups.localWork.length),
                          ...groups.localWork.map(_buildLocalWorkTile),
                          const SizedBox(height: 8),
                        ],
                        if (groups.localEntity.isNotEmpty) ...[
                          _sectionLabel(
                            '📂 내 아카이브 — Entity',
                            groups.localEntity.length,
                          ),
                          ...groups.localEntity.map(_buildLocalEntityTile),
                          const SizedBox(height: 8),
                        ],
                        if (groups.catalogWork.isNotEmpty) ...[
                          _sectionLabel(
                            '📂 내 아카이브 — Work (등록만)',
                            groups.catalogWork.length,
                          ),
                          ...groups.catalogWork
                              .map((h) => _buildRemoteTile(_entryFromHit(h))),
                          const SizedBox(height: 8),
                        ],
                        if (groups.catalogEntityOnly.isNotEmpty) ...[
                          _sectionLabel(
                            '⏳ 아카이브되지 않음',
                            groups.catalogEntityOnly.length,
                          ),
                          ...groups.catalogEntityOnly
                              .map((h) => _buildRemoteTile(_entryFromHit(h))),
                          const SizedBox(height: 8),
                        ],
                        if (groups.globalWork.isNotEmpty) ...[
                          _sectionLabel(
                            '🌐 글로벌 사전 — Work',
                            groups.globalWork.length,
                          ),
                          ...groups.globalWork
                              .map((h) => _buildRemoteTile(_entryFromHit(h))),
                          const SizedBox(height: 8),
                        ],
                        if (groups.globalEntity.isNotEmpty) ...[
                          _sectionLabel(
                            '🌐 글로벌 — Entity',
                            groups.globalEntity.length,
                          ),
                          ...groups.globalEntity
                              .map((h) => _buildRemoteTile(_entryFromHit(h))),
                        ],
                        if (showCustomCta) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onCustomAdd(query);
                                  },
                                  icon: const Icon(Icons.person_add_outlined),
                                  label: const Text('직접 추가 (유형 선택)'),
                                ),
                                if (widget.onCatalogPropose != null) ...[
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      widget.onCatalogPropose!(query);
                                    },
                                    icon: const Icon(Icons.library_add_outlined),
                                    label: const Text('글로벌 사전에 추가 제안'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (!_isSearching &&
                            query.isNotEmpty &&
                            !groups.hasAnyHits &&
                            _searchError == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(child: Text('검색 결과가 없습니다.')),
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
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.tealAccent,
        ),
      ),
    );
  }

  Widget _buildLocalWorkTile(AkashaItem item) {
    final franchise = FranchiseRegistry.groupFor(item.workId);
    final formatLabels = franchise != null
        ? FranchiseFusionService.franchiseFormatLabels(franchise)
        : null;

    final subtitle = [
      item.creator.isNotEmpty ? item.creator : '내 아카이브',
      if (formatLabels != null && formatLabels.isNotEmpty) formatLabels,
    ].join(' · ');

    return ListTile(
      dense: true,
      leading: Icon(item.category.icon, size: 20),
      title: Text(
        franchise?.displayName ?? item.title,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onAddLocalToLibrary != null)
            IconButton(
              icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
              tooltip: '서재에 담기',
              visualDensity: VisualDensity.compact,
              onPressed: () => widget.onAddLocalToLibrary!(item),
            ),
          StarRating(rating: item.rating, size: 11),
        ],
      ),
      onTap: () {
        Navigator.pop(context);
        widget.onSelectLocal(item);
      },
    );
  }

  Widget _buildLocalEntityTile(EntityJournalEntry entry) {
    final badge = entityTypeBadgeLabel(entry.entityType);
    return ListTile(
      dense: true,
      leading: Icon(_iconForEntityType(entry.entityType), size: 20),
      title: Text(entry.title, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        '$badge · 내 아카이브',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          badge,
          style: const TextStyle(fontSize: 10, color: Colors.tealAccent),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        widget.onSelectRemote(_registryWorkFromEntityEntry(entry));
      },
    );
  }

  Widget _buildRemoteTile(_RemoteSearchEntry entry) {
    final work = entry.work;
    final hint = entry.hint;
    final isUserLocal = entry.isUserLocal;
    final catalogOnly = entry.catalogOnly;
    final dimmed = !isUserLocal && hint != RegistryRemoteHint.available;
    final franchise = _franchiseForWork(work);

    String? hintText;
    switch (hint) {
      case RegistryRemoteHint.siblingTracked:
        hintText = '다른 매체 버전 추적 중';
      case RegistryRemoteHint.hidden:
        hintText = '숨김됨';
      case RegistryRemoteHint.available:
        if (catalogOnly) hintText = '아카이브되지 않음';
    }

    final formatLabels =
        franchise != null ? FranchiseFusionService.franchiseFormatLabels(franchise) : null;

    final typeBadge = entry.entityType != EntityAnchorType.work
        ? entityTypeBadgeLabel(entry.entityType)
        : null;

    final subtitle = [
      work.creator.isNotEmpty
          ? work.creator
          : (isUserLocal ? '내 등록' : '글로벌 사전'),
      if (typeBadge != null)
        typeBadge
      else if (formatLabels != null && formatLabels.isNotEmpty)
        formatLabels
      else
        work.category.label,
      ?hintText,
    ].whereType<String>().join(' · ');

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: ListTile(
        dense: true,
        leading: Icon(
          catalogOnly
              ? _iconForEntityType(entry.entityType)
              : work.category.icon,
          size: 20,
          color: dimmed ? Colors.grey : Colors.lightBlueAccent,
        ),
        title: Text(
          franchise?.displayName ?? work.title,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: catalogOnly
                ? Colors.orange[300]
                : hint == RegistryRemoteHint.siblingTracked
                    ? Colors.orange[300]
                    : hint == RegistryRemoteHint.hidden
                        ? Colors.grey[500]
                        : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (catalogOnly && widget.onPromoteCatalogEntity != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await widget.onPromoteCatalogEntity!(work);
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('아카이브하기', style: TextStyle(fontSize: 11)),
              )
            else if (widget.onAddRemoteToLibrary != null &&
                (isUserLocal || hint == RegistryRemoteHint.available))
              TextButton(
                onPressed: () => widget.onAddRemoteToLibrary!(work),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('담기', style: TextStyle(fontSize: 11)),
              ),
            if (!catalogOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isUserLocal ? Colors.teal : Colors.blue)
                      .withValues(alpha: dimmed ? 0.08 : 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isUserLocal
                      ? (typeBadge ?? '내 아카이브')
                      : (hint == RegistryRemoteHint.available ? '사전' : '주의'),
                  style: TextStyle(
                    fontSize: 10,
                    color: dimmed && !isUserLocal
                        ? Colors.grey[500]
                        : (isUserLocal ? Colors.tealAccent : Colors.lightBlueAccent),
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          if (isUserLocal && !catalogOnly) {
            Navigator.pop(context);
            widget.onSelectRemote(work);
            return;
          }
          _handleRemoteTap(entry);
        },
      ),
    );
  }

  static IconData _iconForEntityType(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.person => Icons.person_outline,
      EntityAnchorType.concept => Icons.lightbulb_outline,
      EntityAnchorType.event => Icons.event_outlined,
      EntityAnchorType.place => Icons.place_outlined,
      EntityAnchorType.organization => Icons.groups_outlined,
      _ => Icons.category_outlined,
    };
  }
}
