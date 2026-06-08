/// akasha-db v4 — 중복 탐지 유틸 (dedupe_linter·테스트 공용)
library;

final _legacySlugPattern = RegExp(
  r'^(?:sub|gen)_(?:manga|webtoon|animation|game|book|movie|drama)_(.+?)(?:_\d{4})?$',
);

/// 검색·비교용 제목 정규화 (대소문자·구두점·공백 무시)
String normalizeTitle(String input) {
  if (input.isEmpty) return '';
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '')
      .trim();
}

/// legacy `sub_manga_one-piece_1997` → `one-piece`
String? legacySlugStem(String legacyId) {
  final match = _legacySlugPattern.firstMatch(legacyId);
  if (match == null) return null;
  var slug = match.group(1)!;
  slug = slug
      .replaceAll(RegExp(r'-light-novel$'), '')
      .replaceAll(RegExp(r'-anime$'), '')
      .replaceAll(RegExp(r'-sub$'), '')
      .replaceAll(RegExp(r'-manga$'), '');
  return slug.toLowerCase();
}

/// 정렬된 pair 키 — 예외·프랜차이즈 조회용
String pairKey(String a, String b) {
  return a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
}

bool isPairAllowed(String a, String b, Set<String> allowedPairs) {
  return allowedPairs.contains(pairKey(a, b));
}

/// 동일 franchise_groups 멤버면 의도적 별매체 — fuzzy 중복 제외
bool isFranchiseSibling(
  String a,
  String b,
  Map<String, Set<String>> workToFranchisePeers,
) {
  final peersA = workToFranchisePeers[a];
  if (peersA == null) return false;
  return peersA.contains(b);
}
