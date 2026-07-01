import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/ports/vault_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/category_descriptor.dart';
import '../../../models/enums.dart';
import '../../../models/work_id_codec.dart';
import '../../../services/poster_url_localizer.dart';
import '../../../services/works_registry.dart';
import '../../../utils/app_l10n.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/registry_work_autocomplete.dart';
import '../../../widgets/star_rating.dart';
import '../../../widgets/web_image_search_dialog.dart';

/// 신규 작품 등록(아카이브 추가) 다이얼로그
Future<AkashaItem?> showAddWorkDialog(
  BuildContext context, {
  String? initialTitle,
  VaultPort? vault,
}) async {
  final l10n = lookupAppL10n(context);
  final titleCtrl = TextEditingController(text: initialTitle ?? '');
  final creatorCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final posterUrlCtrl = TextEditingController();
  AppDomain selDomain = AppDomain.newWorkDefault;
  MediaCategory selCategory = MediaCategory.manga;
  String selWork = workStatusOptionsFor(selCategory).first;
  String selMy = myStatusOptionsFor(selCategory).first;
  double selRating = 0.0;
  RegistryWork? selectedRegistryWork;

  return showDialog<AkashaItem>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        final workOpts = workStatusOptionsFor(selCategory);
        final myOpts = myStatusOptionsFor(selCategory);

        if (!workOpts.contains(selWork)) selWork = workOpts.first;
        if (!myOpts.contains(selMy)) selMy = myOpts.first;

        final bool isPreRegistered = selectedRegistryWork != null;

        return AlertDialog(
          title: Text(l10n?.addWorkDialogTitle ?? '새 작품 등록 (아카이브 추가)'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.registryWorkSearch ?? '공통 작품 사전 검색',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RegistryWorkAutocomplete(
                    selectedWork: selectedRegistryWork,
                    onSelected: (selection) {
                      setD(() {
                        if (selection == null) {
                          selectedRegistryWork = null;
                          titleCtrl.clear();
                          creatorCtrl.clear();
                          yearCtrl.clear();
                          posterUrlCtrl.clear();
                          selDomain = AppDomain.newWorkDefault;
                          return;
                        }
                        selectedRegistryWork = selection;
                        titleCtrl.text = selection.title;
                        creatorCtrl.text = selection.creator;
                        yearCtrl.text = selection.releaseYear?.toString() ?? '';
                        posterUrlCtrl.text = selection.posterPath ?? '';
                        selCategory = selection.category;
                        selDomain = selection.domain;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    enabled: !isPreRegistered,
                    decoration: InputDecoration(
                      labelText: l10n?.labelTitle ?? '제목',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.title),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: creatorCtrl,
                    enabled: !isPreRegistered,
                    decoration: InputDecoration(
                      labelText: l10n?.labelCreator ?? '작가 / 제작사',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: yearCtrl,
                    enabled: !isPreRegistered,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n?.labelReleaseYear ?? '출시 연도',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n?.posterImageLabel ?? '포스터 이미지 (웹 URL 또는 로컬 파일)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: posterUrlCtrl,
                          decoration: InputDecoration(
                            hintText:
                                l10n?.posterUrlHint ??
                                'https://... 또는 로컬 경로 입력',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.folder_open),
                              tooltip:
                                  l10n?.tooltipPickLocalImage ?? '로컬 이미지 파일 선택',
                              onPressed: () async {
                                final fileResult = await FilePicker.pickFiles(
                                  type: FileType.image,
                                );
                                if (fileResult != null &&
                                    fileResult.files.single.path != null) {
                                  final path = fileResult.files.single.path!;
                                  if (vault?.vaultPath != null) {
                                    final relativePath = await vault!
                                        .importPosterImage(path);
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
                        tooltip: l10n?.tooltipWebImageSearch ?? '인터넷 이미지 검색',
                        onPressed: () async {
                          final selectedUrl = await showDialog<String>(
                            context: context,
                            builder: (searchCtx) => WebImageSearchDialog(
                              initialQuery: titleCtrl.text,
                              category: selCategory,
                            ),
                          );
                          if (selectedUrl != null) {
                            final resolved =
                                await PosterUrlLocalizer.applyWithSnackBar(
                                  selectedUrl,
                                  showSnack: (message) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  },
                                );
                            posterUrlCtrl.text = resolved;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n?.myRating ?? '나의 별점',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InteractiveStarRating(
                    rating: selRating,
                    onChanged: (v) => setD(() => selRating = v),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n?.labelCategory ?? '카테고리',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<MediaCategory>(
                    initialValue: selCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: isPreRegistered
                        ? [
                            DropdownMenuItem(
                              value: selCategory,
                              child: Row(
                                children: [
                                  Icon(selCategory.icon, size: 18),
                                  const SizedBox(width: 8),
                                  Text(selCategory.localizedLabel(l10n)),
                                ],
                              ),
                            ),
                          ]
                        : MediaCategory.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Row(
                                    children: [
                                      Icon(c.icon, size: 18),
                                      const SizedBox(width: 8),
                                      Text(c.localizedLabel(l10n)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    onChanged: isPreRegistered
                        ? null
                        : (v) {
                            if (v != null) {
                              setD(() {
                                selCategory = v;
                                selWork = workStatusOptionsFor(v).first;
                                selMy = myStatusOptionsFor(v).first;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n?.labelWorkStatus ?? '작품 상태',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('add_work_${selCategory.name}'),
                    initialValue: selWork,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: workOpts.map((s) {
                      final status = CategoryRegistry.isContentType(selCategory)
                          ? ContentWorkStatus.fromStorage(s)
                          : GameWorkStatus.fromStorage(s);
                      final display =
                          CategoryRegistry.isContentType(selCategory)
                          ? (status as ContentWorkStatus).localizedLabel(l10n)
                          : (status as GameWorkStatus).localizedLabel(l10n);
                      return DropdownMenuItem(value: s, child: Text(display));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setD(() => selWork = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n?.labelMyStatus ?? '나의 상태',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('add_my_${selCategory.name}'),
                    initialValue: selMy,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: myOpts.map((s) {
                      final status = CategoryRegistry.isContentType(selCategory)
                          ? ContentMyStatus.fromStorage(s)
                          : GameMyStatus.fromStorage(s);
                      final display =
                          CategoryRegistry.isContentType(selCategory)
                          ? (status as ContentMyStatus).localizedLabel(l10n)
                          : (status as GameMyStatus).localizedLabel(l10n);
                      return DropdownMenuItem(value: s, child: Text(display));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setD(() => selMy = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n?.actionCancel ?? '취소'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.validationEnterTitle ?? '제목을 입력해 주세요.',
                      ),
                    ),
                  );
                  return;
                }
                final rawPoster = posterUrlCtrl.text.trim();
                final posterPath = rawPoster.isEmpty
                    ? null
                    : await PosterUrlLocalizer.applyWithSnackBar(
                        rawPoster,
                        showSnack: (message) {
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        },
                      );
                if (!ctx.mounted) return;
                Navigator.pop(
                  ctx,
                  createItem(
                    workId:
                        selectedRegistryWork?.workId ??
                        WorkIdCodec.buildUserLocal(),
                    title: title,
                    category: selCategory,
                    domain: selDomain,
                    workStatus: selWork,
                    myStatus: selMy,
                    creator: creatorCtrl.text.trim(),
                    releaseYear: int.tryParse(yearCtrl.text.trim()),
                    rating: selRating,
                    posterPath: posterPath != null && posterPath.isNotEmpty
                        ? posterPath
                        : null,
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: Text(l10n?.actionRegister ?? '등록'),
            ),
          ],
        );
      },
    ),
  );
}
