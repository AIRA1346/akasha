import '../models/akasha_item.dart';
import 'status_helpers.dart';

/// Work journal 감상 카드용 미리보기 텍스트·빈 상태 판별.
abstract final class JournalReflectionPreview {
  static const int defaultMemoMaxLength = 180;

  static String formatMemo(String review, {int maxLength = defaultMemoMaxLength}) {
    final trimmed = review.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength).trimRight()}…';
  }

  static bool hasMemo(String review) => review.trim().isNotEmpty;

  static bool hasRating(AkashaItem item) => item.rating > 0;

  static bool hasMeaningfulStatus(AkashaItem item) {
    final label = item.myStatusLabel.trim();
    if (label.isEmpty) return false;
    return !isWatchlistStatusLabel(label);
  }

  static bool hasTags(AkashaItem item) => item.tags.isNotEmpty;

  /// Agent·사용자가 남긴 개인 기록이 하나라도 있는지.
  static bool hasAnyReflection(AkashaItem item) {
    return hasMemo(item.review) ||
        hasRating(item) ||
        hasMeaningfulStatus(item) ||
        hasTags(item);
  }

  static String emptyMemoHint({required bool isVaultArchived}) {
    if (isVaultArchived) {
      return '아직 메모가 없습니다.\n대화나 상세에서 감상을 적어 보세요.';
    }
    return '아카이브 후 감상·메모가 여기에 표시됩니다.';
  }
}
