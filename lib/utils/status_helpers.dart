import '../models/akasha_item.dart';
import '../models/category_descriptor.dart';
import '../models/enums.dart';

/// 감상 예정(watchlist) 상태 — enum 기준 + 레거시 라벨 호환
bool isWatchlistStatusLabel(String label) {
  return label == ContentMyStatus.notStarted.label ||
      label == GameMyStatus.backlog.label ||
      label == '아직 안 봄' ||
      label == '할 예정(백로그)';
}

bool isWatchlistItem(AkashaItem item) {
  if (CategoryRegistry.isContentType(item.category)) {
    return item.myStatusLabel == ContentMyStatus.notStarted.label ||
        item.myStatusLabel == '아직 안 봄';
  }
  return item.myStatusLabel == GameMyStatus.backlog.label ||
      item.myStatusLabel == '할 예정(백로그)';
}

bool isFinishedItem(AkashaItem item) {
  final workDone = item.workStatusLabel == ContentWorkStatus.completed.label ||
      item.workStatusLabel == GameWorkStatus.released.label;
  if (!workDone) return false;

  if (CategoryRegistry.isContentType(item.category)) {
    return item.myStatusLabel == ContentMyStatus.finished.label;
  }
  return item.myStatusLabel == GameMyStatus.cleared.label;
}

String watchlistStatusEmojiLabel(AkashaItem item) {
  final label = item.myStatusLabel;
  if (isWatchlistStatusLabel(label)) return '🟣 볼 예정';
  if (label == ContentMyStatus.watching.label ||
      label == GameMyStatus.playing.label) {
    return '🟢 $label';
  }
  if (label == ContentMyStatus.finished.label ||
      label == GameMyStatus.cleared.label) {
    return '🟣 $label';
  }
  return '⚪ $label';
}
