/// akasha-db v4 — `wk_` 영구 ID 유틸 (도구·CI 공용)
library;

/// 순번 자릿수 — `wk_000000001` 형식 (최대 999,999,999 ≈ 10억 작)
const wkSequenceDigits = 9;

const wkMaxSequence = 999999999;

/// v4 canonical — 정확히 9자리
final wkIdPattern = RegExp(r'^wk_\d{9}$');

/// 마이그레이션·alias 해석용 — 구 8자리도 순번 파싱
final wkIdLegacy8Pattern = RegExp(r'^wk_\d{8}$');

bool isWkId(String workId) => wkIdPattern.hasMatch(workId);

bool isWkIdLegacy8(String workId) => wkIdLegacy8Pattern.hasMatch(workId);

bool isWkIdAny(String workId) => isWkId(workId) || isWkIdLegacy8(workId);

String formatWkId(int sequence) {
  if (sequence < 1 || sequence > wkMaxSequence) {
    throw ArgumentError('wk sequence out of range: $sequence');
  }
  return 'wk_${sequence.toString().padLeft(wkSequenceDigits, '0')}';
}

int? parseWkSequence(String workId) {
  if (!isWkIdAny(workId)) return null;
  return int.tryParse(workId.substring(3));
}

/// 8자리 `wk_` → 9자리 canonical (순번 동일)
String? canonicalizeWkId(String workId) {
  final seq = parseWkSequence(workId);
  if (seq == null) return null;
  return formatWkId(seq);
}
