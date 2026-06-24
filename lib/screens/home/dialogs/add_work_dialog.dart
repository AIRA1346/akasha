import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../models/work_id_codec.dart';
import '../../../services/file_service.dart';
import '../../../services/works_registry.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/registry_work_autocomplete.dart';
import '../../../widgets/star_rating.dart';
import '../../../widgets/web_image_search_dialog.dart';

/// 신규 작품 등록(아카이브 추가) 다이얼로그
Future<AkashaItem?> showAddWorkDialog(
  BuildContext context, {
  String? initialTitle,
}) async {
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
          title: const Text('새 작품 등록 (아카이브 추가)'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '공통 작품 사전 검색',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                        yearCtrl.text =
                            selection.releaseYear?.toString() ?? '';
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
                    decoration: const InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: creatorCtrl,
                    enabled: !isPreRegistered,
                    decoration: const InputDecoration(
                      labelText: '작가 / 제작사',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: yearCtrl,
                    enabled: !isPreRegistered,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '출시 연도',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
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
                              initialQuery: titleCtrl.text,
                              category: selCategory,
                            ),
                          );
                          if (selectedUrl != null) {
                            posterUrlCtrl.text = selectedUrl;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '나의 별점',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  InteractiveStarRating(
                    rating: selRating,
                    onChanged: (v) => setD(() => selRating = v),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '카테고리',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<MediaCategory>(
                    initialValue: selCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: isPreRegistered
                        ? [
                            DropdownMenuItem(
                              value: selCategory,
                              child: Row(
                                children: [
                                  Icon(selCategory.icon, size: 18),
                                  const SizedBox(width: 8),
                                  Text(selCategory.label),
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
                                    Text(c.label),
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
                  const Text(
                    '작품 상태',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('add_work_${selCategory.name}'),
                    initialValue: selWork,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: workOpts
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setD(() => selWork = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '나의 상태',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('add_my_${selCategory.name}'),
                    initialValue: selMy,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: myOpts
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
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
              child: const Text('취소'),
            ),
            FilledButton.icon(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('제목을 입력해 주세요.')),
                  );
                  return;
                }
                Navigator.pop(
                  ctx,
                  createItem(
                    workId: selectedRegistryWork?.workId ??
                        WorkIdCodec.buildUserLocal(),
                    title: title,
                    category: selCategory,
                    domain: selDomain,
                    workStatus: selWork,
                    myStatus: selMy,
                    creator: creatorCtrl.text.trim(),
                    releaseYear: int.tryParse(yearCtrl.text.trim()),
                    rating: selRating,
                    posterPath: posterUrlCtrl.text.trim().isNotEmpty
                        ? posterUrlCtrl.text.trim()
                        : null,
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('등록'),
            ),
          ],
        );
      },
    ),
  );
}
