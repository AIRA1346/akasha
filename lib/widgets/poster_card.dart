import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../services/file_service.dart';
import '../services/image_cache_service.dart';
import 'star_rating.dart';
import 'safe_local_image.dart';

// ════════════════════════════════════════════════════════════════
//  포스터 카드 위젯 (옵시디언 대시보드 스타일)
// ════════════════════════════════════════════════════════════════

class PosterCard extends StatefulWidget {
  final AkashaItem item;
  final VoidCallback? onTap;

  const PosterCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  State<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<PosterCard> {
  bool _isHovered = false;
  File? _localCacheFile;

  @override
  void initState() {
    super.initState();
    _checkLocalCache();
  }

  @override
  void didUpdateWidget(PosterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.posterPath != widget.item.posterPath ||
        oldWidget.item.workId != widget.item.workId) {
      _checkLocalCache();
    }
  }

  Future<void> _checkLocalCache() async {
    final item = widget.item;
    if (item.posterPath != null && item.posterPath!.startsWith('http')) {
      final file = await ImageCacheService().getLocalPosterFile(item.workId, item.posterPath);
      if (file != null && await file.exists()) {
        if (mounted) {
          setState(() {
            _localCacheFile = file;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _localCacheFile = null;
          });
        }
        // 로컬 캐시가 없으면 다운로드 트리거
        _downloadPoster(item.workId, item.posterPath!);
      }
    } else {
      if (mounted) {
        setState(() {
          _localCacheFile = null;
        });
      }
    }
  }

  Future<void> _downloadPoster(String workId, String url) async {
    final file = await ImageCacheService().cachePosterImage(workId, url);
    if (file != null && await file.exists()) {
      if (mounted && widget.item.workId == workId) {
        setState(() {
          _localCacheFile = file;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final gradColors = categoryGradient(item.category);
    final dotColor = myStatusDotColor(item.myStatusLabel);

    // ── 아카이빙 상태별 테두리 및 글로우 스킨 판별 (Phase 6) ──
    final isNotStarted = item.myStatusLabel == '볼 예정' ||
                         item.myStatusLabel == '아직 안 봄' || 
                         item.myStatusLabel == '할 예정(백로그)';
    final isFinished = (item.workStatusLabel == '완결' || item.workStatusLabel == '출시됨') && 
                       (item.myStatusLabel == '전부 봄' || item.myStatusLabel == '클리어(완결)');

    Border cardBorder;
    Color glowColor;

    if (isNotStarted) {
      cardBorder = Border.all(
        color: Colors.white.withValues(alpha: 0.12),
        width: 1.5,
      );
      glowColor = gradColors[0];
    } else if (isFinished) {
      cardBorder = Border.all(
        color: const Color(0xFF9D4EDD).withValues(alpha: 0.7),
        width: 2.0,
      );
      glowColor = const Color(0xFF9D4EDD);
    } else {
      // 진행/연재 중
      cardBorder = Border.all(
        color: Colors.greenAccent.withValues(alpha: 0.6),
        width: 2.0,
      );
      glowColor = Colors.greenAccent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: _isHovered
              ? (Matrix4.identity()..translate(0.0, -4.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(10),
            border: cardBorder,
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isNotStarted ? 0.25 : 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 포스터 이미지 / 플레이스홀더 ──
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: _buildPoster(item, gradColors),
                ),
              ),

              // ── 메타데이터 텍스트 영역 ──
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // 작가
                      if (item.creator.isNotEmpty)
                        Text(
                          item.creator,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),

                      // 별점 / 평가 대기 (Phase 7)
                      if (item.rating > 0)
                        StarRating(rating: item.rating, size: 14)
                      else
                        const Row(
                          children: [
                            Text(
                              '⏳ 평가 대기',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 5),

                      // 상태 (이모지 매핑, Phase 7)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getStatusTextWithEmoji(item),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[300],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // 연도 (캘린더 이모지, Phase 7)
                      if (item.releaseYear != null)
                        Row(
                          children: [
                            Text(
                              '🗓️ ${item.releaseYear}년',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 포스터 이미지가 있으면 표시, 없으면 카테고리별 그라디언트 플레이스홀더
  Widget _buildPoster(AkashaItem item, List<Color> gradColors) {
    if (_localCacheFile != null) {
      return SafeLocalImage(
        file: _localCacheFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, error, stackTrace) {
          print('[PosterCard] IMAGE.FILE ERROR (cached) for ${item.title}: $error\n$stackTrace');
          return _buildGradientPlaceholder(item, gradColors);
        },
      );
    }

    if (item.posterPath != null) {
      if (item.posterPath!.startsWith('http')) {
        return Image.network(
          item.posterPath!,
          fit: BoxFit.cover,
          width: double.infinity,
          headers: const {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          },
          errorBuilder: (_, error, stackTrace) {
            print('[PosterCard] IMAGE.NETWORK ERROR for ${item.title}: $error\n$stackTrace');
            return _buildGradientPlaceholder(item, gradColors);
          },
        );
      } else {
        final absFile = File(item.posterPath!);
        if (absFile.existsSync()) {
          return SafeLocalImage(
            file: absFile,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, error, stackTrace) {
              print('[PosterCard] IMAGE.FILE ERROR (absFile) for ${item.title}: $error\n$stackTrace');
              return _buildGradientPlaceholder(item, gradColors);
            },
          );
        }
        final vaultPath = AkashaFileService().vaultPath;
        if (vaultPath != null) {
          final file = File(p.join(vaultPath, item.posterPath!));
          if (file.existsSync()) {
            return SafeLocalImage(
              file: file,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, error, stackTrace) {
                print('[PosterCard] IMAGE.FILE ERROR (vault) for ${item.title}: $error\n$stackTrace');
                return _buildGradientPlaceholder(item, gradColors);
              },
            );
          }
        }
      }
    }

    // 플레이스홀더
    return _buildGradientPlaceholder(item, gradColors);
  }

  /// 카테고리별 그라디언트 + 이니셜 플레이스홀더
  Widget _buildGradientPlaceholder(AkashaItem item, List<Color> gradColors) {
    return Container(
      width: double.infinity,
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

  /// 상태별 대응 이모지 텍스트 반환
  String _getStatusTextWithEmoji(AkashaItem item) {
    final label = item.myStatusLabel;
    if (label == '볼 예정' || label == '아직 안 봄' || label == '할 예정(백로그)') {
      return '🟣 볼 예정';
    } else if (label == '보는 중' || label == '플레이 중') {
      return '🟢 $label';
    } else if (label == '전부 봄' || label == '클리어(완결)') {
      return '🟣 $label';
    } else {
      return '⚪ $label';
    }
  }
}
