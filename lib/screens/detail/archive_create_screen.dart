import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/akasha_item.dart';
import '../../services/file_service.dart';
import '../../services/works_registry.dart';
import '../../utils/registry_extension_labels.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/web_image_search_dialog.dart';
/// 사전 작품을 Sanctum vault `.md`로 생성하기 위한 입력 화면.
class ArchiveCreateScreen extends StatefulWidget {
  final AkashaItem item;

  const ArchiveCreateScreen({super.key, required this.item});

  @override
  State<ArchiveCreateScreen> createState() => _ArchiveCreateScreenState();
}

class _ArchiveCreateScreenState extends State<ArchiveCreateScreen> {
  late AkashaItem _draft;
  late String _workStatus;
  late String _myStatus;
  late double _rating;
  String? _posterPath;
  bool _isSaving = false;

  final _quotesCtrl = TextEditingController();
  final _synopsisCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _posterUrlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = widget.item;
    _workStatus = _draft.workStatusLabel;
    _myStatus = _draft.myStatusLabel;
    _rating = _draft.rating;
    _posterPath = _draft.posterPath;
    if (_posterPath != null && _posterPath!.isNotEmpty) {
      _posterUrlCtrl.text = _posterPath!;
    }
  }

  @override
  void dispose() {
    _quotesCtrl.dispose();
    _synopsisCtrl.dispose();
    _memoCtrl.dispose();
    _posterUrlCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
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
        setState(() {
          _posterUrlCtrl.text = relativePath;
          _posterPath = relativePath;
        });
      }
    } else {
      setState(() {
        _posterUrlCtrl.text = path;
        _posterPath = path;
      });
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
      setState(() {
        _posterUrlCtrl.text = selectedUrl;
        _posterPath = selectedUrl;
      });
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
      } else {
        service.inMemoryCache[AkashaFileService.cacheKeyFor(item)] = item;
      }

      if (!mounted) return;
      _showSnack(
        service.vaultPath != null
            ? '"${item.title}" 아카이브를 생성했습니다.'
            : '"${item.title}"을(를) 임시 저장했습니다. 볼트 연동 시 .md로 기록됩니다.',
      );
      Navigator.pop(context, item);
    } catch (e) {
      if (mounted) _showSnack('생성 실패: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('아카이브 생성'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!vaultLinked)
              Card(
                color: Colors.amber.withValues(alpha: 0.12),
                child: const ListTile(
                  leading: Icon(Icons.folder_off_outlined, color: Colors.amber),
                  title: Text('Sanctum 볼트 미연동'),
                  subtitle: Text(
                    '볼트를 연동하면 .md 파일로 저장됩니다. '
                    '지금도 임시 저장 후 상세 화면으로 이동할 수 있습니다.',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _draft.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            if (_draft.creator.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _draft.creator,
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
            if (_draft.releaseYear != null) ...[
              const SizedBox(height: 6),
              Text(
                '${_draft.releaseYear}년 · ${_draft.category.label}',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
            const Divider(height: 32),
            const Text(
              '포스터 이미지',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: PosterImage(
                    item: previewItem,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 140,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                        onChanged: (v) => setState(() => _posterPath = v.trim()),
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
            const Text(
              '별점',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            InteractiveStarRating(
              rating: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 24),
            const Text(
              '작품 상태',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
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
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _workStatus = v);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '나의 상태',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
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
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _myStatus = v);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '명대사',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _quotesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '한 줄에 한 문장씩 입력',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '시놉시스',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _synopsisCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '줄거리·소개를 적어 주세요',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '메모',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _memoCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '감상·메모를 자유롭게 적어 주세요',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
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
                    : const Icon(Icons.add_circle_outline),
                label: Text(_isSaving ? '생성 중…' : '생성'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
