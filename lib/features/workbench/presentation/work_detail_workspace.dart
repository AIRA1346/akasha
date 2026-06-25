import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/archiving/record_link.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/link_candidate_service.dart';
import '../../../services/file_service.dart';
import '../../../services/sanctum_body_templates.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'work_detail_save_ops.dart';
import 'work_detail_draft_ops.dart';
import 'work_detail_draft_bundle.dart';
import 'work_detail_link_pick_ops.dart';
import 'work_detail_library_ops.dart';
import 'work_detail_archive_ops.dart';
import 'work_detail_connections_coordinator.dart';
import 'work_detail_item_hydration.dart';
import 'work_detail_save_orchestrator.dart';
import 'work_detail_save_ui_patch.dart';
import 'work_detail_delete_flow_ops.dart';
import 'work_detail_sanctum_workspace_ops.dart';
import 'workbench_workspace_record_nav.dart';
import 'workbench_autosave_scheduler.dart';
import 'workbench_linked_record_ops.dart';
import 'workbench_vault_disk_ops.dart';
import 'workbench_vault_reload_flow.dart';
import 'workbench_vault_reload_messages.dart';
import 'widgets/workbench_save_shortcuts.dart';
import 'widgets/work_detail_workspace_body.dart';
import 'widgets/work_sanctum_section_editor.dart';

part 'work_detail_workspace_ui.part.dart';

/// 3열 작품정보 + 4열 Sanctum md (워크벤치 작업 뷰)
class WorkDetailWorkspace extends StatefulWidget {
  final AkashaItem item;
  final String tabId;
  final bool isDirty;
  final double infoPanelWidth;
  final bool infoPanelLocked;
  final UserCatalogPort? userCatalog;
  final RecordLinkPort? linkIndex;
  final List<AkashaItem> vaultItems;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final void Function(AkashaItem saved, {required bool silent, bool dirty})
      onSaved;
  final VoidCallback onDeleted;
  final ValueChanged<bool> onDirtyChanged;
  final Future<void> Function(AkashaItem item)? onAddToLibrary;
  final void Function(Future<void> Function()? save)? onBindSave;
  final void Function(String tabId, AkashaItem draft)? onPreserveDraft;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )? onRequestEntityLink;
  final VoidCallback? onClose;
  final VoidCallback? onGoKnowledgeGraph;
  final EntityAnchorType? pendingEntityLinkType;
  final String? pendingEntityLinkWorkId;
  final LinkCandidate? pendingEntityLinkCandidate;
  final bool pendingWorkLinkPick;
  final VoidCallback? onPendingEntityLinkHandled;
  final void Function(AkashaItem item)? onRecordOpenWork;
  final Future<void> Function(UserCatalogEntity entity)? onRecordOpenEntity;

  const WorkDetailWorkspace({
    super.key,
    required this.item,
    required this.tabId,
    this.isDirty = false,
    required this.infoPanelWidth,
    this.infoPanelLocked = false,
    this.userCatalog,
    this.linkIndex,
    this.vaultItems = const [],
    this.onInfoWidthChanged,
    this.onToggleInfoLock,
    required this.onSaved,
    required this.onDeleted,
    required this.onDirtyChanged,
    this.onAddToLibrary,
    this.onBindSave,
    this.onPreserveDraft,
    this.onWikiLinkTap,
    this.onRequestEntityLink,
    this.onClose,
    this.onGoKnowledgeGraph,
    this.pendingEntityLinkType,
    this.pendingEntityLinkWorkId,
    this.pendingEntityLinkCandidate,
    this.pendingWorkLinkPick = false,
    this.onPendingEntityLinkHandled,
    this.onRecordOpenWork,
    this.onRecordOpenEntity,
  });

  @override
  State<WorkDetailWorkspace> createState() => _WorkDetailWorkspaceState();
}

class _WorkDetailWorkspaceState extends State<WorkDetailWorkspace> {
  late AkashaItem _item;
  bool _isSaving = false;

  late double _draftRating;
  late String _draftWorkStatus;
  late String _draftMyStatus;
  late bool _draftHallOfFame;
  List<String> _draftTags = [];
  Set<String> _registryTags = {};

  late TextEditingController _titleCtrl;
  late TextEditingController _posterUrlCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _fileCtrl;
  SanctumPageView _pageView = SanctumPageView.preview;

