import 'markdown_body_merger.dart';

/// Sanctum 아카이브 슬롯·메타 기준 완성도.
class SanctumArchiveCompletion {
  SanctumArchiveCompletion._();

  static const _slotLabels = {
    SanctumCompletionSlot.cast: '출연',
    SanctumCompletionSlot.gallery: '갤러리',
    SanctumCompletionSlot.synopsis: '시놉시스',
    SanctumCompletionSlot.quotes: '명장면',
    SanctumCompletionSlot.memo: '감상',
  };

  /// 본문 슬롯 5개 × 20% = 100%.
  static SanctumArchiveCompletionReport evaluate({
    required String bodyRaw,
  }) {
    final slots = MarkdownBodyMerger.parseSlots(bodyRaw);
    final filled = <SanctumCompletionSlot, bool>{
      SanctumCompletionSlot.cast: slots.cast.isNotEmpty,
      SanctumCompletionSlot.gallery: slots.gallery.isNotEmpty,
      SanctumCompletionSlot.synopsis: slots.synopsis.trim().isNotEmpty,
      SanctumCompletionSlot.quotes: slots.quotes.isNotEmpty,
      SanctumCompletionSlot.memo: slots.memo.trim().isNotEmpty,
    };

    final criteria = <SanctumCompletionCriterion>[];
    var earned = 0;
    for (final slot in SanctumCompletionSlot.values) {
      final done = filled[slot] ?? false;
      if (done) earned += 20;
      criteria.add(SanctumCompletionCriterion(
        slot: slot,
        label: _slotLabels[slot]!,
        filled: done,
      ));
    }

    return SanctumArchiveCompletionReport(
      percent: earned.clamp(0, 100),
      criteria: criteria,
    );
  }
}

enum SanctumCompletionSlot { cast, gallery, synopsis, quotes, memo }

class SanctumCompletionCriterion {
  const SanctumCompletionCriterion({
    required this.slot,
    required this.label,
    required this.filled,
  });

  final SanctumCompletionSlot slot;
  final String label;
  final bool filled;
}

class SanctumArchiveCompletionReport {
  const SanctumArchiveCompletionReport({
    required this.percent,
    required this.criteria,
  });

  final int percent;
  final List<SanctumCompletionCriterion> criteria;

  int get filledCount => criteria.where((c) => c.filled).length;
  int get totalCount => criteria.length;
}
