import 'dart:async';
import 'package:flutter/material.dart';
import '../models/akasha_item.dart';
import '../models/franchise_group.dart';
import '../services/franchise_fusion_service.dart';
import '../services/franchise_registry.dart';
import '../services/franchise_representative_picker.dart';
import '../services/registry_visibility_service.dart';
import '../services/user_registry_preferences.dart';
import '../services/works_registry.dart';
import '../widgets/star_rating.dart';

/// 3중 퓨전 검색: [로컬 .md] + [원격 사전] + [직접 추가 CTA]
class FusionSearchDialog extends StatefulWidget {
  final List<AkashaItem> localItems;
  final void Function(AkashaItem item) onSelectLocal;
  final Future<void> Function(RegistryWork work) onSelectRemote;
  final void Function(String query) onCustomAdd;
  final void Function(String query)? onCatalogPropose;
  final Future<void> Function(AkashaItem item)? onAddLocalToLibrary;
  final Future<void> Function(RegistryWork work)? onAddRemoteToLibrary;

  const FusionSearchDialog({
    super.key,
    required this.localItems,
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

  const _RemoteSearchEntry({required this.work, required this.hint});
}

class _FusionSearchDialogState extends State<FusionSearchDialog> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<AkashaItem> _localResults = [];
  List<_RemoteSearchEntry> _remoteEntries = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Set<String> get _allLocalWorkIds => widget.localItems
      .map((e) => e.workId)
      .where((id) => id.isNotEmpty)
      .toSet();

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _localResults = [];
        _remoteEntries = [];
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

    final q = query.toLowerCase();
    final local = widget.localItems.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.creator.toLowerCase().contains(q) ||
          item.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    final localWorkIds = local
        .map((e) => e.workId)
        .where((id) => id.isNotEmpty)
        .toSet();

    List<_RemoteSearchEntry> remoteEntries = [];
    String? error;
    try {
      final registryHits = await WorksRegistry.searchAsync(query);
      remoteEntries = _dedupeFranchiseEntries(
        registryHits
            .where((work) => !localWorkIds.contains(work.workId))
            .map((work) => _RemoteSearchEntry(
                  work: work,
                  hint: RegistryVisibilityService.remoteSearchHint(
                    workId: work.workId,
                    userWorkIds: _allLocalWorkIds,
                  ),
                ))
            .toList()
          ..sort((a, b) {
            final order = RegistryVisibilityService.remoteHintSortOrder(a.hint)
                .compareTo(
                    RegistryVisibilityService.remoteHintSortOrder(b.hint));
            if (order != 0) return order;
            final scoreCmp = WorksRegistry.qualityScoreFor(b.work.workId)
                .compareTo(WorksRegistry.qualityScoreFor(a.work.workId));
            if (scoreCmp != 0) return scoreCmp;
            return a.work.title.compareTo(b.work.title);
          }),
      );
    } catch (e) {
      error = '원격 사전 검색 실패 (오프라인일 수 있습니다)';
    }

    if (!mounted) return;
    setState(() {
      _localResults = FranchiseRepresentativePicker.dedupeLocalByFranchise(local);
      _remoteEntries = remoteEntries;
      _isSearching = false;
      _searchError = error;
    });
  }

  List<_RemoteSearchEntry> _dedupeFranchiseEntries(
    List<_RemoteSearchEntry> entries,
  ) {
    final localFranchiseIds = <String>{};
    for (final local in widget.localItems) {
      final group = FranchiseRegistry.groupFor(local.workId);
      if (group != null) localFranchiseIds.add(group.id);
    }

    final emittedFranchises = <String>{};
    final result = <_RemoteSearchEntry>[];

    for (final entry in entries) {
      final group = FranchiseRegistry.groupFor(entry.work.workId);
      if (group == null) {
        result.add(entry);
        continue;
      }

      if (localFranchiseIds.contains(group.id)) continue;
      if (emittedFranchises.contains(group.id)) continue;
      emittedFranchises.add(group.id);

      final franchiseEntries = entries
          .where(
            (e) => FranchiseRegistry.groupFor(e.work.workId)?.id == group.id,
          )
          .toList();

      final primaryWork =
          WorksRegistry.getWorkById(group.primaryWorkId) ?? entry.work;
      final hint = _mergeHints(franchiseEntries.map((e) => e.hint));

      result.add(_RemoteSearchEntry(work: primaryWork, hint: hint));
    }

    return result;
  }

  RegistryRemoteHint _mergeHints(Iterable<RegistryRemoteHint> hints) {
    if (hints.any((h) => h == RegistryRemoteHint.hidden)) {
      return RegistryRemoteHint.hidden;
    }
    if (hints.any((h) => h == RegistryRemoteHint.siblingTracked)) {
      return RegistryRemoteHint.siblingTracked;
    }
    return RegistryRemoteHint.available;
  }

  FranchiseGroup? _franchiseForWork(RegistryWork work) =>
      FranchiseRegistry.groupFor(work.workId);

  Future<void> _handleRemoteTap(_RemoteSearchEntry entry) async {
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
    final showCustomCta = query.isNotEmpty &&
        !_isSearching &&
        _localResults.isEmpty &&
        _remoteEntries.isEmpty;

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
                        '검색어를 입력하세요.\n로컬 아카이브와 글로벌 사전을 함께 검색합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    )
                  : ListView(
                      children: [
                        if (_localResults.isNotEmpty) ...[
                          _sectionLabel('📂 내 아카이브', _localResults.length),
                          ..._localResults.map(_buildLocalTile),
                          const SizedBox(height: 8),
                        ],
                        if (_remoteEntries.isNotEmpty) ...[
                          _sectionLabel('🌐 글로벌 사전', _remoteEntries.length),
                          ..._remoteEntries.map(_buildRemoteTile),
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
                                  label: const Text('내 아카이브에 직접 추가'),
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
                            _remoteEntries.isEmpty &&
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
    final dimmed = hint != RegistryRemoteHint.available;
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

    final subtitle = [
      work.creator.isNotEmpty ? work.creator : '글로벌 사전',
      if (formatLabels != null && formatLabels.isNotEmpty) formatLabels else work.category.label,
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
                hint == RegistryRemoteHint.available)
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
                color: Colors.blue.withValues(alpha: dimmed ? 0.08 : 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                hint == RegistryRemoteHint.available ? '사전' : '주의',
                style: TextStyle(
                  fontSize: 10,
                  color: dimmed ? Colors.grey[500] : Colors.lightBlueAccent,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _handleRemoteTap(entry),
      ),
    );
  }
}
