import 'dart:async';
import 'package:flutter/material.dart';
import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/franchise_group.dart';
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

/// 3중 퓨전 검색: [로컬 .md] + [내 catalog] + [글로벌 사전] + [직접 추가 CTA]
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
  });

  @override
  State<FusionSearchDialog> createState() => _FusionSearchDialogState();
}

class _RemoteSearchEntry {
  final RegistryWork work;
  final RegistryRemoteHint hint;
  final bool isUserCatalog;
  final EntityAnchorType entityType;

  const _RemoteSearchEntry({
    required this.work,
    required this.hint,
    this.isUserCatalog = false,
    this.entityType = EntityAnchorType.work,
  });
}

class _FusionSearchDialogState extends State<FusionSearchDialog> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<AkashaItem> _localResults = [];
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
        _localResults = [];
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
      _localResults = result?.localItems ?? [];
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
        isUserCatalog: hit.isUserLocalCatalog,
        entityType: hit.entityType,
      );

  FranchiseGroup? _franchiseForWork(RegistryWork work) =>
      FranchiseRegistry.groupFor(work.workId);

  Future<void> _handleRemoteTap(_RemoteSearchEntry entry) async {
    if (entry.entityType != EntityAnchorType.work) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(entry.work.title),
          content: Text(
            '${entityTypeBadgeLabel(entry.entityType)} · 내 catalog\n'
            'ID: ${entry.work.workId}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
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
      local: _localResults,
      catalogHits: _catalogHits,
      globalHits: _globalHits,
    );
    final hasRegistryHits = groups.hasRegistryHits;
    final showCustomCta = query.isNotEmpty &&
        !_isSearching &&
        _localResults.isEmpty &&
        !hasRegistryHits;

    return AlertDialog(
      title: const Text('🔍 작품 검색'),
      content: SizedBox(
        width: 440,
        height: 460,
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '제목, 작가, 태그로 검색...',
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
                        '검색어를 입력하세요.\n로컬 아카이브 · 내 catalog · 글로벌 사전을 함께 검색합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    )
                  : ListView(
                      children: [
                        if (groups.local.isNotEmpty) ...[
                          _sectionLabel('📂 내 아카이브', groups.local.length),
                          ...groups.local.map(_buildLocalTile),
                          const SizedBox(height: 8),
                        ],
                        if (groups.catalogWork.isNotEmpty) ...[
                          _sectionLabel(
                            '📋 내 catalog — Work',
                            groups.catalogWork.length,
                          ),
                          ...groups.catalogWork
                              .map((h) => _buildRemoteTile(_entryFromHit(h))),
                          const SizedBox(height: 8),
                        ],
                        if (groups.catalogEntity.isNotEmpty) ...[
                          _sectionLabel(
                            '📋 내 catalog — Entity',
                            groups.catalogEntity.length,
                          ),
                          ...groups.catalogEntity
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
                            _localResults.isEmpty &&
                            !hasRegistryHits &&
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

  Widget _buildLocalTile(AkashaItem item) {
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

  Widget _buildRemoteTile(_RemoteSearchEntry entry) {
    final work = entry.work;
    final hint = entry.hint;
    final isCatalog = entry.isUserCatalog;
    final dimmed = !isCatalog && hint != RegistryRemoteHint.available;
    final franchise = _franchiseForWork(work);

    String? hintText;
    switch (hint) {
      case RegistryRemoteHint.siblingTracked:
        hintText = '다른 매체 버전 추적 중';
      case RegistryRemoteHint.hidden:
        hintText = '숨김됨';
      case RegistryRemoteHint.available:
        break;
    }

    final formatLabels =
        franchise != null ? FranchiseFusionService.franchiseFormatLabels(franchise) : null;

    final typeBadge = entry.entityType != EntityAnchorType.work
        ? entityTypeBadgeLabel(entry.entityType)
        : null;

    final subtitle = [
      work.creator.isNotEmpty
          ? work.creator
          : (isCatalog ? '내 catalog' : '글로벌 사전'),
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
          work.category.icon,
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
            color: hint == RegistryRemoteHint.siblingTracked
                ? Colors.orange[300]
                : hint == RegistryRemoteHint.hidden
                    ? Colors.grey[500]
                    : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onAddRemoteToLibrary != null &&
                (isCatalog || hint == RegistryRemoteHint.available))
              TextButton(
                onPressed: () => widget.onAddRemoteToLibrary!(work),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('담기', style: TextStyle(fontSize: 11)),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isCatalog ? Colors.teal : Colors.blue)
                    .withValues(alpha: dimmed ? 0.08 : 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isCatalog
                    ? (typeBadge ?? '내 catalog')
                    : (hint == RegistryRemoteHint.available ? '사전' : '주의'),
                style: TextStyle(
                  fontSize: 10,
                  color: dimmed && !isCatalog
                      ? Colors.grey[500]
                      : (isCatalog ? Colors.tealAccent : Colors.lightBlueAccent),
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          if (isCatalog) {
            Navigator.pop(context);
            widget.onSelectRemote(work);
            return;
          }
          _handleRemoteTap(entry);
        },
      ),
    );
  }
}
