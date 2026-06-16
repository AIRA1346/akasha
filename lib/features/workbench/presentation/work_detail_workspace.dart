import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../services/file_service.dart';
import '../../../services/markdown_body_merger.dart';
import '../../../services/markdown_parser.dart';
import '../../../services/work_info_defaults.dart';
import '../../../widgets/sanctum_page_panel.dart';
import '../../../widgets/web_image_search_dialog.dart';
import '../../../screens/detail/detail_archive_save.dart';
import 'work_detail_draft_ops.dart';
import 'work_detail_info_panel.dart';

/// 3열 작품정보 + 4열 Sanctum md (워크벤치 작업 뷰)
class WorkDetailWorkspace extends StatefulWidget {
  final AkashaItem item;
  final String tabId;
  final bool isDirty;
  final double infoPanelWidth;
  final bool infoPanelLocked;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final void Function(AkashaItem saved) onSaved;
  final VoidCallback onDeleted;
  final ValueChanged<bool> onDirtyChanged;
  final Future<void> Function(AkashaItem item)? onAddToLibrary;

  const WorkDetailWorkspace({
    super.key,
    required this.item,
    required this.tabId,
    this.isDirty = false,
    required this.infoPanelWidth,
    this.infoPanelLocked = false,
    this.onInfoWidthChanged,
    this.onToggleInfoLock,
    required this.onSaved,
    required this.onDeleted,
    required this.onDirtyChanged,
    this.onAddToLibrary,
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

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _posterUrlCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _fileCtrl = TextEditingController();
    _applyItem(widget.item, resetPageView: true);
  }

  void _applyItem(AkashaItem item, {required bool resetPageView}) {
    _item = item;
    _titleCtrl.text = _item.title;
    _draftTags = List<String>.from(_item.tags);
    _registryTags = WorkDetailDraftOps.loadRegistryTags(_item.workId);
    _posterUrlCtrl.text = _item.posterPath ?? '';
    _bodyCtrl.text = WorkDetailDraftOps.initialBodyMarkdown(_item);
    if (resetPageView) _pageView = SanctumPageView.preview;
    _loadDraftFromItem();
    _refreshFullFileEditor();
  }

  @override
  void didUpdateWidget(WorkDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      _applyItem(widget.item, resetPageView: true);
      return;
    }
    if (!widget.isDirty &&
        !WorkDetailDraftOps.sameItemSnapshot(oldWidget.item, widget.item)) {
      _applyItem(widget.item, resetPageView: false);
    }
  }

  void _refreshFullFileEditor() {
    WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl);
    final draft = _applyDraft();
    _fileCtrl.text = MarkdownParser.serialize(draft);
  }

  void _loadDraftFromItem() {
    _draftRating = _item.rating;
    _draftWorkStatus = _item.workStatusLabel;
    _draftMyStatus = _item.myStatusLabel;
    _draftHallOfFame = _item.isHallOfFame;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _posterUrlCtrl.dispose();
    _bodyCtrl.dispose();
    _fileCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    widget.onDirtyChanged(true);
    setState(() {});
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

  bool get _isArchived =>
      AkashaFileService().isArchivedInVault(_item) ||
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

  Future<void> _saveArchive() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final draft = _buildSaveDraft();
      final saved = await DetailArchiveSave.save(draft);
      if (!mounted) return;
      setState(() {
        _item = saved;
        _titleCtrl.text = saved.title;
        _draftTags = List<String>.from(saved.tags);
        _registryTags = WorkDetailDraftOps.loadRegistryTags(saved.workId);
        _posterUrlCtrl.text = saved.posterPath ?? '';
        _bodyCtrl.text = saved.bodyRaw.trim().isNotEmpty
            ? saved.bodyRaw
            : MarkdownBodyMerger.buildDefaultBody(
                synopsis: saved.description,
                quotes: saved.memorableQuotes,
                memo: saved.review,
              );
        _pageView = SanctumPageView.preview;
        _loadDraftFromItem();
      });
      widget.onDirtyChanged(false);
      widget.onSaved(saved);
      _showSnack(
        AkashaFileService().vaultPath != null
            ? '"${saved.title}" md 파일을 저장했습니다.'
            : '"${saved.title}"을(를) 임시 저장했습니다.',
      );
    } catch (e) {
      if (mounted) _showSnack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _applyDraft();
    final vaultLinked = AkashaFileService().vaultPath != null;

    return Row(
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
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFF12121A),
            child: SanctumPagePanel(
              view: _pageView,
              onViewChanged: (v) => setState(() => _pageView = v),
              previewMarkdown: _previewBodyMarkdown,
              mdFilePath: _item.filePath,
              bodyController: _bodyCtrl,
              fileController: _fileCtrl,
              onBodyChanged: _markDirty,
              onFileChanged: _markDirty,
              onOpenFileView: _refreshFullFileEditor,
            ),
          ),
        ),
      ],
    );
  }
}
