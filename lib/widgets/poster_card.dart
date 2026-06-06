import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import 'poster_image.dart';
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

    final isNotStarted = item.myStatusLabel == '볼 예정' ||
        item.myStatusLabel == '아직 안 봄' ||
        item.myStatusLabel == '할 예정(백로그)';
    final isFinished =
        (item.workStatusLabel == '완결' || item.workStatusLabel == '출시됨') &&
            (item.myStatusLabel == '전부 봄' ||
                item.myStatusLabel == '클리어(완결)');

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
                      color:
                          glowColor.withValues(alpha: isNotStarted ? 0.25 : 0.4),
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
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: PosterImage(
                    item: item,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

  String _getStatusTextWithEmoji(AkashaItem item) {
    final label = item.myStatusLabel;
    if (label == '볼 예정' ||
        label == '아직 안 봄' ||
        label == '할 예정(백로그)') {
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
