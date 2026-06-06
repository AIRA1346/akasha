import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/akasha_item.dart';
import '../models/enums.dart';
import '../services/file_service.dart';
import 'safe_local_image.dart';

// ════════════════════════════════════════════════════════════════
//  포스터 이미지 뷰어 (링크 참조 + 사용자 로컬 이미지 2출처 정책)
//  - HTTP URL: Image.network 자체 캐싱만 사용 (디스크 다운로드 금지)
//  - 로컬: vault/posters/ 상대경로 또는 사용자 파일
//  - 실패 시: 카테고리 플레이스홀더
// ════════════════════════════════════════════════════════════════

const _networkImageHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

/// 카테고리별 그라디언트 + 아이콘 플레이스홀더
class CategoryPosterPlaceholder extends StatelessWidget {
  final AkashaItem item;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CategoryPosterPlaceholder({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final gradColors = categoryGradient(item.category);
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.category.icon,
              size: 38,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 포스터 표시 위젯 — 외부 URL은 Image.network만, 로컬은 SafeLocalImage
class PosterImage extends StatelessWidget {
  final AkashaItem item;
  final BoxFit fit;
  final double? width;
  final double? height;

  const PosterImage({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = CategoryPosterPlaceholder(
      item: item,
      fit: fit,
      width: width,
      height: height,
    );

    final path = item.posterPath;
    if (path == null || path.isEmpty) {
      return placeholder;
    }

    if (_isNetworkUrl(path)) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        headers: _networkImageHeaders,
        gaplessPlayback: true,
        errorBuilder: (_, error, stackTrace) {
          debugPrint(
            '[PosterImage] NETWORK ERROR for ${item.title}: $error\n$stackTrace',
          );
          return placeholder;
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
      );
    }

    final localFile = _resolveLocalFile(path);
    if (localFile != null) {
      return SafeLocalImage(
        file: localFile,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, error, stackTrace) {
          debugPrint(
            '[PosterImage] LOCAL ERROR for ${item.title}: $error\n$stackTrace',
          );
          return placeholder;
        },
      );
    }

    return placeholder;
  }

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
}
