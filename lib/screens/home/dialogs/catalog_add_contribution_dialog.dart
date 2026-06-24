import 'package:flutter/material.dart';

import '../../../config/catalog_contribution_config.dart';
import '../../../models/catalog_contribution.dart';
import '../../../models/enums.dart';
import '../../../services/catalog_contribution_service.dart';
import '../../../widgets/web_image_search_dialog.dart';

/// 글로벌 사전에 **신규 작품 추가 제안** (로컬 큐 — 자동 반영 없음)
Future<bool?> showCatalogAddContributionDialog(
  BuildContext context, {
  String? initialTitle,
  String? searchQuery,
}) async {
  final titleCtrl = TextEditingController(text: initialTitle ?? '');
  final creatorCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final posterCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final anilistCtrl = TextEditingController();
  final domain = AppDomain.newWorkDefault;
  MediaCategory category = MediaCategory.manga;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('글로벌 사전 — 작품 추가 제안'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CatalogContributionConfig.disclaimerKo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '제목 *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: creatorCtrl,
                  decoration: const InputDecoration(
                    labelText: '작가 / 제작사',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '출시 연도',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<MediaCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: MediaCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setD(() => category = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: posterCtrl,
                        decoration: const InputDecoration(
                          labelText: '포스터 URL (https)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image_search),
                      tooltip: '이미지 검색',
                      onPressed: () async {
                        final url = await showDialog<String>(
                          context: context,
                          builder: (_) => WebImageSearchDialog(
                            initialQuery: titleCtrl.text,
                            category: category,
                          ),
                        );
                        if (url != null) posterCtrl.text = url;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '설명 (직접 작성, 짧게)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: anilistCtrl,
                  decoration: const InputDecoration(
                    labelText: 'AniList ID (선택, 숫자만)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '제안 메모 (선택)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('제목을 입력해 주세요.')),
                );
                return;
              }
              final poster = posterCtrl.text.trim();
              if (poster.isNotEmpty && !poster.startsWith('http')) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('포스터는 https URL만 제안할 수 있습니다.'),
                  ),
                );
                return;
              }
              final anilist = anilistCtrl.text.trim();
              await CatalogContributionService.instance.proposeAddWork(
                CatalogAddWorkProposal(
                  title: title,
                  creator: creatorCtrl.text.trim(),
                  releaseYear: int.tryParse(yearCtrl.text.trim()),
                  category: category,
                  domain: domain,
                  posterPath: poster.isEmpty ? null : poster,
                  description: descCtrl.text.trim(),
                  searchQuery: searchQuery ?? initialTitle,
                  externalIds:
                      anilist.isNotEmpty ? {'anilist': anilist} : const {},
                ),
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('제안 저장'),
          ),
        ],
      ),
    ),
  );
}
