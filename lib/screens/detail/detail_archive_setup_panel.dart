import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/akasha_item.dart';
import '../../services/file_service.dart';
import '../../services/works_registry.dart';
import '../../utils/registry_extension_labels.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/web_image_search_dialog.dart';

/// 아카이브 미생성·자동 생성 stub 작품용 인라인 설정 패널.
/// 편집 다이얼로그 없이 포스터 URL·평점·상태를 입력하고 `.md`를 생성합니다.
class DetailArchiveSetupPanel extends StatefulWidget {
  final AkashaItem item;
  final ValueChanged<AkashaItem> onCreated;

  const DetailArchiveSetupPanel({
    super.key,
    required this.item,
    required this.onCreated,
  });

  @override
  State<DetailArchiveSetupPanel> createState() =>
      _DetailArchiveSetupPanelState();
}

class _DetailArchiveSetupPanelState extends State<DetailArchiveSetupPanel> {
  late AkashaItem _draft;
  late String _workStatus;
  late String _myStatus;
  late double _rating;
  bool _isSaving = false;
  bool _showOptionalFields = false;

  final _posterUrlCtrl = TextEditingController();
  final _quotesCtrl = TextEditingController();
  final _synopsisCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  bool get _isUpdate =>
      AkashaFileService().isArchivedInVault(_draft);

  @override
  void initState() {
    super.initState();
    _draft = widget.item;
    _workStatus = _draft.workStatusLabel;
    _myStatus = _draft.myStatusLabel;
    _rating = _draft.rating;
    final poster = _draft.posterPath;
    if (poster != null && poster.isNotEmpty) {
      _posterUrlCtrl.text = poster;
    }
  }

  @override
  void dispose() {
    _posterUrlCtrl.dispose();
    _quotesCtrl.dispose();
    _synopsisCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  List<String> _parseQuotes(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  AkashaItem _buildItemToSave() {
    final poster = _posterUrlCtrl.text.trim();
    _draft.rating = _rating;
    _draft.posterPath = poster.isNotEmpty ? poster : null;
    _draft.setWorkStatus(_workStatus);
    _draft.setMyStatus(_myStatus);
    _draft.description = _synopsisCtrl.text.trim();
    _draft.review = _memoCtrl.text.trim();
    _draft.memorableQuotes = _parseQuotes(_quotesCtrl.text);
    return _draft;
  }

  Future<void> _pickLocalPoster() async {
    final fileResult = await FilePicker.pickFiles(type: FileType.image);
    if (fileResult == null || fileResult.files.single.path == null) return;

    final path = fileResult.files.single.path!;
    final service = AkashaFileService();
    if (service.vaultPath != null) {
      final relativePath = await service.importPosterImage(path);
      if (relativePath != null) {
        setState(() => _posterUrlCtrl.text = relativePath);
      }
    } else {
      setState(() => _posterUrlCtrl.text = path);
    }
  }

  Future<void> _searchWebPoster() async {
    final selectedUrl = await showDialog<String>(
      context: context,
      builder: (searchCtx) => WebImageSearchDialog(
        initialQuery: _draft.title,
        category: _draft.category,
      ),
    );
    if (selectedUrl != null) {
      setState(() => _posterUrlCtrl.text = selectedUrl);
    }
  }

  Future<void> _createArchive() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    final item = _buildItemToSave();
    final service = AkashaFileService();

    try {
      if (service.vaultPath != null) {
        await service.saveItem(item);
        final reloaded = await _reloadSavedItem(item);
        if (!mounted) return;
        widget.onCreated(reloaded ?? item);
      } else {
        service.inMemoryCache[AkashaFileService.cacheKeyFor(item)] = item;
        if (!mounted) return;
        widget.onCreated(item);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<AkashaItem?> _reloadSavedItem(AkashaItem saved) async {
    final all = await AkashaFileService().loadAllItems();
    for (final loaded in all) {
      if (saved.workId.isNotEmpty && loaded.workId == saved.workId) {
        return loaded;
      }
      if (loaded.title == saved.title && loaded.category == saved.category) {
        return loaded;
      }
    }
    return null;
  }

  List<String> _registryExtensionLines() {
    if (_draft.workId.isEmpty) return const [];
    final work = WorksRegistry.getWorkById(_draft.workId);
    if (work == null) return const [];
    return formatRegistryExtensionLines(work);
  }

  @override
  Widget build(BuildContext context) {
    final vaultLinked = AkashaFileService().vaultPath != null;
    final previewItem = _buildItemToSave();
    final extensionLines = _registryExtensionLines();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!vaultLinked)
            Card(
              color: Colors.amber.withValues(alpha: 0.12),
              margin: const EdgeInsets.only(bottom: 16),
              child: const ListTile(
                leading: Icon(Icons.folder_off_outlined, color: Colors.amber),
                title: Text('Sanctum 볼트 미연동'),
                subtitle: Text(
                  '볼트를 연동하면 .md 파일로 저장됩니다. '
                  '지금은 임시 저장만 가능합니다.',
                ),
              ),
            ),
          Text(
            _draft.creator.isNotEmpty
                ? '${_draft.creator} · ${_draft.category.label}'
                : _draft.category.label,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          if (_draft.releaseYear != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_draft.releaseYear}년',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          ...extensionLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                line,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          detailInlineLabel('포스터 URL'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 136,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: PosterImage(
                  item: previewItem,
                  fit: BoxFit.cover,
                  width: 96,
                  height: 136,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _posterUrlCtrl,
                      decoration: InputDecoration(
                        hintText: 'https://... 또는 posters/...',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.folder_open),
                          tooltip: '로컬 이미지 선택',
                          onPressed: _pickLocalPoster,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _searchWebPoster,
                      icon: const Icon(Icons.image_search, size: 18),
                      label: const Text('웹 이미지 검색'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          detailInlineLabel('별점'),
          const SizedBox(height: 8),
          InteractiveStarRating(
            rating: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    detailInlineLabel('작품 상태'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _workStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _draft.workStatusOptions
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _workStatus = v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    detailInlineLabel('나의 상태'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _myStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _draft.myStatusOptions
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _myStatus = v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () =>
                setState(() => _showOptionalFields = !_showOptionalFields),
            icon: Icon(
              _showOptionalFields ? Icons.expand_less : Icons.expand_more,
            ),
            label: Text(
              _showOptionalFields ? '추가 기록 접기' : '명대사·시놉·메모 추가 (선택)',
            ),
          ),
          if (_showOptionalFields) ...[
            const SizedBox(height: 8),
            detailInlineLabel('명대사'),
            const SizedBox(height: 6),
            TextField(
              controller: _quotesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '한 줄에 한 문장씩',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            detailInlineLabel('시놉시스'),
            const SizedBox(height: 6),
            TextField(
              controller: _synopsisCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '줄거리·소개',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            detailInlineLabel('메모'),
            const SizedBox(height: 6),
            TextField(
              controller: _memoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '감상·메모',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _createArchive,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description_outlined),
              label: Text(
                _isSaving
                    ? '저장 중…'
                    : _isUpdate
                        ? 'md 저장'
                        : 'md 생성',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget detailInlineLabel(String text) {
  return Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
  );
}
