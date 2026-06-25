import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/archiving/record_link.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/file_service.dart';
import '../../../widgets/sanctum_page_panel.dart';
import '../../../core/archiving/entity_anchor.dart';
import 'entity_detail_archive_ops.dart';
import 'entity_detail_connections_coordinator.dart';
import 'entity_detail_save_ops.dart';
import 'entity_detail_delete_ops.dart';
import 'entity_detail_draft_ops.dart';
import 'entity_detail_library_ops.dart';
import 'entity_detail_link_pick_ops.dart';
import 'entity_detail_sanctum_ops.dart';
import 'entity_detail_save_ui_patch.dart';
import 'workbench_workspace_record_nav.dart';
import 'workbench_autosave_scheduler.dart';
import 'workbench_linked_record_ops.dart';
import 'workbench_vault_disk_ops.dart';
import 'workbench_vault_reload_messages.dart';
import 'widgets/entity_detail_workspace_body.dart';
import 'widgets/workbench_save_shortcuts.dart';

/// Entity collectible — Workbench 3·4열 (Phase 6).
class EntityDetailWorkspace extends StatefulWidget {
  const EntityDetailWorkspace({
    super.key,
    required this.entity,
    required this.journal,
    required this.tabId,
    this.isDirty = false,
    required this.infoPanelWidth,
    this.infoPanelLocked = false,
    this.userCatalog,
    this.linkIndex,
    this.vaultItems = const [],
    required this.onSaved,
    required this.onDeleted,
    required this.onDirtyChanged,
    required this.onBindSave,
    this.onAddToLibrary,
    this.onPreserveDraft,
    this.onInfoWidthChanged,
    this.onToggleInfoLock,
    this.onWikiLinkTap,
    this.onRequestEntityLink,
    this.onClose,
    this.onGoKnowledgeGraph,
    this.onRecordOpenWork,
    this.onRecordOpenEntity,
    this.pendingEntityLinkType,
    this.pendingEntityLinkEntityId,
    this.pendingEntityWorkLinkPick = false,
    this.onPendingEntityLinkHandled,
  });

  final UserCatalogEntity entity;
  final EntityJournalEntry? journal;
  final String tabId;
  final bool isDirty;
  final double infoPanelWidth;
  final bool infoPanelLocked;
  final UserCatalogPort? userCatalog;
  final RecordLinkPort? linkIndex;
  final List<AkashaItem> vaultItems;
  final void Function(
    UserCatalogEntity entity,
    EntityJournalEntry? journal, {
    required bool silent,
  }) onSaved;
  final VoidCallback onDeleted;
  final ValueChanged<bool> onDirtyChanged;
  final void Function(Future<void> Function()? save) onBindSave;
  final void Function(
    String tabId,
    UserCatalogEntity entity,
    EntityJournalEntry? journal,
    List<String> tags,
    String body,
  )? onPreserveDraft;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )? onRequestEntityLink;
  final Future<void> Function(UserCatalogEntity entity)? onAddToLibrary;
  final VoidCallback? onClose;
  final VoidCallback? onGoKnowledgeGraph;
  final void Function(AkashaItem item)? onRecordOpenWork;
  final Future<void> Function(UserCatalogEntity entity)? onRecordOpenEntity;
  final EntityAnchorType? pendingEntityLinkType;
  final String? pendingEntityLinkEntityId;
  final bool pendingEntityWorkLinkPick;
  final VoidCallback? onPendingEntityLinkHandled;

  @override
  State<EntityDetailWorkspace> createState() => _EntityDetailWorkspaceState();
}

class _EntityDetailWorkspaceState extends State<EntityDetailWorkspace> {
  static final _store = EntityVaultStore();

  late UserCatalogEntity _entity;
  EntityJournalEntry? _journal;
  late EntityItem _item;
  late EntityItem _preview;
  late List<String> _draftTags;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _fileCtrl;
  late final TextEditingController _posterUrlCtrl;
  SanctumPageView _pageView = SanctumPageView.preview;
  bool _isSaving = false;
  bool _suppressPersist = false;
  DateTime? _lastSavedAt;
  final WorkbenchAutosaveScheduler _autosave = WorkbenchAutosaveScheduler();
  StreamSubscription<void>? _vaultSub;
  late final EntityDetailConnectionsCoordinator _connections;

