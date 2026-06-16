import 'package:flutter/material.dart';

import '../models/format_slot.dart';

/// 카드 하단 매체 칩 행 — **고정 높이 1줄** (+N 오버플로).
class FormatChipRow extends StatelessWidget {
  final List<FormatSlot> slots;
  final void Function(FormatSlot slot)? onHideSlot;

  const FormatChipRow({
    super.key,
    required this.slots,
    this.onHideSlot,
  });

  /// SliverGrid 고정 셀과 맞추기 위한 칩 영역 높이.
  static const double rowHeight = 32;

  static const double _spacing = 4;
  static const EdgeInsets _chipPadding =
      EdgeInsets.symmetric(horizontal: 6, vertical: 2);

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: rowHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          if (!maxWidth.isFinite || maxWidth <= 0) {
            return _chipRow(
              visible: slots.take(1).toList(),
              overflow: slots.skip(1).toList(),
            );
          }

          final split = _splitVisibleSlots(slots, maxWidth);
          return _chipRow(
            visible: split.$1,
            overflow: split.$2,
          );
        },
      ),
    );
  }

  Widget _chipRow({
    required List<FormatSlot> visible,
    required List<FormatSlot> overflow,
  }) {
    return Row(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: _spacing),
          _FormatChip(slot: visible[i], onHide: onHideSlot),
        ],
        if (overflow.isNotEmpty) ...[
          if (visible.isNotEmpty) const SizedBox(width: _spacing),
          _OverflowChip(
            count: overflow.length,
            hiddenLabels: overflow.map((s) => s.shortLabel).join(' · '),
          ),
        ],
      ],
    );
  }

  (List<FormatSlot>, List<FormatSlot>) _splitVisibleSlots(
    List<FormatSlot> slots,
    double maxWidth,
  ) {
    var visible = <FormatSlot>[];
    for (var i = 0; i < slots.length; i++) {
      final candidate = [...visible, slots[i]];
      final hiddenAfter = slots.length - candidate.length;
      final total = _rowWidth(
        candidate,
        overflowCount: hiddenAfter > 0 ? hiddenAfter : 0,
      );
      if (total <= maxWidth) {
        visible = candidate;
      } else {
        break;
      }
    }

    if (visible.isEmpty && slots.isNotEmpty) {
      return (const [], slots);
    }
    return (visible, slots.sublist(visible.length));
  }

  double _rowWidth(List<FormatSlot> visible, {required int overflowCount}) {
    if (visible.isEmpty && overflowCount == 0) return 0;
    var total = 0.0;
    for (var i = 0; i < visible.length; i++) {
      if (i > 0) total += _spacing;
      total += _chipWidth(visible[i]);
    }
    if (overflowCount > 0) {
      if (visible.isNotEmpty) total += _spacing;
      total += _overflowChipWidth(overflowCount);
    }
    return total;
  }

  static double _chipWidth(FormatSlot slot) {
    final labelWidth = _measureText(slot.shortLabel, _chipTextStyle(slot));
    return _chipPadding.horizontal + 10 + 3 + labelWidth;
  }

  static double _overflowChipWidth(int count) {
    final label = '+$count';
    return _chipPadding.horizontal + _measureText(label, _overflowTextStyle);
  }

  static double _measureText(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  static TextStyle _chipTextStyle(FormatSlot slot) {
    final isTracked = slot.state == FormatSlotState.tracked;
    return TextStyle(
      fontSize: 9,
      fontWeight: isTracked ? FontWeight.w600 : FontWeight.w500,
    );
  }

  static const TextStyle _overflowTextStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
  );
}

class _OverflowChip extends StatelessWidget {
  const _OverflowChip({
    required this.count,
    required this.hiddenLabels,
  });

  final int count;
  final String hiddenLabels;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hiddenLabels,
      child: Container(
        padding: FormatChipRow._chipPadding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          '+$count',
          style: FormatChipRow._overflowTextStyle.copyWith(
            color: Colors.grey[300],
          ),
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
      padding: FormatChipRow._chipPadding,
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
