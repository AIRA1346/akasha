import 'package:flutter/material.dart';

import '../../../config/catalog_contribution_config.dart';
import '../../../models/akasha_item.dart';
import '../../../models/catalog_contribution.dart';
import '../../../services/catalog_contribution_service.dart';
import '../../../services/works_registry.dart';
import '../../../widgets/web_image_search_dialog.dart';

/// 기존 사전 작품 **수정 제안** (포스터·연도·제목 등)
Future<bool?> showCatalogFixContributionDialog(
  BuildContext context, {
  required AkashaItem item,
}) async {
  final resolvedId = WorksRegistry.resolveWorkId(item.workId);
  final registry = WorksRegistry.getWorkById(resolvedId);

  final issueCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final titleCtrl = TextEditingController(text: item.title);
  final creatorCtrl = TextEditingController(text: item.creator);
  final yearCtrl = TextEditingController(
    text: item.releaseYear?.toString() ?? registry?.releaseYear?.toString() ?? '',
  );
  final posterCtrl = TextEditingController(
    text: item.posterPath ?? registry?.posterPath ?? '',
  );

  bool fixPoster = false;
  bool fixYear = false;
  bool fixTitle = false;
  bool fixCreator = false;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('글로벌 사전 — 정보 수정 제안'),
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
                const SizedBox(height: 8),
                Text(
                  'workId: $resolvedId',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: issueCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '무엇이 틀렸나요? *',
                    hintText: '예: 포스터가 다른 작품 이미지입니다',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: fixPoster,
                  onChanged: (v) => setD(() => fixPoster = v ?? false),
                  title: const Text('포스터 URL 수정'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (fixPoster) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: posterCtrl,
                          decoration: const InputDecoration(
                            labelText: '제안 포스터 URL',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.image_search),
                        onPressed: () async {
                          final url = await showDialog<String>(
                            context: context,
                            builder: (_) => WebImageSearchDialog(
                              initialQuery: titleCtrl.text,
                              category: item.category,
                            ),
                          );
                          if (url != null) posterCtrl.text = url;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                CheckboxListTile(
                  value: fixYear,
                  onChanged: (v) => setD(() => fixYear = v ?? false),
                  title: const Text('출시 연도 수정'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (fixYear)
                  TextField(
                    controller: yearCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '제안 연도',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                CheckboxListTile(
                  value: fixTitle,
                  onChanged: (v) => setD(() => fixTitle = v ?? false),
                  title: const Text('제목 수정'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (fixTitle)
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: '제안 제목',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                CheckboxListTile(
                  value: fixCreator,
                  onChanged: (v) => setD(() => fixCreator = v ?? false),
                  title: const Text('작가/제작사 수정'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (fixCreator)
                  TextField(
                    controller: creatorCtrl,
                    decoration: const InputDecoration(
                      labelText: '제안 작가/제작사',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '추가 메모',
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
              final issue = issueCtrl.text.trim();
              if (issue.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('문제 설명을 입력해 주세요.')),
                );
                return;
              }
              if (!fixPoster && !fixYear && !fixTitle && !fixCreator) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('수정할 항목을 선택해 주세요.')),
                );
                return;
              }

              final fields = <String, dynamic>{};
              if (fixPoster) {
                final poster = posterCtrl.text.trim();
                if (poster.isNotEmpty && !poster.startsWith('http')) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('포스터는 https URL만 가능합니다.')),
                  );
                  return;
                }
                fields['posterPath'] = poster.isEmpty ? null : poster;
              }
              if (fixYear) {
                final year = int.tryParse(yearCtrl.text.trim());
                if (year == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('연도를 숫자로 입력해 주세요.')),
                  );
                  return;
                }
                fields['releaseYear'] = year;
              }
              if (fixTitle) {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('제목을 입력해 주세요.')),
                  );
                  return;
                }
                fields['title'] = title;
              }
              if (fixCreator) {
                fields['creator'] = creatorCtrl.text.trim();
              }

              await CatalogContributionService.instance.proposeFixWork(
                CatalogFixWorkProposal(
                  targetWorkId: resolvedId,
                  fields: fields,
                  issue: issue,
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
