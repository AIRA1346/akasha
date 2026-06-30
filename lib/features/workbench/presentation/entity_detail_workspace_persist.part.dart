part of 'entity_detail_workspace.dart';

mixin _EntityDetailWorkspacePersist on _EntityDetailWorkspaceStateBase {
  void _bindSaveHandler() {
    widget.onBindSave(() => _saveJournal());
  }

  String _serializeFile() => EntityDetailDraftOps.serializeFile(
        entity: _entity,
        journal: _journal,
        body: _bodyCtrl.text,
        tags: _draftTags,
        posterPath: _posterUrlCtrl.text,
      );

  void _syncBodyFromEditor() {
    if (_pageView != SanctumPageView.file) return;
    final tags = EntityDetailDraftOps.syncBodyFromFileEditor(
      fileText: _fileCtrl.text,
      bodyCtrl: _bodyCtrl,
    );
    if (tags != null) {
      _draftTags = tags;
    }
  }

  void _refreshFileEditor() {
    _syncBodyFromEditor();
    _fileCtrl.text = _serializeFile();
  }

  void _onPageViewChanged(SanctumPageView next) {
    EntityDetailDraftOps.handlePageViewChanging(
      current: _pageView,
      next: next,
      fileCtrl: _fileCtrl,
      bodyCtrl: _bodyCtrl,
      refreshFileEditor: _refreshFileEditor,
      syncBodyFromFile: _syncBodyFromEditor,
    );
    setState(() => _pageView = next);
  }

  void _markDirty() {
    widget.onDirtyChanged(true);
    _scheduleAutoSave();
  }

  void _onDraftTagsChanged(List<String> tags) {
    setState(() => _draftTags = tags);
    _updatePreview();
    _markDirty();
  }

  void _scheduleAutoSave() {
    _autosave.schedule(
      persistEnabled: !_suppressPersist,
      isDirty: () => widget.isDirty,
      isActive: () => mounted,
      save: () => _saveJournal(silent: true),
    );
  }

  Future<void> _saveJournal({bool silent = false}) async {
    if (EntityDetailSaveOps.shouldSkip(
      suppressPersist: _suppressPersist,
      isSaving: _isSaving,
    )) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await EntityDetailSaveOrchestrator.run(
        suppressPersist: _suppressPersist,
        isSaving: false,
        rawBody: _bodyCtrl.text,
        posterPath: _posterUrlCtrl.text,
        tags: _draftTags,
        silent: silent,
        pageView: _pageView,
        syncBodyFromEditor: _syncBodyFromEditor,
        entity: _entity,
        journal: _journal,
        catalog: widget.userCatalog,
        vaultStore: _entityDetailVaultStore,
        currentPageView: _pageView,
        beforePersist: () => EntityDetailSaveOps.warnWorkTitleTagsIfNeeded(
          context: context,
          catalog: widget.userCatalog,
          tags: _draftTags,
        ),
      );
      if (!mounted) return;
      switch (result) {
        case EntityDetailSaveOrchestrationSkipped():
          return;
        case EntityDetailSaveOrchestrationBlocked(:final message):
          _showSnack(message);
        case EntityDetailSaveOrchestrationFailed(:final error):
          final msg = EntityDetailSavePrepareOps.saveFailedMessage(
            error: error,
            silent: silent,
          );
          if (msg != null) _showSnack(msg);
        case EntityDetailSaveOrchestrationSucceeded result:
          if (result.usedPlaceholder && !silent) {
            _bodyCtrl.text = result.body;
          }
          if (result.patch.bodyForPlaceholder != null && !silent) {
            _bodyCtrl.text = result.patch.bodyForPlaceholder!;
          }
          final patch = result.patch;
          setState(() {
            _entity = patch.entity;
            _journal = patch.journal;
            _item = patch.item;
            _preview = patch.preview;
            _draftTags = patch.draftTags;
            _fileCtrl.text = patch.serializedFile;
            _lastSavedAt = patch.savedAt;
            if (patch.pageView != null) {
              _pageView = patch.pageView!;
            }
          });
          widget.onDirtyChanged(false);
          widget.onSaved(patch.entity, patch.journal, silent: silent);
          _refreshRecordLinks();
          _connections.refreshDiskMtime(_journal?.storagePath);
          if (!silent) {
            _showSnack(EntityDetailArchiveOps.saveSuccessMessage(patch.entity));
          }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final result = await EntityDetailDeleteFlowOps.run(
      context: context,
      isSaving: _isSaving,
      journal: _journal,
      title: _entity.title,
      catalog: widget.userCatalog,
      vaultStore: _entityDetailVaultStore,
      onConfirmed: () async {
        if (!mounted) return;
        setState(() => _suppressPersist = true);
        widget.onDirtyChanged(false);
      },
    );
    if (!mounted) return;

    switch (result) {
      case EntityDetailDeleteBlocked(:final message):
        if (message.isNotEmpty) _showSnack(message);
      case EntityDetailDeleteCancelled():
        return;
      case EntityDetailDeleteSucceeded(:final title):
        _showSnack('「$title」 journal을 삭제했습니다.');
        widget.onDeleted();
      case EntityDetailDeleteFailed(:final message):
        setState(() => _suppressPersist = false);
        _showSnack(message);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _exportHtml() async {
    final storagePath = _journal?.storagePath;
    if (storagePath == null || storagePath.isEmpty) {
      _showSnack('HTML보내기 전에 journal을 저장해 주세요.');
      return;
    }

    final item = _buildEntityItem(_entity, _journal);
    item.filePath = storagePath;
    item.bodyRaw = _bodyCtrl.text;
    item.posterPath = _posterUrlCtrl.text.trim().isNotEmpty
        ? _posterUrlCtrl.text.trim()
        : item.posterPath;

    final result = await EntityDetailSanctumOps.exportHtml(
      item: item,
      bodyMarkdown: _bodyCtrl.text,
      titleOverride: _entity.title,
    );
    if (!mounted) return;
    _showSnack(EntityDetailSanctumOps.htmlExportSnackMessage(result));
  }

  Future<void> _openPosterCorrection() async {
    final selected = await EntityDetailSanctumOps.pickPosterUrl(
      context: context,
      title: _entity.title,
      category: _entity.subtype,
    );
    if (selected != null) {
      final resolved = await PosterUrlLocalizer.applyWithSnackBar(
        selected,
        showSnack: _showSnack,
      );
      setState(() {
        _posterUrlCtrl.text = resolved;
        _updatePreview();
      });
      _markDirty();
    }
  }

  Future<void> _handleAddToLibrary() async {
    await EntityDetailLibraryOps.addToLibrary(
      entity: _entity,
      onAddToLibrary: widget.onAddToLibrary,
      vaultConnected: WorkbenchVault.port.vaultPath != null,
      hasJournal: () => EntityDetailArchiveOps.hasJournal(_journal),
      saveJournal: () => _saveJournal(),
      showSnack: _showSnack,
    );
  }
}
