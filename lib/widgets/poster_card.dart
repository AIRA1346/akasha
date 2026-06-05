import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../services/file_service.dart';
import 'star_rating.dart';

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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final gradColors = categoryGradient(item.category);
    final dotColor = myStatusDotColor(item.myStatusLabel);

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
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: gradColors[0].withValues(alpha: 0.3),
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

                      // 별점
                      if (item.rating > 0)
                        StarRating(rating: item.rating, size: 14),
                      const SizedBox(height: 4),

                      // 상태 (컬러 도트 + 텍스트)
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.combinedStatusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // 연도
                      if (item.releaseYear != null)
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 10, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${item.releaseYear}년',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
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
    if (item.posterPath != null) {
      if (item.posterPath!.startsWith('http')) {
        return Image.network(
          item.posterPath!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) =>
              _buildGradientPlaceholder(item, gradColors),
        );
      } else {
        final vaultPath = AkashaFileService().vaultPath;
        if (vaultPath != null) {
          final file = File(p.join(vaultPath, item.posterPath!));
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) =>
                  _buildGradientPlaceholder(item, gradColors),
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
              size: 32,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
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
