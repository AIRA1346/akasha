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
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../services/file_service.dart';
import '../../../services/markdown_parser.dart';
import '../../../services/work_info_defaults.dart';
import '../../../services/same_day_record_service.dart';
import '../../../services/record_link_navigator.dart';
import '../../../services/record_link_stale_label.dart';
import '../../../widgets/sanctum_page_panel.dart';
import '../../../widgets/web_image_search_dialog.dart';
import '../../../screens/detail/detail_archive_save.dart';
import '../../../screens/detail/dialogs/detail_delete_dialog.dart';
import 'work_detail_draft_ops.dart';
import 'work_detail_info_panel.dart';

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
  final void Function(AkashaItem saved) onSaved;
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
  DateTime? _diskMtime;
  bool _externalChangePending = false;
  DateTime? _lastSavedAt;
  Timer? _autoSaveTimer;
  bool _suppressPersist = false;

  List<String> _incomingPaths = const [];
  bool _loadingIncoming = false;
  int _staleLabelRecordCount = 0;
  List<SameDayRecordRef> _sameDayRefs = const [];
  bool _loadingSameDay = false;
  WorkLinkNeighbors _linkNeighbors = const WorkLinkNeighbors();
  bool _loadingLinkNeighbors = false;

  static const _autoSaveDelay = Duration(seconds: 2);

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
    final anchor = _item.addedAt;
    setState(() => _loadingSameDay = true);
    try {
      final refs = await SameDayRecordService.findForAnchor(
        vaultPath: AkashaFileService().vaultPath,
        anchor: anchor,
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
      final paths = await index.incomingRecordPaths(_item.workId);
      final uniquePaths = paths.toSet().toList()..sort();
      final stale = await RecordLinkStaleLabel.countForEntity(
        linkIndex: index,
        entityId: _item.workId,
        currentTitle: _item.title,
      );
      if (mounted) {
        setState(() {
          _incomingPaths = uniquePaths;
          _staleLabelRecordCount = stale.staleRecordCount;
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

  void _applyItem(AkashaItem item, {required bool resetPageView}) {
    _item = item;
    _titleCtrl.text = _item.title;
    _draftTags = List<String>.from(_item.tags);
    _registryTags = WorkDetailDraftOps.loadRegistryTags(_item.workId);
    _posterUrlCtrl.text = _item.posterPath ?? '';
    _bodyCtrl.text = WorkDetailDraftOps.initialBodyMarkdown(_item);
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

  void _refreshDiskMtime() {
    final path = _item.filePath;
    if (path == null || path.isEmpty) {
      _diskMtime = null;
      return;
    }
    final file = File(path);
    _diskMtime = file.existsSync() ? file.lastModifiedSync() : null;
  }

  Future<void> _onVaultDiskChanged() async {
    if (!mounted) return;
    if (_isSaving) return;
    final path = _item.filePath;
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!file.existsSync()) return;

    final mtime = file.lastModifiedSync();
    if (_diskMtime != null && !mtime.isAfter(_diskMtime!)) return;

    if (widget.isDirty) {
      if (!_externalChangePending) {
        setState(() => _externalChangePending = true);
      }
      return;
    }
    await _reloadFromDisk(silent: true);
  }

  Future<void> _reloadFromDisk({bool silent = false}) async {
    final path = _item.filePath;
    if (path == null || path.isEmpty) return;
    try {
      final content = await File(path).readAsString();
      final reloaded = MarkdownParser.deserialize(content, _item.title);
      reloaded.filePath = path;
      setState(() => _externalChangePending = false);
      _applyItem(reloaded, resetPageView: false);
      widget.onDirtyChanged(false);
      widget.onSaved(reloaded);
      _refreshDiskMtime();
      if (!silent && mounted) {
        _showSnack('디스크에서 파일을 다시 불러왔습니다.');
      }
    } catch (e) {
      if (mounted) _showSnack('파일 다시 불러오기 실패: $e');
    }
  }

  void _dismissExternalChange() {
    setState(() => _externalChangePending = false);
    _refreshDiskMtime();
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
      _applyItem(widget.item, resetPageView: false);
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
    _bodyCtrl.text = WorkDetailDraftOps.initialBodyMarkdown(_item);
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
    _autoSaveTimer?.cancel();
    if (!_suppressPersist) {
      _flushAutoSaveIfNeeded();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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
    widget.onDirtyChanged(true);
    setState(() {});
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    if (_suppressPersist) return;
    if (AkashaFileService().vaultPath == null) return;
    if (_externalChangePending) return;
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      if (!mounted) return;
      if (!widget.isDirty) return;
      if (_externalChangePending) return;
      _saveArchive(silent: true, switchToPreview: false);
    });
  }

  void _flushAutoSaveIfNeeded() {
    if (_suppressPersist) return;
    if (!widget.isDirty) return;
    if (AkashaFileService().vaultPath == null) return;
    if (_externalChangePending) return;
    if (_isSaving) return;
    unawaited(_saveArchive(silent: true, switchToPreview: false));
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

  bool get _isArchivedInVault => AkashaFileService().isArchivedInVault(_item);

  bool get _isArchived =>
      _isArchivedInVault ||
      AkashaFileService()
          .inMemoryCache
          .containsKey(AkashaFileService.cacheKeyFor(_item));

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
    _autoSaveTimer?.cancel();
    final contentAtSave = _pageView == SanctumPageView.file
        ? _fileCtrl.text
        : _bodyCtrl.text;
    setState(() => _isSaving = true);
    try {
      final draft = _buildSaveDraft();
      final saved = await DetailArchiveSave.save(draft);
      if (!mounted) return;
      final contentUnchanged = _pageView == SanctumPageView.file
          ? _fileCtrl.text == contentAtSave
          : _bodyCtrl.text == contentAtSave;
      setState(() {
        _item = saved;
        if (!silent) {
          _titleCtrl.text = saved.title;
          _posterUrlCtrl.text = saved.posterPath ?? '';
          _bodyCtrl.text = WorkDetailDraftOps.initialBodyMarkdown(saved);
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
      if (!silent || contentUnchanged) {
        widget.onDirtyChanged(false);
      } else {
        _scheduleAutoSave();
      }
      widget.onSaved(saved);
      _loadIncoming();
      _loadSameDay();
      _loadLinkNeighbors();
      if (!silent) {
        _showSnack(
          AkashaFileService().vaultPath != null
              ? '"${saved.title}" md 파일을 저장했습니다.'
              : '"${saved.title}"을(를) 임시 저장했습니다.',
        );
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
      vaultItems: const [],
      userCatalog: catalog,
      onOpenWork: (item) {
        widget.onWikiLinkTap?.call(
          ParsedRecordLink(
            kind: RecordLinkKind.explicitId,
            raw: '[[${item.workId}]]',
            targetEntityId: item.workId,
          ),
        );
      },
      onOpenEntity: (entity) async {
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
        vaultItems: const [],
        userCatalog: catalog,
        onOpenWork: (item) {
          widget.onWikiLinkTap?.call(
            ParsedRecordLink(
              kind: RecordLinkKind.explicitId,
              raw: '[[${item.workId}]]',
              targetEntityId: item.workId,
            ),
          );
        },
        onOpenEntity: (entity) async {
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

    final service = AkashaFileService();
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

    _autoSaveTimer?.cancel();
    while (_isSaving && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    setState(() => _suppressPersist = true);
    widget.onDirtyChanged(false);

    final deleted = await service.deleteAkashaItem(_item);
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
              ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFF12121A),
            child: SanctumPagePanel(
              view: _pageView,
              onViewChanged: _onPageViewChanged,
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
            ),
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
