part of 'work_detail_workspace.dart';

mixin _WorkDetailWorkspacePersist on _WorkDetailWorkspaceStateBase {
  void _bindSaveHandler() => widget.onBindSave?.call(_saveArchive);

  void _onPageViewChanged(SanctumPageView next) {
    _draft.handlePageViewChanging(current: _pageView, next: next);
    setState(() => _pageView = next);
  }

  void _markDirty() {
    final wasDirty = widget.isDirty;
    widget.onDirtyChanged(true);
    if (!wasDirty && _pageView == SanctumPageView.preview) {
      setState(() {});
    }
    _scheduleAutoSave();
  }

  void _onDraftRatingChanged(double v) => setState(() => _draftRating = v);

  void _onDraftWorkStatusChanged(String v) =>
      setState(() => _draftWorkStatus = v);

  void _onDraftMyStatusChanged(String v) => setState(() => _draftMyStatus = v);

  void _onDraftHallOfFameChanged(bool v) =>
      setState(() => _draftHallOfFame = v);

  void _onDraftTagsChanged(List<String> tags) =>
      setState(() => _draftTags = tags);

  void _scheduleAutoSave() {
    _autosave.schedule(
      persistEnabled: !_suppressPersist,
      isDirty: () => widget.isDirty,
      isActive: () => mounted,
      save: () => _saveArchive(silent: true, switchToPreview: false),
      blockOnExternalChange: true,
      externalChangePending: () => _externalChangePending,
    );
  }

  void _flushAutoSaveIfNeeded() {
    _autosave.flushIfNeeded(
      persistEnabled: !_suppressPersist,
      isDirty: () => widget.isDirty,
      isSaving: _isSaving,
      save: () => _saveArchive(silent: true, switchToPreview: false),
      blockOnExternalChange: true,
      externalChangePending: () => _externalChangePending,
    );
  }

  bool get _isArchivedInVault => WorkDetailArchiveOps.isArchivedInVault(_item);

  bool get _isArchived => WorkDetailArchiveOps.isArchived(_item);

  void _applySaveUiPatch(WorkDetailSaveUiPatch patch) {
    _item = patch.item;
    patch.applyToControllers(
      titleCtrl: _titleCtrl,
      posterUrlCtrl: _posterUrlCtrl,
      bodyCtrl: _bodyCtrl,
      onPageView: (view) => _pageView = view,
    );
    _draftTags = patch.draftTags;
    _registryTags = patch.registryTags;
    _draftRating = patch.draftRating;
    _draftWorkStatus = patch.draftWorkStatus;
    _draftMyStatus = patch.draftMyStatus;
    _draftHallOfFame = patch.draftHallOfFame;
    _draft.refreshFullFileEditor();
    _lastSavedAt = patch.savedAt;
    _connections.refreshDiskMtime(_item.filePath);
  }

  Future<void> _openPosterCorrection() async {
    await WorkDetailSanctumWorkspaceOps.openPosterCorrection(
      context: context,
      item: _item,
      posterUrlCtrl: _posterUrlCtrl,
      onApplied: () => setState(_draft.applyDraft),
      onDirty: () => widget.onDirtyChanged(true),
      scheduleAutoSave: _scheduleAutoSave,
    );
  }

  void _resetToDefaults() {
    WorkDetailSanctumWorkspaceOps.resetToDefaults(
      item: _item,
      titleCtrl: _titleCtrl,
      posterUrlCtrl: _posterUrlCtrl,
      bodyCtrl: _bodyCtrl,
      onTags: (tags, registry) {
        _draftTags = tags;
        _registryTags = registry;
      },
      onDraftFields: (rating, workStatus, myStatus, hall) {
        _draftRating = rating;
        _draftWorkStatus = workStatus;
        _draftMyStatus = myStatus;
        _draftHallOfFame = hall;
      },
      markDirty: _markDirty,
      showSnack: _showSnack,
    );
  }

  Future<void> _handleAddToLibrary() async {
    await WorkDetailLibraryOps.addToLibrary(
      item: _item,
      onAddToLibrary: widget.onAddToLibrary,
      vaultConnected: AkashaFileService().vaultPath != null,
      isArchived: () => _isArchived,
      saveArchive: () => _saveArchive(),
      showSnack: _showSnack,
    );
  }

  Future<void> _saveArchive({
    bool silent = false,
    bool switchToPreview = true,
  }) async {
    if (WorkDetailSaveOps.shouldSkip(
      suppressPersist: _suppressPersist,
      isSaving: _isSaving,
    )) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await WorkDetailSaveOrchestrator.run(
        suppressPersist: _suppressPersist,
        isSaving: false,
        cancelAutosave: _autosave.cancel,
        draft: _draft.buildSaveDraft(),
        pageView: _pageView,
        contentAtSave: _pageView == SanctumPageView.file
            ? _fileCtrl.text
            : _bodyCtrl.text,
        currentFileContent: _fileCtrl.text,
        currentBodyContent: _bodyCtrl.text,
        currentPageView: _pageView,
        silent: silent,
        switchToPreview: switchToPreview,
      );
      if (!mounted) return;
      switch (result) {
        case WorkDetailSaveOrchestrationSkipped():
          return;
        case WorkDetailSaveOrchestrationFailed(:final error):
          if (!silent) _showSnack('저장 실패: $error');
        case WorkDetailSaveOrchestrationSucceeded result:
          setState(() => _applySaveUiPatch(result.patch));
          if (!result.stillDirty) {
            widget.onDirtyChanged(false);
          } else {
            _scheduleAutoSave();
          }
          widget.onSaved(_item, silent: silent, dirty: result.stillDirty);
          _refreshRecordLinks();
          if (!silent) {
            _showSnack(WorkDetailArchiveOps.saveSuccessMessage(result.saved));
          }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _applyBodyTemplate(SanctumBodyTemplate template) async {
    final message = await WorkDetailSanctumWorkspaceOps.applyBodyTemplate(
      context: context,
      template: template,
      bodyCtrl: _bodyCtrl,
      item: _item,
      sectionEditor: _sectionEditorKey.currentState,
      markDirty: _markDirty,
    );
    if (message != null && mounted) {
      setState(() {});
      _showSnack(message);
    }
  }

  Future<void> _exportHtml() async {
    if (!mounted) return;
    await WorkDetailSanctumWorkspaceOps.exportHtml(
      isArchivedInVault: _isArchivedInVault,
      item: _item,
      titleCtrl: _titleCtrl,
      bodyCtrl: _bodyCtrl,
      showSnack: _showSnack,
    );
  }

  Future<void> _confirmDelete() async {
    final displayTitle = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : _item.title;

    final result = await WorkDetailDeleteFlowOps.run(
      context: context,
      isSaving: _isSaving,
      isArchivedInVault: _isArchivedInVault,
      displayTitle: displayTitle,
      hasUnsavedChanges: widget.isDirty,
      item: _item,
      waitWhileSaving: () async {
        _autosave.cancel();
        while (_isSaving && mounted) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      },
      onConfirmed: () async {
        if (!mounted) return;
        setState(() => _suppressPersist = true);
        widget.onDirtyChanged(false);
      },
    );
    if (!mounted) return;

    WorkDetailDeleteFlowOps.handleResult(
      result: result,
      showSnack: _showSnack,
      onDeleted: widget.onDeleted,
      restorePersist: () => setState(() => _suppressPersist = false),
    );
  }
}
