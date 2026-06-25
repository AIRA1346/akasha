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
import '../../../widgets/web_image_search_dialog.dart';
import '../../../services/entity_vault_path_conflict.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/file_service.dart';
import '../../../theme/akasha_colors.dart';
import '../../../config/feature_flags.dart';
import '../../../widgets/sanctum_page_panel.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../screens/home/views/preview_record_view_model.dart';
import 'entity_detail_archive_ops.dart';
import 'entity_detail_connections_coordinator.dart';
import 'entity_detail_save_ops.dart';
import 'entity_detail_delete_ops.dart';
import 'entity_detail_draft_ops.dart';
import 'entity_detail_link_pick_ops.dart';
import 'workbench_autosave_scheduler.dart';
import 'workbench_link_pick_ops.dart';
import 'workbench_linked_record_ops.dart';
import 'workbench_record_navigation.dart';
import 'workbench_vault_disk_ops.dart';
import 'entity_detail_connections_panel.dart';
import 'entity_detail_info_panel.dart';
import 'widgets/workbench_breadcrumb.dart';
import 'widgets/workbench_panel_styles.dart';
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
    _item = _buildEntityItem(_entity, _journal);
    _preview = _item;
    _draftTags = List<String>.from(_journal?.tags ?? _entity.tags);
    _bodyCtrl = TextEditingController(text: _journal?.body ?? '');
    _posterUrlCtrl = TextEditingController(text: _journal?.posterPath ?? _entity.posterPath ?? '');
    _posterUrlCtrl.addListener(() {
      _updatePreview();
    });
    _fileCtrl = TextEditingController(text: _serializeFile());
    _pageView = EntityDetailDraftOps.initialPageView(_bodyCtrl.text);
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
    _journal = entry;
    _entity = _entity.copyWith(
      title: entry.title,
      tags: entry.tags,
      posterPath: entry.posterPath,
    );
    _draftTags = List<String>.from(entry.tags);
    _bodyCtrl.text = entry.body;
    _posterUrlCtrl.text = entry.posterPath ?? '';
    _item = _buildEntityItem(_entity, _journal);
    _preview = _item;
    _fileCtrl.text = _serializeFile();
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
        _showSnack('디스크에서 journal을 다시 불러왔습니다.');
      }
    } catch (e) {
      if (mounted && !silent) {
        _showSnack('journal 다시 불러오기 실패: $e');
      }
    }
  }

  void _dismissExternalChange() {
    _connections.dismissExternalChange(_journal?.storagePath);
  }

  Future<void> _maybeRunPendingEntityLinkPick() async {
    final request = EntityDetailLinkPickOps.pendingRequest(
      pendingEntityId: widget.pendingEntityLinkEntityId,
      pendingWorkLinkPick: widget.pendingEntityWorkLinkPick,
      entityLinkType: widget.pendingEntityLinkType,
    );
    switch (WorkbenchLinkPickOps.classifyPending(
      request: request,
      currentContextId: _entity.entityId,
      catalog: widget.userCatalog,
    )) {
      case WorkbenchPendingLinkResolution.wrongContext:
      case WorkbenchPendingLinkResolution.skipped:
        return;
      case WorkbenchPendingLinkResolution.pickWork:
        widget.onPendingEntityLinkHandled?.call();
        if (!mounted) return;
        await _requestWorkLink();
      case WorkbenchPendingLinkResolution.pickEntity:
        widget.onPendingEntityLinkHandled?.call();
        if (!mounted) return;
        setState(() => _pageView = SanctumPageView.body);
        final picked = await WorkbenchLinkPickOps.pickEntityLink(
          context: context,
          catalog: widget.userCatalog!,
          type: request.entityLinkType!,
          workContext: _item,
          vaultItems: widget.vaultItems,
        );
        if (!mounted || picked == null) return;
        await _applyWikiLinkSelection(picked);
    }
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
      _entity = widget.entity;
      _journal = widget.journal;
      _item = _buildEntityItem(_entity, _journal);
      _preview = _item;
      _draftTags = List<String>.from(_journal?.tags ?? _entity.tags);
      _bodyCtrl.text = _journal?.body ?? '';
      _posterUrlCtrl.text = _journal?.posterPath ?? _entity.posterPath ?? '';
      _fileCtrl.text = _serializeFile();
      _pageView = EntityDetailDraftOps.initialPageView(_bodyCtrl.text);
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
    final vaultMsg = EntityDetailSaveOps.vaultBlockedMessage(silent: silent);
    if (vaultMsg != null) {
      if (mounted) _showSnack(vaultMsg);
      return;
    }

    if (_pageView == SanctumPageView.file) {
      _syncBodyFromEditor();
    }

    final emptyMsg = EntityDetailSaveOps.emptyBodyBlockedMessage(
      rawBody: _bodyCtrl.text,
      posterPath: _posterUrlCtrl.text,
      tags: _draftTags,
      silent: silent,
    );
    if (emptyMsg != null) {
      if (mounted) _showSnack(emptyMsg);
      return;
    }
    final bodyResolve = EntityDetailArchiveOps.resolveBodyForSave(
      rawBody: _bodyCtrl.text,
      posterPath: _posterUrlCtrl.text,
      tags: _draftTags,
    );
    final body = bodyResolve.body!;
    if (bodyResolve.usedPlaceholder && !silent) {
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
        usedPlaceholder: bodyResolve.usedPlaceholder,
        catalog: widget.userCatalog,
        vaultStore: _store,
      );
      if (!mounted) return;
      switch (result) {
        case EntityDetailSaveSkipped():
          return;
        case EntityDetailSaveFailed(:final error):
          if (!silent) {
            final msg = error is EntityVaultPathConflict
                ? error.userMessage
                : '저장 실패: $error';
            _showSnack(msg);
          }
        case EntityDetailSaveSucceeded(
            :final mirrored,
            :final saved,
            :final savedAt,
            :final serializedFile,
            :final bodyForPlaceholder,
          ):
          if (bodyForPlaceholder != null && !silent) {
            _bodyCtrl.text = bodyForPlaceholder;
          }
          final nextPageView = EntityDetailSaveOps.pageViewAfterSave(
            current: _pageView,
            silent: silent,
          );
          setState(() {
            _entity = mirrored;
            _journal = saved;
            _item = _buildEntityItem(mirrored, saved);
            _preview = _item;
            _draftTags = List<String>.from(saved.tags);
            _fileCtrl.text = serializedFile;
            _lastSavedAt = savedAt;
            if (nextPageView != null) {
              _pageView = nextPageView;
            }
          });
          widget.onDirtyChanged(false);
          widget.onSaved(mirrored, saved, silent: silent);
          _refreshRecordLinks();
          _connections.refreshDiskMtime(_journal?.storagePath);
          if (!silent) {
            _showSnack(EntityDetailArchiveOps.saveSuccessMessage(mirrored));
          }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openIncoming(String path) async {
    final catalog = widget.userCatalog;
    if (catalog == null) return;

    await WorkbenchRecordNavigation.openIncoming(
      context: context,
      storagePath: path,
      vaultItems: widget.vaultItems,
      userCatalog: catalog,
      onRecordOpenWork: widget.onRecordOpenWork,
      onRecordOpenEntity: widget.onRecordOpenEntity,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

  Future<void> _openSameDay(SameDayRecordRef ref) async {
    await WorkbenchRecordNavigation.openSameDay(
      context: context,
      ref: ref,
      vaultItems: widget.vaultItems,
      userCatalog: widget.userCatalog,
      onRecordOpenWork: widget.onRecordOpenWork,
      onRecordOpenEntity: widget.onRecordOpenEntity,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

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

  Future<void> _openPosterCorrection() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (searchCtx) => WebImageSearchDialog(
        initialQuery: _entity.title,
        category: _entity.subtype,
      ),
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
    if (widget.onAddToLibrary == null) return;
    if (AkashaFileService().vaultPath == null) {
      _showSnack('볼트 연결 후 서재에 담을 수 있습니다.');
      return;
    }
    if (!EntityDetailArchiveOps.hasJournal(_journal)) {
      await _saveJournal();
    }
    if (_journal != null) {
      await widget.onAddToLibrary!(_entity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasJournal = EntityDetailArchiveOps.hasJournal(_journal);
    final saveLabel = hasJournal ? 'md 저장' : 'journal 생성';
    final typeLabel = entityTypeDisplayLabel(_entity.anchorType);

    return WorkbenchSaveShortcuts(
      onSave: () => _saveJournal(),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (FeatureFlags.showWorkbenchBreadcrumb)
                WorkbenchBreadcrumb(
                  segments: [
                    WorkbenchBreadcrumbSegment(
                      label: '서재',
                      onTap: widget.onClose,
                    ),
                    WorkbenchBreadcrumbSegment(label: typeLabel),
                    WorkbenchBreadcrumbSegment(label: _entity.title),
                  ],
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EntityDetailInfoPanel(
                      entity: _entity,
                      preview: _preview,
                      hasJournal: hasJournal,
                      panelWidth: widget.infoPanelWidth,
                      infoPanelLocked: widget.infoPanelLocked,
                      onInfoWidthChanged: widget.onInfoWidthChanged,
                      onToggleInfoLock: widget.onToggleInfoLock,
                      onPosterTap: _openPosterCorrection,
                      posterUrlCtrl: _posterUrlCtrl,
                      onClose: widget.onClose,
                      onFocusSanctum: _focusSanctumForLinks,
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: AkashaColors.workbenchEditor,
                        child: SanctumPagePanel(
                          view: _pageView,
                          onViewChanged: _onPageViewChanged,
                          headerTitle: '기록 본문',
                          previewMarkdown: _bodyCtrl.text,
                          mdFilePath: _journal?.storagePath,
                          isDirty: widget.isDirty,
                          isSaving: _isSaving,
                          externalChangePending: _externalChangePending,
                          onReloadFromDisk: () => _reloadFromDisk(),
                          onDismissExternalChange: _dismissExternalChange,
                          lastSavedAt: _lastSavedAt,
                          bodyController: _bodyCtrl,
                          fileController: _fileCtrl,
                          onBodyChanged: _markDirty,
                          onFileChanged: _markDirty,
                          onOpenFileView: _refreshFileEditor,
                          onWikiLinkTap: widget.onWikiLinkTap,
                          onRequestEntityLink: widget.onRequestEntityLink,
                          userCatalog: widget.userCatalog,
                          onOpenLinkedEntity: _openLinkedEntity,
                          footer: WorkbenchSaveActions(
                            isSaving: _isSaving,
                            isDirty: widget.isDirty,
                            lastSavedAt: _lastSavedAt,
                            saveLabel: saveLabel,
                            explicitSaveLabel: saveLabel,
                            onSave: () => _saveJournal(),
                            showAddToLibrary: widget.onAddToLibrary != null,
                            libraryLabel: hasJournal
                                ? '서재에 담기'
                                : '저장하고 서재에 담기',
                            onAddToLibrary: _handleAddToLibrary,
                            canDeleteMd: hasJournal,
                            onDeleteArchive: hasJournal ? _confirmDelete : null,
                          ),
                        ),
                      ),
                    ),
                    EntityDetailConnectionsPanel(
                      entity: _entity,
                      linkNeighbors: _connections.linkNeighbors,
                      loadingLinkNeighbors: _connections.loadingLinkNeighbors,
                      draftTags: _draftTags,
                      onOpenLinkedEntity: _openLinkedEntity,
                      onOpenLinkedWork: _openLinkedWork,
                      onGoKnowledgeGraph: widget.onGoKnowledgeGraph,
                      onFocusSanctum: _focusSanctumForLinks,
                      onAddEntityLink: widget.userCatalog != null
                          ? _requestEntityLinkForType
                          : null,
                      onAddWorkLink: widget.userCatalog != null
                          ? _requestWorkLink
                          : null,
                      loadingIncoming: _connections.loadingIncoming,
                      incomingPaths: _connections.incomingPaths,
                      staleLabelRecordCount: _connections.staleLabelRecordCount,
                      onRefreshIncoming: () => _connections.loadIncoming(
                        entity: _entity,
                        journal: _journal,
                        linkIndex: widget.linkIndex,
                      ),
                      onOpenIncoming: _openIncoming,
                      loadingSameDay: _connections.loadingSameDay,
                      sameDayRefs: _connections.sameDayRefs,
                      onOpenSameDay: _openSameDay,
                      onDraftTagsChanged: (tags) {
                        setState(() => _draftTags = tags);
                        _updatePreview();
                        _markDirty();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