  StreamSubscription<void>? _vaultSub;
  late final WorkDetailConnectionsCoordinator _connections;
  DateTime? _lastSavedAt;
  final WorkbenchAutosaveScheduler _autosave = WorkbenchAutosaveScheduler();
  bool _suppressPersist = false;

  final GlobalKey<WorkSanctumSectionEditorState> _sectionEditorKey =
      GlobalKey<WorkSanctumSectionEditorState>();

  bool get _externalChangePending => _connections.externalChangePending;

  WorkDetailDraftBundle get _draft => WorkDetailDraftBundle(
        item: _item,
        pageView: _pageView,
        titleCtrl: _titleCtrl,
        bodyCtrl: _bodyCtrl,
        fileCtrl: _fileCtrl,
        posterUrlCtrl: _posterUrlCtrl,
        draftRating: _draftRating,
        draftWorkStatus: _draftWorkStatus,
        draftMyStatus: _draftMyStatus,
        draftHallOfFame: _draftHallOfFame,
        draftTags: _draftTags,
      );

  void _refreshRecordLinks() {
    _connections.refreshAll(
      work: _item,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }

  @override
  void initState() {
    super.initState();
    _connections = WorkDetailConnectionsCoordinator(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _titleCtrl = TextEditingController();
    _posterUrlCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _fileCtrl = TextEditingController();
    _applyItem(widget.item, resetPageView: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
    _vaultSub = AkashaFileService().onVaultUpdated.listen((_) {
      _onVaultDiskChanged();
    });
    _connections.refreshDiskMtime(_item.filePath);
    _refreshRecordLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRunPendingEntityLinkPick();
    });
  }

  Future<void> _maybeRunPendingEntityLinkPick() async {
    if (!mounted) return;
    await WorkDetailLinkPickOps.runPendingPick(
      context: context,
      pendingWorkId: widget.pendingEntityLinkWorkId,
      pendingWorkLinkPick: widget.pendingWorkLinkPick,
      pendingEntityLinkType: widget.pendingEntityLinkType,
      preselected: widget.pendingEntityLinkCandidate,
      currentWorkId: _item.workId,
      catalog: widget.userCatalog,
      item: _item,
      vaultItems: widget.vaultItems,
      showBodyView: (view) => setState(() => _pageView = view),
      requestWorkLink: _requestWorkLink,
      applySelection: _applyWikiLinkSelection,
      onPendingHandled: widget.onPendingEntityLinkHandled,
    );
  }

  void _openLinkedEntity(UserCatalogEntity entity) {
    WorkbenchLinkedRecordOps.openLinkedEntity(
      entity: entity,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

  void _openLinkedWork(AkashaItem work) {
    WorkbenchLinkedRecordOps.openLinkedWork(
      work: work,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

  void _bindSaveHandler() => widget.onBindSave?.call(_saveArchive);

  void _applyItem(
    AkashaItem item, {
    required bool resetPageView,
    bool preserveBodyEditor = false,
  }) {
    WorkDetailItemHydration.fromItem(
      item,
      resetPageView: resetPageView,
      preserveBodyEditor: preserveBodyEditor,
      currentBodyText: _bodyCtrl.text,
      currentPageView: _pageView,
    ).writeTo(
      setItem: (next) => _item = next,
      titleCtrl: _titleCtrl,
      posterUrlCtrl: _posterUrlCtrl,
      bodyCtrl: _bodyCtrl,
      setPageView: (view) => _pageView = view,
      setDraftState: (tags, registry, rating, workStatus, myStatus, hall) {
        _draftTags = tags;
        _registryTags = registry;
        _draftRating = rating;
        _draftWorkStatus = workStatus;
        _draftMyStatus = myStatus;
        _draftHallOfFame = hall;
      },
    );
    _draft.refreshFullFileEditor();
    _connections.refreshDiskMtime(_item.filePath);
    _connections.loadLinkNeighbors(
      work: _item,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }

  Future<void> _onVaultDiskChanged() async {
    if (!mounted) return;
    await WorkbenchVaultDiskOps.handleChange(
      action: _connections.evaluateVaultDiskChange(
        filePath: _item.filePath,
        isSaving: _isSaving,
        isDirty: widget.isDirty,
      ),
      mounted: mounted,
      promptRebuild: () => setState(() {}),
      reloadFromDisk: _reloadFromDisk,
    );
  }

  Future<void> _reloadFromDisk({bool silent = false}) async {
    await WorkbenchVaultReloadFlow.run(
      reload: () => _connections.reloadWorkFromDisk(current: _item),
      onReloaded: (reloaded) {
        _applyItem(reloaded, resetPageView: false);
        widget.onDirtyChanged(false);
        widget.onSaved(reloaded, silent: true, dirty: false);
      },
      showSuccess: _showSnack,
      showFailure: _showSnack,
      successMessage: () => WorkbenchVaultReloadMessages.workSuccess,
      failureMessage: WorkbenchVaultReloadMessages.workFailure,
      silent: silent,
      isMounted: () => mounted,
    );
  }

  void _dismissExternalChange() =>
      _connections.dismissExternalChange(_item.filePath);

  @override
  void didUpdateWidget(WorkDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      _applyItem(widget.item, resetPageView: true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
      _refreshRecordLinks();
      return;
    }
    if (!widget.isDirty &&
        !WorkDetailDraftOps.sameItemSnapshot(oldWidget.item, widget.item)) {
      _applyItem(
        widget.item,
        resetPageView: false,
        preserveBodyEditor: _pageView == SanctumPageView.body,
      );
      _connections.loadIncoming(work: _item, linkIndex: widget.linkIndex);
      _connections.loadSameDay(work: _item);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
  }

  void _onPageViewChanged(SanctumPageView next) {
    _draft.handlePageViewChanging(current: _pageView, next: next);
    setState(() => _pageView = next);
  }

  Future<void> _requestEntityLinkForType(EntityAnchorType type) =>
      WorkDetailLinkPickOps.runInteractiveEntityPick(
        context: context,
        isMounted: () => mounted,
        catalog: widget.userCatalog,
        type: type,
        workContext: _item,
        vaultItems: widget.vaultItems,
        showBodyView: (view) => setState(() => _pageView = view),
        applySelection: _applyWikiLinkSelection,
      );

  Future<void> _requestWorkLink() => WorkDetailLinkPickOps.runInteractiveWorkPick(
        context: context,
        isMounted: () => mounted,
        vaultItems: widget.vaultItems,
        excludeWorkId: _item.workId,
        showBodyView: (view) => setState(() => _pageView = view),
        applySelection: _applyWikiLinkSelection,
      );

  Future<void> _applyWikiLinkSelection(EntityLinkSelection picked) async {
    await WorkDetailLinkPickOps.applySelection(
      picked: picked,
      pageView: _pageView,
      sectionEditor: _sectionEditorKey.currentState,
      bodyCtrl: _bodyCtrl,
      syncBodyToItem: () => WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl),
      markDirty: _markDirty,
      reloadLinkNeighbors: () => _connections.loadLinkNeighbors(
        work: _item,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      ),
    );
  }

  void _focusSanctumForLinks() => setState(() => _pageView = SanctumPageView.body);

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

  @override
  void deactivate() {
    _autosave.cancel();
    if (!_suppressPersist) {
      _flushAutoSaveIfNeeded();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _autosave.dispose();
    if (!_suppressPersist && widget.isDirty) {
      if (_pageView == SanctumPageView.file) {
        WorkDetailDraftOps.applyFileEditorToItem(
          item: _item,
          titleCtrl: _titleCtrl,
          bodyCtrl: _bodyCtrl,
          fileCtrl: _fileCtrl,
        );
      } else {
        WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl);
      }
      widget.onPreserveDraft?.call(widget.tabId, _draft.buildSaveDraft());
    }
    _vaultSub?.cancel();
    widget.onBindSave?.call(null);
    _titleCtrl.dispose();
    _posterUrlCtrl.dispose();
    _bodyCtrl.dispose();
    _fileCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    final wasDirty = widget.isDirty;
    widget.onDirtyChanged(true);
    if (!wasDirty && _pageView == SanctumPageView.preview) {
      setState(() {});
    }
    _scheduleAutoSave();
  }

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

  @override
  Widget build(BuildContext context) {
    return WorkbenchSaveShortcuts(
      onSave: _saveArchive,
      child: buildWorkDetailWorkspaceBody(this),
    );
  }
}
