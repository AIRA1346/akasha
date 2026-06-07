import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/akasha_item.dart';
import '../models/format_slot.dart';
import '../services/file_service.dart';
import '../services/franchise_fusion_service.dart';
import '../services/user_registry_preferences.dart';
import 'detail/detail_franchise_section.dart';
import 'detail/detail_profile_section.dart';
import 'detail/detail_section_title.dart';
import 'detail/dialogs/detail_delete_dialog.dart';
import 'detail/dialogs/detail_edit_dialog.dart';
import 'detail/dialogs/detail_quote_dialog.dart';
import 'detail/dialogs/detail_review_dialog.dart';

// ════════════════════════════════════════════════════════════════
//  작품 상세 페이지 (Detail Screen)
// ════════════════════════════════════════════════════════════════

class DetailScreen extends StatefulWidget {
  final AkashaItem item;

  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late AkashaItem item;
  bool _registryPrefsReady = false;
  List<FormatSlot> _formatSlots = const [];

  @override
  void initState() {
    super.initState();
    item = widget.item;
    _loadRegistryPrefs();
  }

  Future<void> _loadRegistryPrefs() async {
    if (!UserRegistryPreferences.instance.isLoaded) {
      await UserRegistryPreferences.instance.load();
    }
    await _loadFormatSlots();
  }

  Future<void> _loadFormatSlots() async {
    final service = AkashaFileService();
    List<AkashaItem> allItems;
    if (service.vaultPath != null) {
      allItems = await service.loadAllItems();
    } else {
      allItems = service.inMemoryCache.values.toList();
    }

    final slots = FranchiseFusionService.formatSlotsForWorkId(
      item.workId,
      allUserItems: allItems,
    );

    if (!mounted) return;
    setState(() {
      _registryPrefsReady = true;
      _formatSlots = slots;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _persistItem(BuildContext context) async {
    try {
      await AkashaFileService().saveItem(item);
      if (!context.mounted) return;
      _showSnack(
        AkashaFileService().vaultPath != null
            ? '마크다운 아카이브에 저장되었습니다.'
            : '변경 사항이 저장되었습니다. (볼트 연동 시 .md로 기록됩니다)',
      );
      await _loadFormatSlots();
    } catch (e) {
      if (!context.mounted) return;
      _showSnack('저장 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '편집',
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: '작품 삭제',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailProfileSection(item: item),
            const Divider(height: 32),
            if (_registryPrefsReady) ...[
              DetailFranchiseSection(
                item: item,
                formatSlots: _formatSlots,
                onPreferencesChanged: () => setState(() {}),
                onReloadFormatSlots: _loadFormatSlots,
                showSnackBar: _showSnack,
              ),
              const Divider(height: 32),
            ],
            if (item.description.isNotEmpty) ...[
              detailSectionTitle('📝', '작품 특징'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MarkdownBody(
                  data: item.description,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                    p: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),
            ],
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
            detailSectionTitle('🎬', '명장면 & 명대사'),
            if (item.memorableQuotes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '아직 등록된 명대사가 없습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...item.memorableQuotes.map((quote) => _buildQuoteCard(quote, cs)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () => _showAddQuoteDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('명대사 추가'),
              ),
            ),
            const Divider(height: 32),
            detailSectionTitle('📖', '감상문'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: item.review.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '아직 감상문이 작성되지 않았습니다.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showEditReviewDialog(context),
                          icon: const Icon(Icons.rate_review, size: 18),
                          label: const Text('감상문 작성'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.15),
                            ),
                          ),
                          child: MarkdownBody(
                            data: item.review,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(Theme.of(context))
                                    .copyWith(
                              p: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[300],
                                height: 1.7,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _showEditReviewDialog(context),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text(
                              '감상문 편집',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(String quote, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: cs.primary.withValues(alpha: 0.6),
              width: 3,
            ),
          ),
        ),
        child: Text(
          quote,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[300],
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final oldTitle = item.title;
    final result = await showDetailEditDialog(context, item);

    if (result != null) {
      final newTitle = result['title'] as String;
      setState(() {
        item.title = newTitle;
        item.setWorkStatus(result['work'] as String);
        item.setMyStatus(result['my'] as String);
        item.rating = result['rating'] as double;
        item.isHallOfFame = result['hof'] as bool;
        item.posterPath = result['poster'] as String?;
      });
      try {
        await AkashaFileService().saveItem(
          item,
          oldTitle: newTitle != oldTitle ? oldTitle : null,
        );
        if (!context.mounted) return;
        _showSnack(
          AkashaFileService().vaultPath != null
              ? '마크다운 아카이브에 저장되었습니다.'
              : '변경 사항이 저장되었습니다.',
        );
        await _loadFormatSlots();
      } catch (e) {
        if (!context.mounted) return;
        _showSnack('저장 실패: $e');
      }
    }
  }

  Future<void> _showAddQuoteDialog(BuildContext context) async {
    final result = await showAddQuoteDialog(context);
    if (result != null) {
      setState(() => item.memorableQuotes.add(result));
      await _persistItem(context);
    }
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

  Future<void> _showEditReviewDialog(BuildContext context) async {
    final result = await showEditReviewDialog(
      context,
      initialReview: item.review,
    );
    if (result != null) {
      setState(() => item.review = result);
      await _persistItem(context);
    }
  }
}
