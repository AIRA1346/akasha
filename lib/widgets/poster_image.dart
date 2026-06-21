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
//  - Tier 1 registry 포스터 없음 — 유저 URL/로컬만, 실패 시 플레이스홀더
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
class PosterImage extends StatefulWidget {
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
  State<PosterImage> createState() => _PosterImageState();
}

class _PosterImageState extends State<PosterImage> {
  late List<String> _networkCandidates;
  int _candidateIndex = 0;
  String? _trackedPosterPath;
  String _trackedWorkId = '';

  @override
  void initState() {
    super.initState();
    _trackedPosterPath = widget.item.posterPath;
    _trackedWorkId = widget.item.workId;
    _networkCandidates = _buildNetworkCandidates();
  }

  @override
  void didUpdateWidget(PosterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reloadIfPosterSourceChanged();
  }

  /// item 객체가 in-place로 바뀌어도 posterPath 변경을 감지
  void _reloadIfPosterSourceChanged() {
    final path = widget.item.posterPath;
    final workId = widget.item.workId;
    if (path == _trackedPosterPath && workId == _trackedWorkId) return;
    _trackedPosterPath = path;
    _trackedWorkId = workId;
    _candidateIndex = 0;
    _networkCandidates = _buildNetworkCandidates();
  }

  List<String> _buildNetworkCandidates() {
    final candidates = <String>[];
    final path = widget.item.posterPath;
    if (path != null && path.isNotEmpty && _isNetworkUrl(path)) {
      candidates.add(path);
    }
    return candidates;
  }

  void _tryNextCandidate() {
    if (_candidateIndex + 1 >= _networkCandidates.length) return;
    setState(() => _candidateIndex++);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = widget.width ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : null);
        final height = widget.height ??
            (constraints.hasBoundedHeight ? constraints.maxHeight : null);

        final placeholder = CategoryPosterPlaceholder(
          item: widget.item,
          fit: widget.fit,
          width: width,
          height: height,
        );

        if (_networkCandidates.isNotEmpty) {
          final url = _networkCandidates[_candidateIndex];
          return _boundedImage(
            width: width,
            height: height,
            placeholder: placeholder,
            image: Image.network(
              url,
              key: ValueKey(url),
              fit: widget.fit,
              width: width,
              height: height,
              headers: _networkImageHeaders,
              gaplessPlayback: true,
              errorBuilder: (_, error, stackTrace) {
                debugPrint(
                  '[PosterImage] NETWORK ERROR for ${widget.item.title} ($url): $error',
                );
                if (_candidateIndex + 1 < _networkCandidates.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _tryNextCandidate();
                  });
                }
                return placeholder;
              },
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return ShimmerLoadingPlaceholder(
                  width: width,
                  height: height,
                );
              },
            ),
          );
        }

        final path = widget.item.posterPath;
        if (path != null && path.isNotEmpty) {
          final localFile = _resolveLocalFile(path);
          if (localFile != null) {
            return _boundedImage(
              width: width,
              height: height,
              placeholder: placeholder,
              image: SafeLocalImage(
                file: localFile,
                fit: widget.fit,
                width: width,
                height: height,
                errorBuilder: (_, error, stackTrace) {
                  debugPrint(
                    '[PosterImage] LOCAL ERROR for ${widget.item.title}: $error\n$stackTrace',
                  );
                  return placeholder;
                },
              ),
            );
          }
        }

        return placeholder;
      },
    );
  }

  /// bounded 박스 — Image.fit=contain으로 레터박스 (FittedBox 이중 스케일 금지)
  Widget _boundedImage({
    required double? width,
    required double? height,
    required Widget placeholder,
    required Widget image,
  }) {
    if (width == null || height == null || width <= 0 || height <= 0) {
      return image;
    }
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: const Color(0xFF12121A),
        child: image,
      ),
    );
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

class ShimmerLoadingPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;

  const ShimmerLoadingPlaceholder({
    super.key,
    this.width,
    this.height,
  });

  @override
  State<ShimmerLoadingPlaceholder> createState() => _ShimmerLoadingPlaceholderState();
}

class _ShimmerLoadingPlaceholderState extends State<ShimmerLoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value * 3.0 - 1.0;
        return SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(value - 1.0, -0.3),
                end: Alignment(value, 0.3),
                colors: const [
                  Color(0xFF1E1E2F),
                  Color(0xFF2E2E42),
                  Color(0xFF1E1E2F),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}
