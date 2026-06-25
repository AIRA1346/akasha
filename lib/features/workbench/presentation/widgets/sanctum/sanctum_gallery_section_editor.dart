import 'package:flutter/material.dart';

import '../../../../../models/sanctum_gallery_entry.dart';
import '../../../../../services/sanctum_image_import.dart';
import '../../../../../theme/akasha_colors.dart';
import '../../../../../theme/akasha_radius.dart';
import '../../../../../theme/akasha_spacing.dart';
import '../../../../../theme/akasha_typography.dart';
import '../../../../../utils/vault_asset_resolver.dart';
import '../../../../../widgets/safe_local_image.dart';
import '../../../../../widgets/sanctum/sanctum_image_drop_zone.dart';

/// Sanctum 기록 탭 — `# 🖼 갤러리` 편집 UI.
class SanctumGallerySectionEditor extends StatelessWidget {
  const SanctumGallerySectionEditor({
    super.key,
    required this.entries,
    required this.onAdd,
    required this.onPaste,
    required this.onImportPaths,
    required this.onRemove,
  });

  final List<SanctumGalleryEntry> entries;
  final VoidCallback onAdd;
  final VoidCallback onPaste;
  final Future<void> Function(List<String> paths) onImportPaths;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return SanctumImageDropZone(
      enabled: SanctumImageImport.canImport,
      onImagesDropped: onImportPaths,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AkashaColors.surface.withValues(alpha: 0.35),
          borderRadius: AkashaRadius.mdBorder,
          border: Border.all(color: AkashaColors.borderSubtle(0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AkashaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 16, color: AkashaColors.accent),
                  const SizedBox(width: AkashaSpacing.sm),
                  Text('갤러리', style: AkashaTypography.sectionTitle),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onPaste,
                    icon: const Icon(Icons.content_paste_go_outlined, size: 16),
                    label: const Text('붙여넣기', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Colors.grey[400],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAdd,
                    icon:
                        const Icon(Icons.add_photo_alternate_outlined, size: 16),
                    label:
                        const Text('이미지 추가', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AkashaColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AkashaSpacing.sm),
              if (entries.isEmpty)
                Text(
                  '이미지를 끌어다 놓거나, 붙여넣기·추가로 스크린샷·콜라주를 넣을 수 있습니다.',
                  style: AkashaTypography.bodySecondary,
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(entries.length, (index) {
                      final entry = entries[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == entries.length - 1 ? 0 : 8,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: AkashaRadius.smBorder,
                              child: SizedBox(
                                width: 96,
                                height: 72,
                                child: _galleryThumb(entry.imagePath),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Material(
                                color: AkashaColors.workbenchPanel,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: () => onRemove(index),
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.close, size: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _galleryThumb(String imagePath) {
    final local = VaultAssetResolver.resolveImageFile(imagePath);
    if (local != null) {
      return SafeLocalImage(file: local, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: AkashaColors.workbenchEditor,
      child: Icon(Icons.broken_image, color: Colors.grey[600]),
    );
  }
}
