import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../services/file_service.dart';
import '../utils/helpers.dart';
import '../widgets/star_rating.dart';
import '../widgets/poster_image.dart';
import '../widgets/web_image_search_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  Future<void> _persistItem(BuildContext context) async {
    try {
      await AkashaFileService().saveItem(item);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AkashaFileService().vaultPath != null
                ? '마크다운 아카이브에 저장되었습니다.'
                : '변경 사항이 저장되었습니다. (볼트 연동 시 .md로 기록됩니다)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradColors = categoryGradient(item.category);

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
            // ━━━ 상단 프로필 섹션 ━━━
            _buildProfileSection(cs, gradColors),
            const Divider(height: 32),

            // ━━━ 작품 특징 ━━━
            if (item.description.isNotEmpty) ...[
              _sectionTitle('📝', '작품 특징'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MarkdownBody(
                  data: item.description,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
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

            // ━━━ 태그 ━━━
            if (item.tags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: item.tags
                      .map((tag) => Chip(
                            label: Text('#$tag',
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor: cs.surfaceContainerHighest,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ━━━ 명장면 & 명대사 ━━━
            _sectionTitle('🎬', '명장면 & 명대사'),
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

            // ━━━ 감상문 ━━━
            _sectionTitle('📖', '감상문'),
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
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
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
                            label: const Text('감상문 편집',
                                style: TextStyle(fontSize: 12)),
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

  // ── 프로필 섹션 ──────────────────────────

  Widget _buildProfileSection(ColorScheme cs, List<Color> gradColors) {
    final dotColor = myStatusDotColor(item.myStatusLabel);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 포스터 썸네일
          Container(
            width: 140,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradColors[0].withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PosterImage(
                item: item,
                fit: BoxFit.cover,
                width: 140,
                height: 190,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // 메타데이터
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),

                // 작가
                if (item.creator.isNotEmpty)
                  Text(
                    item.creator,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                const SizedBox(height: 12),

                // 별점
                Row(
                  children: [
                    StarRating(rating: item.rating, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 연도
                if (item.releaseYear != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        '${item.releaseYear}년',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // 상태
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.combinedStatusLabel,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 카테고리 칩
                Chip(
                  avatar: Icon(item.category.icon, size: 14),
                  label: Text(item.category.label,
                      style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),

                // Hall of Fame 배지
                if (item.isHallOfFame) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('👑', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          'Hall of Fame',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 섹션 타이틀 ──

  Widget _sectionTitle(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── 명대사 카드 ──

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

  // ── 편집 다이얼로그 ───────────────────────

  Future<void> _showEditDialog(BuildContext context) async {
    final oldTitle = item.title;
    final titleCtrl = TextEditingController(text: item.title);
    String currentWork = item.workStatusLabel;
    String currentMy = item.myStatusLabel;
    double currentRating = item.rating;
    bool currentHoF = item.isHallOfFame;
    final posterUrlCtrl = TextEditingController(text: item.posterPath ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('작품 정보 편집'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('제목',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                // 포스터 이미지
                const Text('포스터 이미지 (웹 URL 또는 로컬 파일)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: posterUrlCtrl,
                        decoration: InputDecoration(
                          hintText: 'https://... 또는 로컬 경로 입력',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.folder_open),
                            tooltip: '로컬 이미지 파일 선택',
                            onPressed: () async {
                              final fileResult = await FilePicker.pickFiles(
                                type: FileType.image,
                              );
                              if (fileResult != null && fileResult.files.single.path != null) {
                                final path = fileResult.files.single.path!;
                                final service = AkashaFileService();
                                if (service.vaultPath != null) {
                                  final relativePath = await service.importPosterImage(path);
                                  if (relativePath != null) {
                                    posterUrlCtrl.text = relativePath;
                                  }
                                } else {
                                  posterUrlCtrl.text = path;
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.image_search),
                      tooltip: '인터넷 이미지 검색',
                      onPressed: () async {
                        final selectedUrl = await showDialog<String>(
                          context: context,
                          builder: (ctx) => WebImageSearchDialog(
                            initialQuery: item.title,
                            category: item.category,
                          ),
                        );
                        if (selectedUrl != null) {
                          posterUrlCtrl.text = selectedUrl;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 별점
                const Text('별점',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                InteractiveStarRating(
                  rating: currentRating,
                  onChanged: (v) => setD(() => currentRating = v),
                ),
                const SizedBox(height: 20),

                // 작품 상태
                const Text('작품 상태',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: currentWork,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: item.workStatusOptions
                      .map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setD(() => currentWork = v);
                  },
                ),
                const SizedBox(height: 20),

                // 나의 상태
                const Text('나의 상태',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: currentMy,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: item.myStatusOptions
                      .map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setD(() => currentMy = v);
                  },
                ),
                const SizedBox(height: 20),

                // Hall of Fame 토글
                SwitchListTile(
                  title: const Text('👑 Hall of Fame',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text('인생 명작 컬렉션에 등록',
                      style: TextStyle(fontSize: 11)),
                  value: currentHoF,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setD(() => currentHoF = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(ctx, {
                  'title': title,
                  'work': currentWork,
                  'my': currentMy,
                  'rating': currentRating,
                  'hof': currentHoF,
                  'poster': posterUrlCtrl.text.trim().isNotEmpty
                      ? posterUrlCtrl.text.trim()
                      : null,
                });
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AkashaFileService().vaultPath != null
                  ? '마크다운 아카이브에 저장되었습니다.'
                  : '변경 사항이 저장되었습니다.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  // ── 명대사 추가 다이얼로그 ──

  Future<void> _showAddQuoteDialog(BuildContext context) async {
    final ctrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎬 명대사 추가'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                '"대사 내용" — 캐릭터 이름 / 상황 설명',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => item.memorableQuotes.add(result));
      await _persistItem(context);
    }
  }

  // ── 작품 삭제 ──

  Future<void> _confirmDelete(BuildContext context) async {
    final service = AkashaFileService();
    final hasVault = service.vaultPath != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗑️ 작품 삭제'),
        content: Text(
          hasVault
              ? '"${item.title}" 작품을 아카이브에서 삭제할까요?\n로컬 볼트의 .md 파일이 영구 삭제됩니다.'
              : '"${item.title}" 작품을 목록에서 제거할까요?\n(데모 모드 — 볼트 연동 시 .md 파일이 삭제됩니다)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await service.deleteAkashaItem(item);
    if (!context.mounted) return;

    if (hasVault) {
      if (deleted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${item.title}" 작품이 삭제되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제할 파일을 찾지 못했습니다.')),
        );
      }
    } else {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.title}" 이(가) 목록에서 제거되었습니다.')),
      );
    }
  }

  // ── 감상문 편집 다이얼로그 ──

  Future<void> _showEditReviewDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: item.review);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📖 감상문 편집'),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: ctrl,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: '이 작품에 대한 감상을 자유롭게 적어주세요...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => item.review = result);
      await _persistItem(context);
    }
  }
}
