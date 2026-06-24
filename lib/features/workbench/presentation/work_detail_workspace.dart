import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/archiving/record_link.dart';
import '../../../core/archiving/record_kind.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/link_candidate_service.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../services/file_service.dart';
import '../../../services/markdown_parser.dart';
import '../../../services/work_info_defaults.dart';
import '../../../services/record_link_navigator.dart';
import '../../../widgets/sanctum_page_panel.dart';
import '../../../widgets/web_image_search_dialog.dart';
import '../../../screens/detail/dialogs/detail_delete_dialog.dart';
import '../../../theme/akasha_colors.dart';
import '../../../config/feature_flags.dart';
import 'work_detail_draft_ops.dart';
import 'work_detail_link_pick_ops.dart';
import 'workbench_link_pick_ops.dart';
import 'work_detail_archive_ops.dart';
import 'work_detail_info_panel.dart';
import 'work_detail_connections_panel.dart';
import 'work_detail_vault_sync.dart';
import 'workbench_autosave_scheduler.dart';
import 'workbench_record_links_loader.dart';
import 'widgets/workbench_breadcrumb.dart';
import 'widgets/workbench_panel_styles.dart';
import 'widgets/work_sanctum_section_editor.dart';

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
  final WorkDetailVaultDiskSync _vaultDiskSync = WorkDetailVaultDiskSync();
  DateTime? _lastSavedAt;
  final WorkbenchAutosaveScheduler _autosave = WorkbenchAutosaveScheduler();
  bool _suppressPersist = false;

  List<String> _incomingPaths = const [];
  bool _loadingIncoming = false;
  int _staleLabelRecordCount = 0;
  List<SameDayRecordRef> _sameDayRefs = const [];
  bool _loadingSameDay = false;
  WorkLinkNeighbors _linkNeighbors = const WorkLinkNeighbors();
  bool _loadingLinkNeighbors = false;

  final GlobalKey<WorkSanctumSectionEditorState> _sectionEditorKey =
      GlobalKey<WorkSanctumSectionEditorState>();

  bool get _externalChangePending => _vaultDiskSync.externalChangePending;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _posterUrlCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _fileCtrl = TextEditingController();
    _applyItem(widget.item, resetPageView: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
    _vaultSub = AkashaFileService().onVaultUpdated.listen((_) {
      _onVaultDiskChanged();
    });
    _refreshDiskMtime();
    _loadIncoming();
    _loadSameDay();
    _loadLinkNeighbors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRunPendingEntityLinkPick();
    });
  }

  Future<void> _maybeRunPendingEntityLinkPick() async {
    final request = WorkDetailLinkPickOps.pendingRequest(
      pendingWorkId: widget.pendingEntityLinkWorkId,
      pendingWorkLinkPick: widget.pendingWorkLinkPick,
      entityLinkType: widget.pendingEntityLinkType,
      preselected: widget.pendingEntityLinkCandidate,
    );
    switch (WorkbenchLinkPickOps.classifyPending(
      request: request,
      currentContextId: _item.workId,
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
          preselected: request.preselected,
        );
        if (!mounted || picked == null) return;
        await _applyWikiLinkSelection(picked);
    }
  }

  Future<void> _loadLinkNeighbors() async {
    final catalog = widget.userCatalog;
    final index = widget.linkIndex;
    if (catalog == null || index == null) return;
    setState(() => _loadingLinkNeighbors = true);
    try {
      final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
        linkIndex: index,
        vaultItems: widget.vaultItems,
      );
      final neighbors = await fetchWorkLinkNeighbors(
        work: _item,
        userCatalog: catalog,
        discovery: discovery,
        linkIndex: index,
        vaultItems: widget.vaultItems,
      );
      if (mounted) {
        setState(() {
          _linkNeighbors = neighbors;
          _loadingLinkNeighbors = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLinkNeighbors = false);
    }
  }

  void _openLinkedEntity(UserCatalogEntity entity) {
    widget.onWikiLinkTap?.call(
      ParsedRecordLink(
        kind: RecordLinkKind.explicitId,
        raw: '[[${entity.entityId}]]',
        targetEntityId: entity.entityId,
      ),
    );
  }

  void _openLinkedWork(AkashaItem work) {
    widget.onWikiLinkTap?.call(
      ParsedRecordLink(
        kind: RecordLinkKind.explicitId,
        raw: '[[${work.workId}]]',
        targetEntityId: work.workId,
      ),
    );
  }

  Future<void> _loadSameDay() async {
    setState(() => _loadingSameDay = true);
    try {
      final refs = await WorkbenchRecordLinksLoader.loadSameDay(
        anchor: _item.addedAt,
        excludePath: _item.filePath,
      );
      if (mounted) {
        setState(() {
          _sameDayRefs = refs;
          _loadingSameDay = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSameDay = false);
    }
  }

  Future<void> _loadIncoming() async {
    final index = widget.linkIndex;
    if (index == null) return;
    setState(() => _loadingIncoming = true);
    try {
      final snapshot = await WorkbenchRecordLinksLoader.loadIncoming(
        linkIndex: index,
        recordEntityId: _item.workId,
        currentTitle: _item.title,
      );
      if (mounted) {
        setState(() {
          _incomingPaths = snapshot.paths;
          _staleLabelRecordCount = snapshot.staleLabelRecordCount;
          _loadingIncoming = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingIncoming = false);
    }
  }

  void _bindSaveHandler() {
    widget.onBindSave?.call(_saveArchive);
  }

  void _assignControllerTextIfChanged(TextEditingController ctrl, String text) {
    WorkDetailDraftOps.assignControllerTextIfChanged(ctrl, text);
  }

  void _applyItem(
    AkashaItem item, {
    required bool resetPageView,
    bool preserveBodyEditor = false,
  }) {
    _item = item;
    _assignControllerTextIfChanged(_titleCtrl, _item.title);
    _draftTags = List<String>.from(_item.tags);
    _registryTags = WorkDetailDraftOps.loadRegistryTags(_item.workId);
    _assignControllerTextIfChanged(_posterUrlCtrl, _item.posterPath ?? '');
    if (preserveBodyEditor) {
      _item.bodyRaw = _bodyCtrl.text;
      WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl);
    } else {
      _assignControllerTextIfChanged(
        _bodyCtrl,
        WorkDetailDraftOps.initialBodyMarkdown(_item),
      );
    }
    if (resetPageView) {
      _pageView = _item.bodyRaw.trim().isEmpty
          ? SanctumPageView.body
          : SanctumPageView.preview;
    }
    _loadDraftFromItem();
    _refreshFullFileEditor();
    _refreshDiskMtime();
    _loadLinkNeighbors();
  }

  void _refreshDiskMtime() => _vaultDiskSync.refreshDiskMtime(_item.filePath);

  Future<void> _onVaultDiskChanged() async {
    if (!mounted) return;
    final action = _vaultDiskSync.evaluateFileChange(
      filePath: _item.filePath,
      isSaving: _isSaving,
      isDirty: widget.isDirty,
    );
    switch (action) {
      case VaultDiskChangeAction.noOp:
        return;
      case VaultDiskChangeAction.promptReload:
        if (mounted) setState(() {});
        return;
      case VaultDiskChangeAction.reload:
        await _reloadFromDisk(silent: true);
    }
  }

  Future<void> _reloadFromDisk({bool silent = false}) async {
    final path = _item.filePath;
    if (path == null || path.isEmpty) return;
    try {
      final content = await File(path).readAsString();
      final reloaded = MarkdownParser.deserialize(content, _item.title);
      reloaded.filePath = path;
      setState(() => _vaultDiskSync.externalChangePending = false);
      _applyItem(reloaded, resetPageView: false);
      widget.onDirtyChanged(false);
      widget.onSaved(reloaded, silent: true, dirty: false);
      _refreshDiskMtime();
      if (!silent && mounted) {
        _showSnack('디스크에서 파일을 다시 불러왔습니다.');
      }
    } catch (e) {
      if (mounted) _showSnack('파일 다시 불러오기 실패: $e');
    }
  }

  void _dismissExternalChange() {
    setState(() => _vaultDiskSync.dismissExternalChange(_item.filePath));
  }

  @override
  void didUpdateWidget(WorkDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      _applyItem(widget.item, resetPageView: true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
      _loadIncoming();
      _loadSameDay();
      return;
    }
    if (!widget.isDirty &&
        !WorkDetailDraftOps.sameItemSnapshot(oldWidget.item, widget.item)) {
      _applyItem(
        widget.item,
        resetPageView: false,
        preserveBodyEditor: _pageView == SanctumPageView.body,
      );
      _loadIncoming();
      _loadSameDay();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
  }

  void _refreshFullFileEditor() {
    WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl);
    final draft = _applyDraft();
    _fileCtrl.text = MarkdownParser.serialize(draft);
  }

  void _applyFileEditorToItem() {
    final preservedPath = _item.filePath;
    final titleFallback = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : _item.title;
    final parsed = MarkdownParser.deserialize(_fileCtrl.text, titleFallback);
    parsed.filePath = preservedPath;
    _item.bodyRaw = parsed.bodyRaw;
    _item.description = parsed.description;
    _item.memorableQuotes = List<String>.from(parsed.memorableQuotes);
    _item.review = parsed.review;
    _assignControllerTextIfChanged(
      _bodyCtrl,
      WorkDetailDraftOps.initialBodyMarkdown(_item),
    );
  }

  void _focusSanctumForLinks() {
    setState(() => _pageView = SanctumPageView.body);
  }

  Future<void> _requestEntityLinkForType(EntityAnchorType type) async {
    final catalog = widget.userCatalog;
    if (catalog == null || !mounted) return;

    setState(() => _pageView = SanctumPageView.body);

    final picked = await WorkDetailLinkPickOps.requestEntityLinkForType(
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

    final picked = await WorkDetailLinkPickOps.requestWorkLink(
      context: context,
      vaultItems: widget.vaultItems,
      excludeWorkId: _item.workId,
    );
    if (!mounted || picked == null) return;
    await _applyWikiLinkSelection(picked);
  }

  Future<void> _applyWikiLinkSelection(EntityLinkSelection picked) async {
    await WorkDetailLinkPickOps.applySelection(
      picked: picked,
      pageView: _pageView,
      sectionEditor: _sectionEditorKey.currentState,
      bodyCtrl: _bodyCtrl,
      syncBodyToItem: () => WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl),
      markDirty: _markDirty,
      reloadLinkNeighbors: _loadLinkNeighbors,
    );
  }

  void _onPageViewChanged(SanctumPageView next) {
    if (_pageView == SanctumPageView.body) {
      WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl);
    } else if (_pageView == SanctumPageView.file &&
        next != SanctumPageView.file) {
      _applyFileEditorToItem();
    }
    if (next == SanctumPageView.file) {
      _refreshFullFileEditor();
    }
    setState(() => _pageView = next);
  }

  void _loadDraftFromItem() {
    _draftRating = _item.rating;
    _draftWorkStatus = _item.workStatusLabel;
    _draftMyStatus = _item.myStatusLabel;
    _draftHallOfFame = _item.isHallOfFame;
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
        _applyFileEditorToItem();
      } else {
        WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl);
      }
      widget.onPreserveDraft?.call(widget.tabId, _buildSaveDraft());
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

  AkashaItem _buildSaveDraft() => WorkDetailDraftOps.buildSaveDraft(
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

  String get _previewBodyMarkdown => WorkDetailDraftOps.previewBodyMarkdown(
        item: _item,
        pageView: _pageView,
        bodyCtrl: _bodyCtrl,
        titleCtrl: _titleCtrl,
        posterUrlCtrl: _posterUrlCtrl,
        draftRating: _draftRating,
        draftWorkStatus: _draftWorkStatus,
        draftMyStatus: _draftMyStatus,
        draftHallOfFame: _draftHallOfFame,
        draftTags: _draftTags,
      );

  AkashaItem _applyDraft() => WorkDetailDraftOps.applyDraft(
        item: _item,
        titleCtrl: _titleCtrl,
        posterUrlCtrl: _posterUrlCtrl,
        draftRating: _draftRating,
        draftWorkStatus: _draftWorkStatus,
        draftMyStatus: _draftMyStatus,
        draftHallOfFame: _draftHallOfFame,
        draftTags: _draftTags,
      );

  bool get _isArchivedInVault => WorkDetailArchiveOps.isArchivedInVault(_item);

  bool get _isArchived => WorkDetailArchiveOps.isArchived(_item);

  Future<void> _openPosterCorrection() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (searchCtx) => WebImageSearchDialog(
        initialQuery: _item.title,
        category: _item.category,
      ),
    );
    if (selected != null) {
      setState(() {
        _posterUrlCtrl.text = selected;
        _applyDraft();
      });
      widget.onDirtyChanged(true);
      _scheduleAutoSave();
    }
  }

  void _resetToDefaults() {
    WorkInfoDefaults.applyRegistryDefaults(_item);
    _titleCtrl.text = _item.title;
    _draftTags = List<String>.from(_item.tags);
    _registryTags = WorkDetailDraftOps.loadRegistryTags(_item.workId);
    _posterUrlCtrl.text = _item.posterPath ?? '';
    _bodyCtrl.text = WorkDetailDraftOps.initialBodyMarkdown(_item);
    _loadDraftFromItem();
    _markDirty();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사전 기본값으로 되돌렸습니다. (work_id는 유지)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleAddToLibrary() async {
    if (widget.onAddToLibrary == null) return;
    if (AkashaFileService().vaultPath == null) {
      _showSnack('볼트 연결 후 서재에 담을 수 있습니다.');
      return;
    }
    if (!_isArchived) {
      await _saveArchive();
    }
    await widget.onAddToLibrary!(_item);
  }

  Future<void> _saveArchive({
    bool silent = false,
    bool switchToPreview = true,
  }) async {
    if (_suppressPersist || _isSaving) return;
    _autosave.cancel();
    final contentAtSave = _pageView == SanctumPageView.file
        ? _fileCtrl.text
        : _bodyCtrl.text;
    setState(() => _isSaving = true);
    try {
      final outcome = await WorkDetailArchiveOps.persist(
        draft: _buildSaveDraft(),
        pageView: _pageView,
        contentAtSave: contentAtSave,
        currentFileContent: _fileCtrl.text,
        currentBodyContent: _bodyCtrl.text,
      );
      final saved = outcome.saved;
      if (!mounted) return;
      final stillDirty = outcome.stillDirty;
      setState(() {
        _item = saved;
        if (!silent && !stillDirty) {
          _assignControllerTextIfChanged(_titleCtrl, saved.title);
          _assignControllerTextIfChanged(_posterUrlCtrl, saved.posterPath ?? '');
          _assignControllerTextIfChanged(
            _bodyCtrl,
            WorkDetailDraftOps.initialBodyMarkdown(saved),
          );
          if (switchToPreview) {
            _pageView = SanctumPageView.preview;
          }
        }
        _draftTags = List<String>.from(saved.tags);
        _registryTags = WorkDetailDraftOps.loadRegistryTags(saved.workId);
        _loadDraftFromItem();
        _refreshFullFileEditor();
        _lastSavedAt = DateTime.now();
        _refreshDiskMtime();
      });
      if (!stillDirty) {
        widget.onDirtyChanged(false);
      } else {
        _scheduleAutoSave();
      }
      widget.onSaved(_item, silent: silent, dirty: stillDirty);
      _loadIncoming();
      _loadSameDay();
      _loadLinkNeighbors();
      if (!silent) {
        _showSnack(WorkDetailArchiveOps.saveSuccessMessage(saved));
      }
    } catch (e) {
      if (mounted && !silent) _showSnack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openIncoming(String path) async {
    final catalog = widget.userCatalog;
    if (catalog == null) return;

    await RecordLinkNavigator.openRecordPath(
      context,
      storagePath: path,
      vaultItems: widget.vaultItems,
      userCatalog: catalog,
      onOpenWork: (item) {
        if (widget.onRecordOpenWork != null) {
          widget.onRecordOpenWork!(item);
          return;
        }
        widget.onWikiLinkTap?.call(
          ParsedRecordLink(
            kind: RecordLinkKind.explicitId,
            raw: '[[${item.workId}]]',
            targetEntityId: item.workId,
          ),
        );
      },
      onOpenEntity: (entity) async {
        if (widget.onRecordOpenEntity != null) {
          await widget.onRecordOpenEntity!(entity);
          return;
        }
        widget.onWikiLinkTap?.call(
          ParsedRecordLink(
            kind: RecordLinkKind.explicitId,
            raw: '[[${entity.entityId}]]',
            targetEntityId: entity.entityId,
          ),
        );
      },
    );
  }

  Future<void> _openSameDay(SameDayRecordRef ref) async {
    final catalog = widget.userCatalog;
    if (ref.kind == RecordKind.workJournal && catalog != null) {
      await RecordLinkNavigator.openRecordPath(
        context,
        storagePath: ref.storagePath,
        vaultItems: widget.vaultItems,
        userCatalog: catalog,
        onOpenWork: (item) {
          if (widget.onRecordOpenWork != null) {
            widget.onRecordOpenWork!(item);
            return;
          }
          widget.onWikiLinkTap?.call(
            ParsedRecordLink(
              kind: RecordLinkKind.explicitId,
              raw: '[[${item.workId}]]',
              targetEntityId: item.workId,
            ),
          );
        },
        onOpenEntity: (entity) async {
          if (widget.onRecordOpenEntity != null) {
            await widget.onRecordOpenEntity!(entity);
            return;
          }
          widget.onWikiLinkTap?.call(
            ParsedRecordLink(
              kind: RecordLinkKind.explicitId,
              raw: '[[${entity.entityId}]]',
              targetEntityId: entity.entityId,
            ),
          );
        },
      );
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${ref.kindLabel} · ${ref.title}'),
        content: Text(
          '${_formatWhen(ref.when.toLocal())}\n${ref.storagePath}',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  String _formatWhen(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:$m';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _confirmDelete() async {
    if (_isSaving) return;

    if (!_isArchivedInVault) {
      _showSnack('삭제할 md 파일이 없습니다.');
      return;
    }

    final displayTitle = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : _item.title;

    final confirmed = await showDetailDeleteConfirmDialog(
      context,
      title: displayTitle,
      hasVault: true,
      hasUnsavedChanges: widget.isDirty,
    );
    if (!confirmed || !mounted) return;

    _autosave.cancel();
    while (_isSaving && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    setState(() => _suppressPersist = true);
    widget.onDirtyChanged(false);

    final deleted = await WorkDetailArchiveOps.deleteFromVault(_item);
    if (!mounted) return;

    if (deleted) {
      _showSnack('"$displayTitle" md 파일을 삭제했습니다.');
      widget.onDeleted();
    } else {
      setState(() => _suppressPersist = false);
      _showSnack('삭제할 파일을 찾지 못했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _applyDraft();
    final vaultLinked = AkashaFileService().vaultPath != null;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
      },
      child: Actions(
        actions: {
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              _saveArchive();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
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
                    const WorkbenchBreadcrumbSegment(label: '작품'),
                    WorkbenchBreadcrumbSegment(
                      label: _titleCtrl.text.trim().isNotEmpty
                          ? _titleCtrl.text.trim()
                          : _item.title,
                    ),
                  ],
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              WorkDetailInfoPanel(
                item: _item,
                preview: preview,
                panelWidth: widget.infoPanelWidth,
                infoPanelLocked: widget.infoPanelLocked,
                vaultLinked: vaultLinked,
                titleCtrl: _titleCtrl,
                posterUrlCtrl: _posterUrlCtrl,
                draftRating: _draftRating,
                draftWorkStatus: _draftWorkStatus,
                draftMyStatus: _draftMyStatus,
                draftHallOfFame: _draftHallOfFame,
                draftTags: _draftTags,
                registryTags: _registryTags,
                isSaving: _isSaving,
                isArchived: _isArchived,
                isDirty: widget.isDirty,
                lastSavedAt: _lastSavedAt,
                showAddToLibrary: widget.onAddToLibrary != null,
                loadingIncoming: _loadingIncoming,
                incomingPaths: _incomingPaths,
                staleLabelRecordCount: _staleLabelRecordCount,
                onRefreshIncoming: _loadIncoming,
                loadingSameDay: _loadingSameDay,
                sameDayRefs: _sameDayRefs,
                onOpenIncoming: _openIncoming,
                onOpenSameDay: _openSameDay,
                onInfoWidthChanged: widget.onInfoWidthChanged,
                onToggleInfoLock: widget.onToggleInfoLock,
                onMarkDirty: _markDirty,
                onDraftRatingChanged: (v) => setState(() => _draftRating = v),
                onDraftWorkStatusChanged: (v) => setState(() => _draftWorkStatus = v),
                onDraftMyStatusChanged: (v) => setState(() => _draftMyStatus = v),
                onDraftHallOfFameChanged: (v) => setState(() => _draftHallOfFame = v),
                onDraftTagsChanged: (tags) => setState(() => _draftTags = tags),
                onPosterTap: _openPosterCorrection,
                onResetToDefaults: _resetToDefaults,
                onSaveArchive: _saveArchive,
                onAddToLibrary: _handleAddToLibrary,
                canDeleteMd: _isArchivedInVault,
                onDeleteArchive: _confirmDelete,
                onClose: widget.onClose,
                linkNeighbors: _linkNeighbors,
                loadingLinkNeighbors: _loadingLinkNeighbors,
                onOpenLinkedEntity: _openLinkedEntity,
                onOpenLinkedWork: _openLinkedWork,
                onGoKnowledgeGraph: widget.onGoKnowledgeGraph,
                onFocusSanctum: _focusSanctumForLinks,
              ),
        Expanded(
          child: ColoredBox(
            color: AkashaColors.workbenchEditor,
            child: SanctumPagePanel(
              view: _pageView,
              onViewChanged: _onPageViewChanged,
              headerTitle: '작품 정보 편집',
              titleController: _titleCtrl,
              onTitleChanged: _markDirty,
              sectionLayout: true,
              sectionEditorKey: _sectionEditorKey,
              previewMarkdown: _previewBodyMarkdown,
              mdFilePath: _item.filePath,
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
              onOpenFileView: _refreshFullFileEditor,
              onWikiLinkTap: widget.onWikiLinkTap,
              onRequestEntityLink: widget.onRequestEntityLink,
              footer: WorkbenchSaveActions(
                isSaving: _isSaving,
                isDirty: widget.isDirty,
                lastSavedAt: _lastSavedAt,
                saveLabel: _isArchived ? 'md 저장' : 'md 생성',
                onSave: _saveArchive,
                showAddToLibrary: widget.onAddToLibrary != null,
                libraryLabel: _isArchived
                    ? '서재에 담기'
                    : '저장하고 서재에 담기',
                onAddToLibrary: _handleAddToLibrary,
                showReset: true,
                onReset: _resetToDefaults,
                canDeleteMd: _isArchivedInVault,
                onDeleteArchive: _confirmDelete,
              ),
            ),
          ),
        ),
              WorkDetailConnectionsPanel(
                item: _item,
                linkNeighbors: _linkNeighbors,
                loadingLinkNeighbors: _loadingLinkNeighbors,
                draftTags: _draftTags,
                onOpenLinkedEntity: _openLinkedEntity,
                onOpenLinkedWork: _openLinkedWork,
                onGoKnowledgeGraph: widget.onGoKnowledgeGraph,
                onFocusSanctum: _focusSanctumForLinks,
                onAddEntityLink: widget.userCatalog != null
                    ? _requestEntityLinkForType
                    : null,
                onAddWorkLink: _requestWorkLink,
                loadingIncoming: _loadingIncoming,
                incomingPaths: _incomingPaths,
                staleLabelRecordCount: _staleLabelRecordCount,
                onRefreshIncoming: _loadIncoming,
                onOpenIncoming: _openIncoming,
                loadingSameDay: _loadingSameDay,
                sameDayRefs: _sameDayRefs,
                onOpenSameDay: _openSameDay,
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}
