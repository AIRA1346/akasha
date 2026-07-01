import 'package:flutter/material.dart';

import '../../../config/catalog_contribution_config.dart';
import '../../../models/catalog_contribution.dart';
import '../../../models/enums.dart';
import '../../../services/catalog_contribution_service.dart';
import '../../../widgets/web_image_search_dialog.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/app_l10n.dart';

/// 글로벌 사전에 **신규 작품 추가 제안** (로컬 큐 — 자동 반영 없음)
Future<bool?> showCatalogAddContributionDialog(
  BuildContext context, {
  String? initialTitle,
  String? searchQuery,
}) async {
  final l10n = lookupAppL10n(context);
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
        title: Text(l10n?.catalogAddContributionTitle ?? '글로벌 사전 — 작품 추가 제안'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.catalogContributionDisclaimer ??
                      CatalogContributionConfig.disclaimerKo,
                  style: TextStyle(fontSize: 12, color: AkashaColors.textMuted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: l10n?.labelTitleRequired ?? '제목 *',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: creatorCtrl,
                  decoration: InputDecoration(
                    labelText: l10n?.labelCreator ?? '작가 / 제작사',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n?.labelReleaseYear ?? '출시 연도',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<MediaCategory>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: l10n?.labelCategory ?? '카테고리',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: MediaCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.localizedLabel(l10n)),
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
                        decoration: InputDecoration(
                          labelText: l10n?.labelPosterUrl ?? '포스터 URL (https)',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image_search),
                      tooltip: l10n?.tooltipImageSearch ?? '이미지 검색',
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
                  decoration: InputDecoration(
                    labelText: l10n?.labelDescriptionBrief ?? '설명 (직접 작성, 짧게)',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: anilistCtrl,
                  decoration: InputDecoration(
                    labelText: l10n?.labelAnilistId ?? 'AniList ID (선택, 숫자만)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n?.labelProposalNote ?? '제안 메모 (선택)',
                    border: const OutlineInputBorder(),
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
            child: Text(l10n?.actionCancel ?? '취소'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(l10n?.validationEnterTitle ?? '제목을 입력해 주세요.'),
                  ),
                );
                return;
              }
              final poster = posterCtrl.text.trim();
              if (poster.isNotEmpty && !poster.startsWith('http')) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.validationPosterHttpsOnly ??
                          '포스터는 https URL만 제안할 수 있습니다.',
                    ),
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
                  externalIds: anilist.isNotEmpty
                      ? {'anilist': anilist}
                      : const {},
                ),
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: Text(l10n?.actionSaveProposal ?? '제안 저장'),
          ),
        ],
      ),
    ),
  );
}
