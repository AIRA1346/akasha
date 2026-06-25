import 'package:flutter/material.dart';

import '../../models/sanctum_gallery_entry.dart';
import '../../theme/akasha_colors.dart';
import 'sanctum_vault_image.dart';

/// Sanctum 미리보기 — 갤러리 가로 스크롤 스트립.
class SanctumGalleryStrip extends StatelessWidget {
  const SanctumGalleryStrip({
    super.key,
    required this.entries,
    this.mdFilePath,
  });

  final List<SanctumGalleryEntry> entries;
  final String? mdFilePath;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '갤러리',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 140,
                    child: SanctumVaultImage(
                      src: entry.imagePath,
                      mdFilePath: mdFilePath,
                      caption: entry.caption,
                      height: 100,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: AkashaColors.borderSubtle(0.08), height: 1),
        ],
      ),
    );
  }
}
