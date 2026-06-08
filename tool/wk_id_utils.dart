/// akasha-db v4 — `wk_` 영구 ID 유틸 (도구·CI 공용)
library;

final wkIdPattern = RegExp(r'^wk_\d{8}$');

bool isWkId(String workId) => wkIdPattern.hasMatch(workId);

String formatWkId(int sequence) {
  if (sequence < 1 || sequence > 99999999) {
    throw ArgumentError('wk sequence out of range: $sequence');
  }
  return 'wk_${sequence.toString().padLeft(8, '0')}';
}

int? parseWkSequence(String workId) {
  if (!isWkId(workId)) return null;
  return int.tryParse(workId.substring(3));
}
