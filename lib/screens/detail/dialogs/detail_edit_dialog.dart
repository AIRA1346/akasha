import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../services/file_service.dart';
import '../../../widgets/star_rating.dart';
import '../../../widgets/web_image_search_dialog.dart';

/// 작품 정보 편집 다이얼로그 — 저장 시 결과 Map 반환
Future<Map<String, dynamic>?> showDetailEditDialog(
  BuildContext context,
  AkashaItem item,
) async {
  final titleCtrl = TextEditingController(text: item.title);
  String currentWork = item.workStatusLabel;
  String currentMy = item.myStatusLabel;
  double currentRating = item.rating;
  bool currentHoF = item.isHallOfFame;
  final posterUrlCtrl = TextEditingController(text: item.posterPath ?? '');

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('작품 정보 편집'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '제목',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '포스터 이미지 (웹 URL 또는 로컬 파일)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
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
                            if (fileResult != null &&
                                fileResult.files.single.path != null) {
                              final path = fileResult.files.single.path!;
                              final service = AkashaFileService();
                              if (service.vaultPath != null) {
                                final relativePath =
                                    await service.importPosterImage(path);
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
                        builder: (searchCtx) => WebImageSearchDialog(
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
              const Text(
                '별점',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              InteractiveStarRating(
                rating: currentRating,
                onChanged: (v) => setD(() => currentRating = v),
              ),
              const SizedBox(height: 20),
              const Text(
                '작품 상태',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: currentWork,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: item.workStatusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setD(() => currentWork = v);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                '나의 상태',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: currentMy,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: item.myStatusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setD(() => currentMy = v);
                },
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('👑 Hall of Fame', style: TextStyle(fontSize: 14)),
                subtitle: const Text('인생 명작 컬렉션에 등록', style: TextStyle(fontSize: 11)),
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
}
