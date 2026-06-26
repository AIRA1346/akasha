part of 'fusion_search_dialog.dart';

mixin _FusionSearchDialogSearch on _FusionSearchDialogStateBase {
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

  FusionRemoteSearchEntry entryFromHit(FusionRegistryHit hit) => FusionRemoteSearchEntry(
        work: hit.work,
        hint: hit.hint,
        isUserLocal: hit.isUserLocalCatalog,
        entityType: hit.entityType,
        catalogOnly: hit.catalogOnly,
      );

  RegistryWork registryWorkFromEntityEntry(EntityJournalEntry entry) {
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

  Future<void> _handleRemoteTap(FusionRemoteSearchEntry entry) async {
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
}
