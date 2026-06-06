import '../models/akasha_item.dart';

/// 오늘의 회상 — 날짜 기준 결정적(deterministic) 명대사 선택
class DailyRecall {
  final AkashaItem item;
  final String quote;

  const DailyRecall({required this.item, required this.quote});
}

class RecallPicker {
  static DailyRecall? pickDailyRecall(
    List<AkashaItem> items, {
    DateTime? date,
  }) {
    final day = date ?? DateTime.now();
    final candidates = <DailyRecall>[];

    for (final item in items) {
      for (final raw in item.memorableQuotes) {
        final quote = raw.trim();
        if (quote.isNotEmpty) {
          candidates.add(DailyRecall(item: item, quote: quote));
        }
      }
    }

    if (candidates.isEmpty) return null;

    final seed = day.year * 10000 + day.month * 100 + day.day;
    return candidates[seed % candidates.length];
  }
}
