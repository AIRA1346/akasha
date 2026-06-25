import 'package:flutter/material.dart';
import '../theme/akasha_colors.dart';

// ════════════════════════════════════════════════════════════════
//  별점 표시 위젯 (커스텀, 외부 패키지 불필요)
// ════════════════════════════════════════════════════════════════

/// 읽기 전용 별점 표시 위젯.
/// [rating]은 0.0~5.0 범위의 double 값이며,
/// 반 별(half star) 단위를 지원한다.
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final Color emptyColor;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = Colors.amber,
    this.emptyColor = AkashaColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        IconData icon;
        Color starColor;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
          starColor = color;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
          starColor = color;
        } else {
          icon = Icons.star_border_rounded;
          starColor = emptyColor.withValues(alpha: 0.3);
        }

        return Icon(icon, size: size, color: starColor);
      }),
    );
  }
}

/// 인터랙티브 별점 입력 위젯.
/// 탭하여 0.5 단위로 별점을 설정할 수 있다.
class InteractiveStarRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;
  final double size;
  final Color color;

  const InteractiveStarRating({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 32,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return GestureDetector(
          onTapDown: (details) {
            // 별의 왼쪽 절반을 탭하면 0.5, 오른쪽이면 1.0
            final half = details.localPosition.dx < size / 2;
            onChanged(half ? starValue - 0.5 : starValue.toDouble());
          },
          child: Icon(
            rating >= starValue
                ? Icons.star_rounded
                : (rating >= starValue - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_border_rounded),
            size: size,
            color: rating >= starValue - 0.5 ? color : AkashaColors.textMuted.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}
