import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../models/akasha_item.dart';
import '../../../services/file_service.dart';
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
    final hasPoster = posterUrlCtrl.text.isNotEmpty;

    return GestureDetector(
      onTap: onPosterTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: maxWidth,
          height: height + 24,
          color: const Color(0xFF0F0F1A),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. 블러 백그라운드 (배경)
              if (hasPoster)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Opacity(
                      opacity: 0.35,
                      child: _BlurredPosterBackground(
                        path: posterUrlCtrl.text,
                      ),
                    ),
                  ),
                ),
              // 2. 앞단 메인 포스터 카드
              Container(
                width: width - 16,
                height: height - 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: PosterImage(
                    key: ValueKey(posterUrlCtrl.text),
                    item: preview,
                    fit: BoxFit.contain,
                    width: width - 16,
                    height: height - 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurredPosterBackground extends StatelessWidget {
  final String path;

  const _BlurredPosterBackground({
    required this.path,
  });

  bool _isNetworkUrl(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  File? _resolveLocalFile(String path) {
    final absFile = File(path);
    if (absFile.existsSync()) return absFile;

    final vaultPath = AkashaFileService().vaultPath;
    if (vaultPath != null) {
      final vaultFile = File(p.join(vaultPath, path));
      if (vaultFile.existsSync()) return vaultFile;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkUrl(path)) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    final localFile = _resolveLocalFile(path);
    if (localFile != null) {
      return Image.file(
        localFile,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }
}
