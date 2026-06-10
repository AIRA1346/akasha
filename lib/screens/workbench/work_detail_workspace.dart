import 'package:flutter/material.dart';

import '../../models/akasha_item.dart';
import '../../models/enums.dart';
import '../../services/file_service.dart';
import '../../services/markdown_body_merger.dart';
import '../../services/work_info_defaults.dart';
import '../../services/works_registry.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/vault_markdown_body.dart';
import '../../widgets/web_image_search_dialog.dart';
import '../../widgets/workbench_resizable_panel.dart';
import '../detail/detail_archive_save.dart';
import '../detail/dialogs/detail_delete_dialog.dart';
import '../home/dialogs/catalog_fix_contribution_dialog.dart';

/// 3열 작품정보 + 4열 Sanctum md (워크벤치 작업 뷰)
class WorkDetailWorkspace extends StatefulWidget {
  final AkashaItem item;
  final String tabId;
  final double infoPanelWidth;
  final bool infoPanelLocked;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final void Function(AkashaItem saved) onSaved;
  final VoidCallback onDeleted;
  final ValueChanged<bool> onDirtyChanged;

  const WorkDetailWorkspace({
    super.key,
    required this.item,
    required this.tabId,
    required this.infoPanelWidth,
    this.infoPanelLocked = false,
    this.onInfoWidthChanged,
    this.onToggleInfoLock,
    required this.onSaved,
    required this.onDeleted,
    required this.onDirtyChanged,
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

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _titleCtrl = TextEditingController(text: _item.title);
    _tagsCtrl = TextEditingController(text: _item.tags.join(', '));
    _posterUrlCtrl = TextEditingController(text: _item.posterPath ?? '');
    _loadDraftFromItem();
  }

  @override
  void didUpdateWidget(WorkDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      _item = widget.item;
      _titleCtrl.text = _item.title;
      _tagsCtrl.text = _item.tags.join(', ');
      _posterUrlCtrl.text = _item.posterPath ?? '';
      _loadDraftFromItem();
    }
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

  String get _previewBodyMarkdown {
    final draft = _applyDraft();
    return MarkdownBodyMerger.mergeBody(
      bodyRaw: draft.bodyRaw,
      synopsis: draft.description,
      quotes: draft.memorableQuotes,
      memo: draft.review,
    );
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
      setState(() => _posterUrlCtrl.text = selected);
      _markDirty();
    }
  }

  void _resetToDefaults() {
    WorkInfoDefaults.applyRegistryDefaults(_item);
    _titleCtrl.text = _item.title;
    _tagsCtrl.text = _item.tags.join(', ');
    _posterUrlCtrl.text = _item.posterPath ?? '';
    _loadDraftFromItem();
    _markDirty();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사전 기본값으로 되돌렸습니다. (work_id는 유지)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveArchive() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final draft = _applyDraft();
      final saved = await DetailArchiveSave.save(draft);
      if (!mounted) return;
      setState(() {
        _item = saved;
        _titleCtrl.text = saved.title;
        _tagsCtrl.text = saved.tags.join(', ');
        _posterUrlCtrl.text = saved.posterPath ?? '';
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

  Future<void> _confirmDelete() async {
    final service = AkashaFileService();
    final hasVault = service.vaultPath != null;
    final confirmed = await showDetailDeleteConfirmDialog(
      context,
      title: _item.title,
      hasVault: hasVault,
    );
    if (!confirmed || !mounted) return;

    final deleted = await service.deleteAkashaItem(_item);
    if (!mounted) return;

    if (hasVault && !deleted) {
      _showSnack('삭제할 파일을 찾지 못했습니다.');
      return;
    }
    _showSnack('"${_item.title}" 작품이 삭제되었습니다.');
    widget.onDeleted();
  }

  Future<void> _proposeCatalogFix() async {
    final saved = await showCatalogFixContributionDialog(context, item: _item);
    if (saved == true && mounted) {
      _showSnack('사전 수정 제안이 저장되었습니다.');
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
    final hasRegistry = WorksRegistry.getWorkById(
          WorksRegistry.resolveWorkId(_item.workId),
        ) !=
        null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkbenchResizablePanel(
          width: widget.infoPanelWidth,
          minWidth: 240,
          maxWidth: 480,
          locked: widget.infoPanelLocked,
          onWidthChanged: widget.onInfoWidthChanged,
          onToggleLock: widget.onToggleInfoLock,
          child: Container(
            color: const Color(0xFF1A1A28),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!vaultLinked)
                    Card(
                      color: Colors.amber.withValues(alpha: 0.12),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: const ListTile(
                        dense: true,
                        leading: Icon(Icons.folder_off_outlined,
                            color: Colors.amber, size: 20),
                        title: Text('볼트 미연동', style: TextStyle(fontSize: 12)),
                        subtitle: Text(
                          'md 생성·저장은 임시 저장만 됩니다.',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  Center(
                    child: GestureDetector(
                      onTap: _openPosterCorrection,
                      child: Container(
                        width: 120,
                        height: 168,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: gradColors,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: PosterImage(
                            item: preview,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 168,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    onChanged: (_) => _markDirty(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_item.creator.isNotEmpty)
                    Text(
                      _item.creator,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  if (_item.releaseYear != null)
                    Text(
                      '${_item.releaseYear}년',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 10),
                  InteractiveStarRating(
                    rating: _draftRating,
                    size: 22,
                    onChanged: (v) {
                      setState(() => _draftRating = v);
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 10),
                  _statusDropdown(
                    label: '작품 상태',
                    value: _draftWorkStatus,
                    options: _item.workStatusOptions,
                    onChanged: (v) {
                      setState(() => _draftWorkStatus = v);
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 8),
                  _statusDropdown(
                    label: '나의 상태',
                    value: _draftMyStatus,
                    options: _item.myStatusOptions,
                    onChanged: (v) {
                      setState(() => _draftMyStatus = v);
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('👑 Hall of Fame',
                        style: TextStyle(fontSize: 12)),
                    value: _draftHallOfFame,
                    onChanged: (v) {
                      setState(() => _draftHallOfFame = v);
                      _markDirty();
                    },
                  ),
                  TextField(
                    controller: _tagsCtrl,
                    onChanged: (_) => _markDirty(),
                    decoration: const InputDecoration(
                      labelText: '태그 (쉼표 구분)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_item.workId.isNotEmpty)
                    Text(
                      'work_id: ${_item.workId}',
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('기본값으로'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveArchive,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.description_outlined, size: 18),
                    label: Text(_isArchived ? 'md 저장' : 'md 생성'),
                  ),
                  if (hasRegistry) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _proposeCatalogFix,
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('사전 수정 제안'),
                    ),
                  ],
                  if (_isArchived) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: Colors.redAccent),
                      label: const Text('삭제',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFF12121A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          size: 18, color: Colors.tealAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Sanctum 페이지',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: VaultMarkdownBody(
                      data: _previewBodyMarkdown,
                      mdFilePath: _item.filePath,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          items: options
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
