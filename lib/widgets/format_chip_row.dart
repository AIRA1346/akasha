import 'package:flutter/material.dart';
import '../models/format_slot.dart';

/// 카드 하단 매체 칩 행
class FormatChipRow extends StatelessWidget {
  final List<FormatSlot> slots;
  final void Function(FormatSlot slot)? onHideSlot;

  const FormatChipRow({
    super.key,
    required this.slots,
    this.onHideSlot,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 22,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, i) => _FormatChip(
          slot: slots[i],
          onHide: onHideSlot,
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final FormatSlot slot;
  final void Function(FormatSlot slot)? onHide;

  const _FormatChip({required this.slot, this.onHide});

  @override
  Widget build(BuildContext context) {
    final isTracked = slot.state == FormatSlotState.tracked;
    final isHidden = slot.state == FormatSlotState.hidden;
    final dimmed = slot.dimmedByFilter || isHidden;

    Color borderColor;
    Color bgColor;
    Color textColor;

    if (isTracked) {
      borderColor = const Color(0xFFCCCCCC);
      bgColor = Colors.white.withValues(alpha: 0.14);
      textColor = const Color(0xFFE8E8E8);
    } else if (isHidden) {
      borderColor = Colors.grey.withValues(alpha: 0.25);
      bgColor = Colors.transparent;
      textColor = Colors.grey[600]!;
    } else {
      borderColor = Colors.grey.withValues(alpha: 0.35);
      bgColor = Colors.transparent;
      textColor = Colors.grey[400]!;
    }

    if (dimmed && !isHidden) {
      textColor = Colors.grey[600]!;
      borderColor = Colors.grey.withValues(alpha: 0.2);
    }

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            slot.category.icon,
            size: 10,
            color: textColor,
          ),
          const SizedBox(width: 3),
          Text(
            slot.shortLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isTracked ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
              decoration: isHidden ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );

    if (onHide == null ||
        isTracked ||
        isHidden ||
        slot.state != FormatSlotState.catalogOnly) {
      return chip;
    }

    return GestureDetector(
      onLongPress: () => onHide!(slot),
      child: Tooltip(
        message: '길게 눌러 이 매체 숨기기',
        child: chip,
      ),
    );
  }
}
