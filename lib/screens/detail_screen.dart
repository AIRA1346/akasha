import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../services/file_service.dart';
import '../services/markdown_body_merger.dart';
import '../services/works_registry.dart';
import '../widgets/vault_markdown_body.dart';
import '../widgets/web_image_search_dialog.dart';
import 'home/dialogs/catalog_fix_contribution_dialog.dart';
import 'detail/detail_archive_save.dart';
import 'detail/detail_profile_section.dart';
import 'detail/detail_section_title.dart';
import 'detail/dialogs/detail_delete_dialog.dart';

// ════════════════════════════════════════════════════════════════
//  작품 상세 페이지 — 프로필 + Sanctum md 페이지 + 빠른 편집
// ════════════════════════════════════════════════════════════════

class DetailScreen extends StatefulWidget {
  final AkashaItem item;

  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late AkashaItem item;
  bool _isSaving = false;

  late double _draftRating;
  late String _draftWorkStatus;
  late String _draftMyStatus;
  late bool _draftHallOfFame;
  bool _quickEditExpanded = false;

  final _posterUrlCtrl = TextEditingController();
  final _quotesCtrl = TextEditingController();
  final _synopsisCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    item = widget.item;
    _loadFieldsFromItem();
  }

  void _loadFieldsFromItem() {
    _draftRating = item.rating;
    _draftWorkStatus = item.workStatusLabel;
    _draftMyStatus = item.myStatusLabel;
    _draftHallOfFame = item.isHallOfFame;
    _posterUrlCtrl.text = item.posterPath ?? '';
    _quotesCtrl.text = item.memorableQuotes.join('\n');
    _synopsisCtrl.text = item.description;
    _memoCtrl.text = item.review;
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

  AkashaItem _applyFieldsToItem() {
    final poster = _posterUrlCtrl.text.trim();
    item.rating = _draftRating;
    item.posterPath = poster.isNotEmpty ? poster : null;
    item.setWorkStatus(_draftWorkStatus);
    item.setMyStatus(_draftMyStatus);
    item.isHallOfFame = _draftHallOfFame;
    item.description = _synopsisCtrl.text.trim();
    item.review = _memoCtrl.text.trim();
    item.memorableQuotes = _parseQuotes(_quotesCtrl.text);
    return item;
  }

  String get _previewBodyMarkdown => MarkdownBodyMerger.mergeBody(
        bodyRaw: item.bodyRaw,
        synopsis: _synopsisCtrl.text.trim(),
        quotes: _parseQuotes(_quotesCtrl.text),
        memo: _memoCtrl.text.trim(),
      );

  bool get _isArchived =>
      AkashaFileService().isArchivedInVault(item) ||
      AkashaFileService()
          .inMemoryCache
          .containsKey(AkashaFileService.cacheKeyFor(item));

  Future<void> _proposeCatalogFix(BuildContext context) async {
    final saved = await showCatalogFixContributionDialog(context, item: item);
    if (saved == true && mounted) {
      _showSnack('사전 수정 제안이 저장되었습니다. (제안함에서 export 가능)');
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
        initialQuery: item.title,
        category: item.category,
      ),
    );
    if (selected != null) {
      setState(() {
        _posterUrlCtrl.text = selected;
        _applyFieldsToItem();
      });
    }
  }

  Future<void> _saveArchive() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final draft = _applyFieldsToItem();
      final saved = await DetailArchiveSave.save(draft);
      if (!mounted) return;
      setState(() {
        item = saved;
        _loadFieldsFromItem();
      });
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vaultLinked = AkashaFileService().vaultPath != null;
    final previewItem = _applyFieldsToItem();

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          if (WorksRegistry.getWorkById(
                WorksRegistry.resolveWorkId(item.workId),
              ) !=
              null)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: '글로벌 사전 정보 수정 제안',
              onPressed: () => _proposeCatalogFix(context),
            ),
          if (_isArchived)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: '작품 삭제',
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!vaultLinked)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Card(
                  color: Colors.amber.withValues(alpha: 0.12),
                  child: const ListTile(
                    leading:
                        Icon(Icons.folder_off_outlined, color: Colors.amber),
                    title: Text('Sanctum 볼트 미연동'),
                    subtitle: Text(
                      '볼트를 연동하면 .md 파일로 저장됩니다. '
                      '지금은 임시 저장만 가능합니다.',
                    ),
                  ),
                ),
              ),
            DetailProfileSection(
              item: previewItem,
              editable: true,
              rating: _draftRating,
              onRatingChanged: (v) => setState(() => _draftRating = v),
              workStatus: _draftWorkStatus,
              myStatus: _draftMyStatus,
              onWorkStatusChanged: (v) => setState(() => _draftWorkStatus = v),
              onMyStatusChanged: (v) => setState(() => _draftMyStatus = v),
              onPosterTap: _openPosterCorrection,
              isHallOfFame: _draftHallOfFame,
              onHallOfFameChanged: (v) => setState(() => _draftHallOfFame = v),
            ),
            const Divider(height: 32),
            if (item.tags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: item.tags
                      .map(
                        (tag) => Chip(
                          label: Text(
                            '#$tag',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: cs.surfaceContainerHighest,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            detailSectionTitle('📖', 'Sanctum 페이지'),
            VaultMarkdownBody(
              data: _previewBodyMarkdown,
              mdFilePath: item.filePath,
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ExpansionTile(
                initiallyExpanded: _quickEditExpanded,
                onExpansionChanged: (v) =>
                    setState(() => _quickEditExpanded = v),
                title: const Text(
                  '빠른 편집',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '시놉·명대사·메모 — md 저장 시 Sanctum 페이지에 반영됩니다',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        detailSectionTitle('📋', '시놉시스'),
                        TextField(
                          controller: _synopsisCtrl,
                          maxLines: 5,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: '줄거리·소개를 적어 주세요',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        detailSectionTitle('🎬', '명장면 & 명대사'),
                        TextField(
                          controller: _quotesCtrl,
                          maxLines: 4,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: '한 줄에 한 문장씩 입력',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        detailSectionTitle('📝', '메모'),
                        TextField(
                          controller: _memoCtrl,
                          maxLines: 5,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: '감상·메모를 자유롭게 적어 주세요',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveArchive,
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
                  : _isArchived
                      ? 'md 저장'
                      : 'md 생성',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final service = AkashaFileService();
    final hasVault = service.vaultPath != null;

    final confirmed = await showDetailDeleteConfirmDialog(
      context,
      title: item.title,
      hasVault: hasVault,
    );
    if (!confirmed || !context.mounted) return;

    final deleted = await service.deleteAkashaItem(item);
    if (!context.mounted) return;

    if (hasVault) {
      if (deleted) {
        Navigator.pop(context, true);
        _showSnack('"${item.title}" 작품이 삭제되었습니다.');
      } else {
        _showSnack('삭제할 파일을 찾지 못했습니다.');
      }
    } else {
      Navigator.pop(context, true);
      _showSnack('"${item.title}" 이(가) 목록에서 제거되었습니다.');
    }
  }
}
