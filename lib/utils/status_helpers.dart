import '../models/akasha_item.dart';
import '../models/category_descriptor.dart';
import '../models/enums.dart';
import '../generated/l10n/app_localizations.dart';

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

String watchlistStatusEmojiLabel(AkashaItem item, [AppLocalizations? l10n]) {
  final label = item.myStatusLabel;
  final isContent = CategoryRegistry.isContentType(item.category);

  if (isWatchlistStatusLabel(label)) {
    final text = isContent
        ? (l10n?.statusContentMyNotStarted ?? '볼 예정')
        : (l10n?.statusGameMyBacklog ?? '볼 예정');
    return '🟣 $text';
  }

  if (label == ContentMyStatus.watching.label ||
      label == GameMyStatus.playing.label) {
    final text = isContent
        ? (l10n?.statusContentMyWatching ?? 'Watching')
        : (l10n?.statusGameMyPlaying ?? 'Playing');
    return '🟢 $text';
  }

  if (label == ContentMyStatus.finished.label ||
      label == GameMyStatus.cleared.label) {
    final text = isContent
        ? (l10n?.statusContentMyFinished ?? 'Finished')
        : (l10n?.statusGameMyCleared ?? 'Cleared');
    return '🟣 $text';
  }

  if (label == ContentMyStatus.dropped.label ||
      label == GameMyStatus.abandoned.label) {
    final text = isContent
        ? (l10n?.statusContentMyDropped ?? 'Dropped')
        : (l10n?.statusGameMyAbandoned ?? 'Abandoned');
    return '⚪ $text';
  }

  return '⚪ $label';
}
