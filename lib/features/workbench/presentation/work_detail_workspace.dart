import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../services/file_service.dart';
import '../../../services/markdown_body_merger.dart';
import '../../../services/markdown_parser.dart';
import '../../../services/work_info_defaults.dart';
import '../../../widgets/poster_image.dart';
import '../../../widgets/sanctum_page_panel.dart';
import '../../../widgets/star_rating.dart';
import '../../../widgets/web_image_search_dialog.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import '../../../screens/detail/detail_archive_save.dart';

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

  late TextEditingController _titleCtrl;
  late TextEditingController _tagsCtrl;
  late TextEditingController _posterUrlCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _fileCtrl;
  SanctumPageView _pageView = SanctumPageView.preview;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _tagsCtrl = TextEditingController();
    _posterUrlCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _fileCtrl = TextEditingController();
    _applyItem(widget.item, resetPageView: true);
  }

  void _applyItem(AkashaItem item, {required bool resetPageView}) {
    _item = item;
    _titleCtrl.text = _item.title;
    _tagsCtrl.text = _item.tags.join(', ');
    _posterUrlCtrl.text = _item.posterPath ?? '';
    _bodyCtrl.text = _initialBodyMarkdown();
    if (resetPageView) _pageView = SanctumPageView.preview;
    _loadDraftFromItem();
    _refreshFullFileEditor();
  }

  bool _sameItemSnapshot(AkashaItem a, AkashaItem b) {
    return a.workId == b.workId &&
        a.title == b.title &&
        a.rating == b.rating &&
        a.posterPath == b.posterPath &&
        a.bodyRaw == b.bodyRaw &&
        a.description == b.description &&
        a.review == b.review &&
        a.myStatusLabel == b.myStatusLabel &&
        a.workStatusLabel == b.workStatusLabel &&
        a.isHallOfFame == b.isHallOfFame;
  }

  @override
  void didUpdateWidget(WorkDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      _applyItem(widget.item, resetPageView: true);
      return;
    }
    if (!widget.isDirty &&
        !_sameItemSnapshot(oldWidget.item, widget.item)) {
      _applyItem(widget.item, resetPageView: false);
    }
  }

  String _initialBodyMarkdown() {
    if (_item.bodyRaw.trim().isNotEmpty) return _item.bodyRaw;
    return MarkdownBodyMerger.buildDefaultBody(
      synopsis: _item.description,
      quotes: _item.memorableQuotes,
      memo: _item.review,
    );
  }

  void _syncBodyFromEditor() {
    _item.bodyRaw = _bodyCtrl.text.trimRight();
    final slots = MarkdownBodyMerger.parseSlots(_item.bodyRaw);
    _item.description = slots.synopsis;
    _item.memorableQuotes = List<String>.from(slots.quotes);
    _item.review = slots.memo;
  }

  void _refreshFullFileEditor() {
    _syncBodyFromEditor();
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
    _tagsCtrl.dispose();
    _posterUrlCtrl.dispose();
    _bodyCtrl.dispose();
    _fileCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    widget.onDirtyChanged(true);
    setState(() {});
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  AkashaItem _buildSaveDraft() {
    if (_pageView == SanctumPageView.file) {
      final preservedPath = _item.filePath;
      final titleFallback = _titleCtrl.text.trim().isNotEmpty
          ? _titleCtrl.text.trim()
          : _item.title;
      final parsed =
          MarkdownParser.deserialize(_fileCtrl.text, titleFallback);
      parsed.filePath = preservedPath;
      return parsed;
    }
    _syncBodyFromEditor();
    return _applyDraft();
  }

  String get _previewBodyMarkdown {
    if (_pageView == SanctumPageView.body) _syncBodyFromEditor();
    final draft = _applyDraft();
    return MarkdownBodyMerger.mergeBody(
      bodyRaw: draft.bodyRaw,
      synopsis: draft.description,
      quotes: draft.memorableQuotes,
      memo: draft.review,
    );
  }

  AkashaItem _applyDraft() {
    final poster = _posterUrlCtrl.text.trim();
    _item.title = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : _item.title;
    _item.rating = _draftRating;
    _item.posterPath = poster.isNotEmpty ? poster : null;
    _item.setWorkStatus(_draftWorkStatus);
    _item.setMyStatus(_draftMyStatus);
    _item.isHallOfFame = _draftHallOfFame;
    _item.tags = _parseTags(_tagsCtrl.text);
    return _item;
  }

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
    _tagsCtrl.text = _item.tags.join(', ');
    _posterUrlCtrl.text = _item.posterPath ?? '';
    _bodyCtrl.text = _initialBodyMarkdown();
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
        _tagsCtrl.text = saved.tags.join(', ');
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
    final gradColors = categoryGradient(_item.category);
    final vaultLinked = AkashaFileService().vaultPath != null;
    final metaLine = [
      if (_item.creator.isNotEmpty) _item.creator,
      if (_item.releaseYear != null) '${_item.releaseYear}',
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkbenchResizablePanel(
          width: widget.infoPanelWidth,
          minWidth: 220,
          maxWidth: 400,
          locked: widget.infoPanelLocked,
          onWidthChanged: widget.onInfoWidthChanged,
          onToggleLock: widget.onToggleInfoLock,
          child: ColoredBox(
            color: const Color(0xFF1A1A28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.tealAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '작품 정보',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF2D2D44)),
                if (!vaultLinked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                    child: Row(
                      children: [
                        Icon(Icons.folder_off_outlined,
                            size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '볼트 미연동 · 임시 저장만',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final posterMaxHeight = constraints.maxHeight * 0.55;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: _buildInfoPoster(
                                maxWidth: constraints.maxWidth,
                                maxHeight: posterMaxHeight,
                                preview: preview,
                                gradColors: gradColors,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                              child: _buildInfoForm(metaLine: metaLine),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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

  /// 스크롤 없이 하단 고정 — bba7b13의 148px·cover 패턴 대체.
  Widget _buildInfoForm({required String metaLine}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _metaChip(icon: _item.domain.icon, label: _item.domain.label),
            _metaChip(icon: _item.category.icon, label: _item.category.label),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _titleCtrl,
          onChanged: (_) => _markDirty(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
        if (metaLine.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            metaLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            InteractiveStarRating(
              rating: _draftRating,
              size: 18,
              onChanged: (v) {
                setState(() => _draftRating = v);
                _markDirty();
              },
            ),
            const Spacer(),
            SizedBox(
              height: 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Switch(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: _draftHallOfFame,
                  onChanged: (v) {
                    setState(() => _draftHallOfFame = v);
                    _markDirty();
                  },
                ),
              ),
            ),
            Text(
              'HoF',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _statusDropdown(
                label: '작품',
                value: _draftWorkStatus,
                options: _item.workStatusOptions,
                onChanged: (v) {
                  setState(() => _draftWorkStatus = v);
                  _markDirty();
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _statusDropdown(
                label: '나의',
                value: _draftMyStatus,
                options: _item.myStatusOptions,
                onChanged: (v) {
                  setState(() => _draftMyStatus = v);
                  _markDirty();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _tagsCtrl,
          onChanged: (_) => _markDirty(),
          style: const TextStyle(fontSize: 11),
          decoration: const InputDecoration(
            hintText: '태그',
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.onAddToLibrary != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleAddToLibrary,
              icon: const Icon(Icons.collections_bookmark_outlined, size: 16),
              label: Text(_isArchived ? '서재에 담기' : '저장하고 서재에 담기'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetToDefaults,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('기본값'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveArchive,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isArchived ? 'md 저장' : 'md 생성'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 2:3 프레임 + contain — 전체 높이 채우기·148px·cover 금지.
  Widget _buildInfoPoster({
    required double maxWidth,
    required double maxHeight,
    required AkashaItem preview,
    required List<Color> gradColors,
  }) {
    final bounds = infoPosterDisplayBounds(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    final width = bounds.width;
    final height = bounds.height;

    return GestureDetector(
        onTap: _openPosterCorrection,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: const Color(0xFF12121A),
            border: Border.all(color: const Color(0xFF2D2D44)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                gradColors.first.withValues(alpha: 0.25),
                const Color(0xFF12121A),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: width,
              height: height,
              child: PosterImage(
                key: ValueKey(_posterUrlCtrl.text),
                item: preview,
                fit: BoxFit.contain,
                width: width,
                height: height,
              ),
            ),
          ),
        ),
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3A3A52)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.tealAccent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  Widget _statusDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(fontSize: 10, height: 1.1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      items: options
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// 작품정보 패널 포스터 — 2:3 프레임을 max 안에 맞춤 (빈 세로 여백 최소화).
@visibleForTesting
({double width, double height}) infoPosterDisplayBounds({
  required double maxWidth,
  required double maxHeight,
}) {
  if (maxWidth <= 0 || maxHeight <= 0) {
    return (width: 0, height: 0);
  }
  var width = maxWidth;
  var height = width * 3 / 2;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * 2 / 3;
  }
  return (width: width, height: height);
}
