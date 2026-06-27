part of 'entity_link_picker_dialog.dart';

mixin _EntityLinkPickerDialogActions on _EntityLinkPickerDialogStateBase {
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
    final vaultPath = widget.vaultPath;
    if (vaultPath != null && vaultPath.isNotEmpty) {
      try {
        final saved = await EntityArchiveService.saveFromAddResult(
          result: addResult,
          vaultPath: vaultPath,
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
}
