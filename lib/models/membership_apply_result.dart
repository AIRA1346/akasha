import '../generated/l10n/app_localizations.dart';

/// `WorkLibraryPanel` 적용 결과 — 스낵바용
class MembershipApplyResult {
  final int addedLibraryCount;
  final int removedLibraryCount;
  final List<String> addedLibraryNames;
  final List<String> removedLibraryNames;

  const MembershipApplyResult({
    this.addedLibraryCount = 0,
    this.removedLibraryCount = 0,
    this.addedLibraryNames = const [],
    this.removedLibraryNames = const [],
  });

  bool get hasChanges => addedLibraryCount > 0 || removedLibraryCount > 0;

  String toSnackBarMessage([AppLocalizations? l10n]) {
    if (!hasChanges) return l10n?.libApplyNoChanges ?? '변경 사항이 없습니다.';
    final parts = <String>[];
    final joinChar = l10n != null ? (l10n.localeName == 'ko' ? '」, 「' : '", "') : '」, 「';

    if (addedLibraryNames.isNotEmpty) {
      if (l10n != null) {
        parts.add(l10n.libApplyAdded(addedLibraryNames.join(joinChar)));
      } else {
        parts.add('「${addedLibraryNames.join('」, 「')}」에 담았습니다');
      }
    }
    if (removedLibraryNames.isNotEmpty) {
      if (l10n != null) {
        parts.add(l10n.libApplyRemoved(removedLibraryNames.join(joinChar)));
      } else {
        parts.add('「${removedLibraryNames.join('」, 「')}」에서 제거했습니다 (볼트 기록 유지)');
      }
    }
    return parts.join(' · ');
  }
}