  bool get _externalChangePending => _connections.externalChangePending;

  void _refreshRecordLinks() {
    _connections.refreshAll(
      entity: _entity,
      journal: _journal,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }

  EntityItem _buildEntityItem(UserCatalogEntity entity, EntityJournalEntry? journal) =>
      EntityDetailDraftOps.buildEntityItem(entity, journal);

  void _applySnapshot(EntityDetailWorkspaceSnapshot snapshot) {
    _entity = snapshot.entity;
    _journal = snapshot.journal;
    _item = snapshot.item;
    _preview = snapshot.preview;
    _draftTags = snapshot.draftTags;
    _pageView = snapshot.pageView;
    _bodyCtrl.text = snapshot.bodyText;
    _posterUrlCtrl.text = snapshot.posterText;
    _fileCtrl.text = snapshot.fileText;
  }

  void _updatePreview() {
    setState(() {
      _preview = EntityDetailDraftOps.buildPreviewItem(
        entity: _entity,
        journal: _journal,
        posterPath: _posterUrlCtrl.text,
        tags: _draftTags,
        bodyRaw: _bodyCtrl.text,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _connections = EntityDetailConnectionsCoordinator(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _entity = widget.entity;
    _journal = widget.journal;
    final snapshot = EntityDetailWorkspaceSnapshot.fromProps(
      entity: _entity,
      journal: _journal,
    );
    _item = snapshot.item;
    _preview = snapshot.preview;
    _draftTags = snapshot.draftTags;
    _bodyCtrl = TextEditingController(text: snapshot.bodyText);
    _posterUrlCtrl = TextEditingController(text: snapshot.posterText);
    _posterUrlCtrl.addListener(() {
      _updatePreview();
    });
    _fileCtrl = TextEditingController(text: snapshot.fileText);
    _pageView = snapshot.pageView;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
    _vaultSub = AkashaFileService().onVaultUpdated.listen((_) {
      _onVaultDiskChanged();
    });
    _connections.refreshDiskMtime(_journal?.storagePath);
    _refreshRecordLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRunPendingEntityLinkPick();
    });
  }

  Future<void> _onVaultDiskChanged() async {
    if (!mounted) return;
    await WorkbenchVaultDiskOps.handleChange(
      action: _connections.evaluateVaultDiskChange(
        filePath: _journal?.storagePath,
        isSaving: _isSaving,
        isDirty: widget.isDirty,
      ),
      mounted: mounted,
      promptRebuild: () => setState(() {}),
      reloadFromDisk: _reloadFromDisk,
    );
  }

  void _applyJournalFromEntry(EntityJournalEntry entry) {
    _applySnapshot(
      EntityDetailWorkspaceSnapshot.fromJournalEntry(
        entity: _entity,
        entry: entry,
        pageView: _pageView,
      ),
    );
    _connections.refreshDiskMtime(_journal?.storagePath);
    _connections.loadLinkNeighbors(
      entity: _entity,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }

  Future<void> _reloadFromDisk({bool silent = false}) async {
    try {
      final parsed = await _connections.reloadJournalFromDisk(
        storagePath: _journal?.storagePath,
      );
      if (parsed == null) {
        throw StateError('journal parse failed');
      }
      if (!mounted) return;
      _applyJournalFromEntry(parsed);
      widget.onDirtyChanged(false);
      widget.onSaved(_entity, parsed, silent: true);
      if (!silent && mounted) {
        _showSnack(WorkbenchVaultReloadMessages.entitySuccess);
      }
    } catch (e) {
      if (mounted && !silent) {
        _showSnack(WorkbenchVaultReloadMessages.entityFailure(e));
      }
    }
  }

  void _dismissExternalChange() {
    _connections.dismissExternalChange(_journal?.storagePath);
  }

  Future<void> _maybeRunPendingEntityLinkPick() async {
    if (!mounted) return;
    await EntityDetailLinkPickOps.runPendingPick(
      context: context,
      pendingEntityId: widget.pendingEntityLinkEntityId,
      pendingWorkLinkPick: widget.pendingEntityWorkLinkPick,
      pendingEntityLinkType: widget.pendingEntityLinkType,
      currentEntityId: _entity.entityId,
      catalog: widget.userCatalog,
      item: _item,
      vaultItems: widget.vaultItems,
      bodyCtrl: _bodyCtrl,
      showBodyView: (view) => setState(() => _pageView = view),
      markDirty: _markDirty,
      reloadLinkNeighbors: () => _connections.loadLinkNeighbors(
        entity: _entity,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      ),
      requestWorkLink: _requestWorkLink,
      onPendingHandled: widget.onPendingEntityLinkHandled,
    );
  }

  Future<void> _requestEntityLinkForType(EntityAnchorType type) async {
    final catalog = widget.userCatalog;
    if (catalog == null || !mounted) return;

    setState(() => _pageView = SanctumPageView.body);

    final picked = await EntityDetailLinkPickOps.requestEntityLinkForType(
      context: context,
      catalog: catalog,
      type: type,
      workContext: _item,
      vaultItems: widget.vaultItems,
    );
    if (!mounted || picked == null) return;
    await _applyWikiLinkSelection(picked);
  }

  Future<void> _requestWorkLink() async {
    if (!mounted) return;

    setState(() => _pageView = SanctumPageView.body);

    final picked = await EntityDetailLinkPickOps.requestWorkLink(
      context: context,
      vaultItems: widget.vaultItems,
    );
    if (!mounted || picked == null) return;
    await _applyWikiLinkSelection(picked);
  }

  Future<void> _applyWikiLinkSelection(EntityLinkSelection picked) async {
    await EntityDetailLinkPickOps.applySelection(
      picked: picked,
      bodyCtrl: _bodyCtrl,
      markDirty: _markDirty,
      reloadLinkNeighbors: () => _connections.loadLinkNeighbors(
        entity: _entity,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      ),
    );
  }

  void _openLinkedEntity(UserCatalogEntity entity) {
    WorkbenchLinkedRecordOps.openLinkedEntity(
      entity: entity,
      onRecordOpenEntity: widget.onRecordOpenEntity,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

  void _openLinkedWork(AkashaItem work) {
    WorkbenchLinkedRecordOps.openLinkedWork(
      work: work,
      onRecordOpenWork: widget.onRecordOpenWork,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

  void _focusSanctumForLinks() {
    setState(() => _pageView = SanctumPageView.body);
  }

  @override
  void didUpdateWidget(EntityDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      final snapshot = EntityDetailWorkspaceSnapshot.fromProps(
        entity: widget.entity,
        journal: widget.journal,
      );
      setState(() {
        _applySnapshot(snapshot);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
      _refreshRecordLinks();
      _connections.refreshDiskMtime(_journal?.storagePath);
      return;
    }
    if (!widget.isDirty &&
        (oldWidget.entity.entityId != widget.entity.entityId ||
            oldWidget.journal?.storagePath != widget.journal?.storagePath)) {
      _entity = widget.entity;
      _journal = widget.journal;
      _item = _buildEntityItem(_entity, _journal);
      _preview = _item;
      _draftTags = List<String>.from(_journal?.tags ?? _entity.tags);
      _bodyCtrl.text = _journal?.body ?? '';
      _posterUrlCtrl.text = _journal?.posterPath ?? _entity.posterPath ?? '';
      _fileCtrl.text = _serializeFile();
      _connections.loadIncoming(
        entity: _entity,
        journal: _journal,
        linkIndex: widget.linkIndex,
      );
      _connections.loadSameDay(entity: _entity, journal: _journal);
      _connections.loadLinkNeighbors(
        entity: _entity,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      );
      _connections.refreshDiskMtime(_journal?.storagePath);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
  }

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

  void _scheduleAutoSave() {
    _autosave.schedule(
      persistEnabled: !_suppressPersist,
      isDirty: () => widget.isDirty,
      isActive: () => mounted,
      save: () => _saveJournal(silent: true),
    );
  }

  @override
  void deactivate() {
    _autosave.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    _autosave.dispose();
    if (!_suppressPersist && widget.isDirty) {
      if (_pageView == SanctumPageView.file) {
        _syncBodyFromEditor();
      }
      widget.onPreserveDraft?.call(
        widget.tabId,
        _entity,
        _journal,
        _draftTags,
        _bodyCtrl.text,
      );
    }
    widget.onBindSave(null);
    _vaultSub?.cancel();
    _bodyCtrl.dispose();
    _fileCtrl.dispose();
    _posterUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveJournal({bool silent = false}) async {
    if (EntityDetailSaveOps.shouldSkip(
      suppressPersist: _suppressPersist,
      isSaving: _isSaving,
    )) {
      return;
    }

    final prepare = EntityDetailSavePrepareOps.prepare(
      rawBody: _bodyCtrl.text,
      posterPath: _posterUrlCtrl.text,
      tags: _draftTags,
      silent: silent,
      pageView: _pageView,
      syncBodyFromEditor: _syncBodyFromEditor,
    );
    switch (prepare) {
      case EntityDetailSaveBlocked(:final message):
        if (mounted) _showSnack(message);
        return;
      case EntityDetailSaveReady(:final body, :final usedPlaceholder):
        if (usedPlaceholder && !silent) {
          _bodyCtrl.text = body;
        }

        await EntityDetailSaveOps.warnWorkTitleTagsIfNeeded(
          context: context,
          catalog: widget.userCatalog,
          tags: _draftTags,
        );

        setState(() => _isSaving = true);
        try {
          final result = await EntityDetailSaveOps.run(
            entity: _entity,
            journal: _journal,
            tags: _draftTags,
            posterPath: _posterUrlCtrl.text,
            body: body,
            usedPlaceholder: usedPlaceholder,
            catalog: widget.userCatalog,
            vaultStore: _store,
          );
          if (!mounted) return;
          switch (result) {
            case EntityDetailSaveSkipped():
              return;
            case EntityDetailSaveFailed(:final error):
              final msg = EntityDetailSavePrepareOps.saveFailedMessage(
                error: error,
                silent: silent,
              );
              if (msg != null) _showSnack(msg);
            case EntityDetailSaveSucceeded result:
              final patch = EntityDetailSaveUiPatch.fromSucceeded(
                result: result,
                currentPageView: _pageView,
                silent: silent,
              );
              if (patch.bodyForPlaceholder != null && !silent) {
                _bodyCtrl.text = patch.bodyForPlaceholder!;
              }
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
  }

  Future<void> _openIncoming(String path) => WorkbenchWorkspaceRecordNav.openIncoming(
        context: context,
        path: path,
        vaultItems: widget.vaultItems,
        userCatalog: widget.userCatalog,
        onRecordOpenWork: widget.onRecordOpenWork,
        onRecordOpenEntity: widget.onRecordOpenEntity,
        onWikiLinkTap: widget.onWikiLinkTap,
      );

  Future<void> _openSameDay(SameDayRecordRef ref) =>
      WorkbenchWorkspaceRecordNav.openSameDay(
        context: context,
        ref: ref,
        vaultItems: widget.vaultItems,
        userCatalog: widget.userCatalog,
        onRecordOpenWork: widget.onRecordOpenWork,
        onRecordOpenEntity: widget.onRecordOpenEntity,
        onWikiLinkTap: widget.onWikiLinkTap,
      );

  Future<void> _confirmDelete() async {
    if (_journal == null || _isSaving) return;
    final confirmed = await EntityDetailDeleteOps.confirmDelete(
      context,
      title: _entity.title,
    );
    if (!confirmed || !mounted) return;

    final catalog = widget.userCatalog;
    if (catalog == null) {
      _showSnack('catalog 연결이 필요합니다.');
      return;
    }

    setState(() => _suppressPersist = true);
    widget.onDirtyChanged(false);

    final deleted = await EntityDetailDeleteOps.deleteJournal(
      entry: _journal!,
      userCatalog: catalog,
      vaultStore: _store,
    );
    if (!mounted) return;

    if (deleted) {
      _showSnack('「${_entity.title}」 journal을 삭제했습니다.');
      widget.onDeleted();
    } else {
      setState(() => _suppressPersist = false);
      _showSnack('삭제할 파일을 찾지 못했습니다.');
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
      setState(() {
        _posterUrlCtrl.text = selected;
        _updatePreview();
      });
      _markDirty();
    }
  }

  Future<void> _handleAddToLibrary() async {
    await EntityDetailLibraryOps.addToLibrary(
      entity: _entity,
      onAddToLibrary: widget.onAddToLibrary,
      vaultConnected: AkashaFileService().vaultPath != null,
      hasJournal: () => EntityDetailArchiveOps.hasJournal(_journal),
      saveJournal: () => _saveJournal(),
      showSnack: _showSnack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasJournal = EntityDetailArchiveOps.hasJournal(_journal);
    final saveLabel = hasJournal ? 'md 저장' : 'journal 생성';

    return WorkbenchSaveShortcuts(
      onSave: () => _saveJournal(),
      child: EntityDetailWorkspaceBody(
        entity: _entity,
        preview: _preview,
        hasJournal: hasJournal,
        saveLabel: saveLabel,
        infoPanelWidth: widget.infoPanelWidth,
        infoPanelLocked: widget.infoPanelLocked,
        posterUrlCtrl: _posterUrlCtrl,
        bodyCtrl: _bodyCtrl,
        fileCtrl: _fileCtrl,
        draftTags: _draftTags,
        pageView: _pageView,
        isDirty: widget.isDirty,
        isSaving: _isSaving,
        externalChangePending: _externalChangePending,
        lastSavedAt: _lastSavedAt,
        showAddToLibrary: widget.onAddToLibrary != null,
        linkNeighbors: _connections.linkNeighbors,
        loadingLinkNeighbors: _connections.loadingLinkNeighbors,
        loadingIncoming: _connections.loadingIncoming,
        incomingPaths: _connections.incomingPaths,
        staleLabelRecordCount: _connections.staleLabelRecordCount,
        loadingSameDay: _connections.loadingSameDay,
        sameDayRefs: _connections.sameDayRefs,
        onClose: widget.onClose,
        onGoKnowledgeGraph: widget.onGoKnowledgeGraph,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        journalStoragePath: _journal?.storagePath,
        onWikiLinkTap: widget.onWikiLinkTap,
        onRequestEntityLink: widget.onRequestEntityLink,
        onInfoWidthChanged: widget.onInfoWidthChanged,
        onToggleInfoLock: widget.onToggleInfoLock,
        onPosterTap: _openPosterCorrection,
        onFocusSanctum: _focusSanctumForLinks,
        onViewChanged: _onPageViewChanged,
        onReloadFromDisk: () => _reloadFromDisk(),
        onDismissExternalChange: _dismissExternalChange,
        onBodyChanged: _markDirty,
        onFileChanged: _markDirty,
        onOpenFileView: _refreshFileEditor,
        onSave: () => _saveJournal(),
        onExportHtml: _exportHtml,
        onAddToLibrary: _handleAddToLibrary,
        onDeleteArchive: hasJournal ? _confirmDelete : null,
        onOpenLinkedEntity: _openLinkedEntity,
        onOpenLinkedWork: _openLinkedWork,
        onAddEntityLink: widget.userCatalog != null
            ? _requestEntityLinkForType
            : null,
        onAddWorkLink: widget.userCatalog != null ? _requestWorkLink : null,
        onRefreshIncoming: () => _connections.loadIncoming(
          entity: _entity,
          journal: _journal,
          linkIndex: widget.linkIndex,
        ),
        onOpenIncoming: _openIncoming,
        onOpenSameDay: _openSameDay,
        onDraftTagsChanged: (tags) {
          setState(() => _draftTags = tags);
          _updatePreview();
          _markDirty();
        },
      ),
    );
  }
}
