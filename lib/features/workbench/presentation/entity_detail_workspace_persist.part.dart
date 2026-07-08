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
    _scheduleRecoveryDraftSave();
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

  void _scheduleRecoveryDraftSave() {
    _recoveryDraftTimer?.cancel();
    if (_suppressPersist) return;
    _recoveryDraftTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_saveRecoveryDraftNow());
    });
  }

  Future<void> _saveRecoveryDraftNow() async {
    final vaultPath = WorkbenchVault.port.vaultPath;
    if (_suppressPersist || vaultPath == null || vaultPath.isEmpty) return;
    try {
      await _recoveryDraftStore.save(
        vaultPath: vaultPath,
        draft: WorkbenchRecoveryDraft(
          kind: WorkbenchRecoveryRecordKind.entity,
          recordId: widget.tabId,
          updatedAt: DateTime.now().toUtc(),
          title: _entity.title,
          posterPath: _posterUrlCtrl.text.trim().isNotEmpty
              ? _posterUrlCtrl.text.trim()
              : null,
          bodyText: _bodyCtrl.text,
          fileText: _fileCtrl.text,
          tags: List<String>.from(_draftTags),
          pageView: _pageView.name,
        ),
      );
    } catch (_) {}
  }

  Future<void> _deleteRecoveryDraft() async {
    final vaultPath = WorkbenchVault.port.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return;
    try {
      await _recoveryDraftStore.delete(
        vaultPath: vaultPath,
        kind: WorkbenchRecoveryRecordKind.entity,
        recordId: widget.tabId,
      );
    } catch (_) {}
  }

  Future<void> _maybeOfferRecoveryDraft() async {
    if (_recoveryPromptShown || _suppressPersist) return;
    final vaultPath = WorkbenchVault.port.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return;
    final draft = await _recoveryDraftStore.load(
      vaultPath: vaultPath,
      kind: WorkbenchRecoveryRecordKind.entity,
      recordId: widget.tabId,
    );
    if (!mounted || draft == null) return;
    if (draft.hasSameText(body: _bodyCtrl.text, file: _fileCtrl.text)) {
      await _deleteRecoveryDraft();
      return;
    }
    _recoveryPromptShown = true;
    final l10n = lookupAppL10n(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.draftRecoveryAvailable ?? '임시 저장본이 있습니다.'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: l10n?.trashRestore ?? '복구',
          onPressed: () => _restoreRecoveryDraft(draft),
        ),
      ),
    );
  }

  void _restoreRecoveryDraft(WorkbenchRecoveryDraft draft) {
    if (!mounted) return;
    setState(() {
      _posterUrlCtrl.text = draft.posterPath ?? '';
      _bodyCtrl.text = draft.bodyText;
      _fileCtrl.text = draft.fileText;
      _draftTags = List<String>.from(draft.tags);
      _pageView = SanctumPageView.values.firstWhere(
        (view) => view.name == draft.pageView,
        orElse: () => _pageView,
      );
      _preview = EntityDetailDraftOps.buildPreviewItem(
        entity: _entity,
        journal: _journal,
        posterPath: _posterUrlCtrl.text,
        tags: _draftTags,
        bodyRaw: _bodyCtrl.text,
      );
    });
    widget.onDirtyChanged(true);
    _scheduleAutoSave();
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
        context,
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
            context,
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
          final successMessage = !silent
              ? EntityDetailArchiveOps.saveSuccessMessage(context, patch.entity)
              : null;
          await _deleteRecoveryDraft();
          widget.onSaved(patch.entity, patch.journal, silent: silent);
          _refreshRecordLinks();
          _connections.refreshDiskMtime(_journal?.storagePath);
          if (successMessage != null) {
            _showSnack(successMessage);
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

    final l10n = lookupAppL10n(context);
    switch (result) {
      case EntityDetailDeleteBlocked(:final message):
        if (message.isNotEmpty) _showSnack(message);
      case EntityDetailDeleteCancelled():
        return;
      case EntityDetailDeleteSucceeded(:final title):
        _showSnack(l10n?.journalDeleted(title) ?? '「$title」 journal을 삭제했습니다.');
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
    final l10n = lookupAppL10n(context);
    if (storagePath == null || storagePath.isEmpty) {
      _showSnack(l10n?.journalSaveBeforeHtml ?? 'HTML보내기 전에 journal을 저장해 주세요.');
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
      l10n: l10n,
    );
    if (!mounted) return;
    _showSnack(EntityDetailSanctumOps.htmlExportSnackMessage(result, l10n));
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
