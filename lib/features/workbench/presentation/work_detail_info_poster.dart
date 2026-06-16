import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../widgets/poster_image.dart';
import 'work_detail_poster_layout.dart';

/// 워크벤치 작품정보 패널 — 포스터 영역.
class WorkDetailInfoPoster extends StatelessWidget {
  const WorkDetailInfoPoster({
    super.key,
    required this.preview,
    required this.posterUrlCtrl,
    required this.gradColors,
    required this.maxWidth,
    required this.maxHeight,
    required this.onPosterTap,
  });

  final AkashaItem preview;
  final TextEditingController posterUrlCtrl;
  final List<Color> gradColors;
  final double maxWidth;
  final double maxHeight;
  final VoidCallback onPosterTap;

  @override
  Widget build(BuildContext context) {
    final bounds = infoPosterDisplayBounds(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    final width = bounds.width;
    final height = bounds.height;

    return GestureDetector(
      onTap: onPosterTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFF12121A),
          border: Border.all(color: const Color(0xFF2D2D44)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradColors.first.withValues(alpha: 0.25),
              const Color(0xFF12121A),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: width,
            height: height,
            child: PosterImage(
              key: ValueKey(posterUrlCtrl.text),
              item: preview,
              fit: BoxFit.contain,
              width: width,
              height: height,
            ),
          ),
        ),
      ),
    );
  }
}
