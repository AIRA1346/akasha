// Wikidata Q-id ingest 검증 — [wikidata-spine-plan.md](../../docs/strategy/wikidata-spine-plan.md) §7
library;

/// Q-id / P-id 형식 (Wikidata와 동일: 접두 + 무제한 10진수)
final wikidataQidPattern = RegExp(r'^Q\d+$');
final wikidataPropertyPattern = RegExp(r'^P\d+$');

/// AKASHA category → 허용 Wikidata P31 (instance of) Q-id
const expectedP31ByAkashaCategory = {
  'manga': {'Q21198342'}, // manga series
  'webtoon': {'Q60496358', 'Q21198342', 'Q1004', 'Q7978994', 'Q74262765'}, // webtoon, manga series, comics
  'animation': {'Q63952888', 'Q2485346', 'Q20650540', 'Q113671041', 'Q1259759'}, // anime TV, anime series, anime film
  'game': {'Q7889'},
  'book': {'Q7725634', 'Q8261', 'Q1667921', 'Q104213567'}, // literary work, novel series, light novel
  'movie': {'Q11424', 'Q20650540'},
  'drama': {'Q5398426', 'Q15416', 'Q24856'}, // television series
};

/// SPARQL·문서 검증용 귀멨 SSOT (2026-06 live)
const kimetsuWikidataSsot = {
  'franchise': 'Q105037706',
  'manga': 'Q24862683',
  'animeTv': 'Q63350570',
  'mugenFilm': 'Q96376192',
  'season1': 'Q105847391',
  'season2': 'Q105847067',
};

/// 알려진 오류 Q-id (재사용·AI 환각 — ingest BLOCK)
const knownInvalidWikidataQids = {
  'Q105556271', // was cited as franchise; live = unrelated human
  'Q24867451', // was cited as manga; live = Wikimedia category
  'Q61093122', // was cited as anime series; live ≠ Kimetsu
  'Q112674443', // was cited as season 1; live ≠ Kimetsu
  'Q112623351', // was cited as season 2; live ≠ Kimetsu
  'Q100323330', // was cited as Mugen arc; live = unrelated artefact
};

enum WikidataQValidationVerdict { pass, block, review }

class WikidataQValidationResult {
  final WikidataQValidationVerdict verdict;
  final String code;
  final String detail;

  const WikidataQValidationResult({
    required this.verdict,
    required this.code,
    required this.detail,
  });

  bool get isPass => verdict == WikidataQValidationVerdict.pass;
}

bool isValidWikidataQidFormat(String? qid) {
  final trimmed = qid?.trim() ?? '';
  return trimmed.isNotEmpty && wikidataQidPattern.hasMatch(trimmed);
}

bool isValidWikidataPropertyFormat(String? pid) {
  final trimmed = pid?.trim() ?? '';
  return trimmed.isNotEmpty && wikidataPropertyPattern.hasMatch(trimmed);
}

/// ingest 전 Q 검증 (live P31·label는 fixture/SPARQL 확장 시 주입)
WikidataQValidationResult validateWikidataQidForIngest({
  required String qid,
  required String category,
  required String title,
  Set<String> registryWikidataQids = const {},
  Set<String>? entityP31Qids,
  String? entityEnLabel,
}) {
  if (!isValidWikidataQidFormat(qid)) {
    return const WikidataQValidationResult(
      verdict: WikidataQValidationVerdict.block,
      code: 'V0_format',
      detail: 'invalid Q-id format',
    );
  }

  if (knownInvalidWikidataQids.contains(qid)) {
    return WikidataQValidationResult(
      verdict: WikidataQValidationVerdict.block,
      code: 'V0_known_bad',
      detail: 'Q-id on blocklist (verify label via live Wikidata)',
    );
  }

  if (registryWikidataQids.contains(qid)) {
    return WikidataQValidationResult(
      verdict: WikidataQValidationVerdict.block,
      code: 'V4_duplicate',
      detail: 'wikidata Q already on another work',
    );
  }

  final allowedP31 = expectedP31ByAkashaCategory[category];
  if (entityP31Qids != null &&
      allowedP31 != null &&
      entityP31Qids.isNotEmpty &&
      !entityP31Qids.any(allowedP31.contains)) {
    return WikidataQValidationResult(
      verdict: WikidataQValidationVerdict.block,
      code: 'V2_p31_mismatch',
      detail: 'P31 $entityP31Qids not allowed for category $category',
    );
  }

  if (entityEnLabel != null &&
      entityEnLabel.trim().isNotEmpty &&
      title.trim().isNotEmpty) {
    final a = _normalizeLabel(entityEnLabel);
    final b = _normalizeLabel(title);
    if (a.length >= 4 &&
        b.length >= 4 &&
        !a.contains(b) &&
        !b.contains(a) &&
        _tokenOverlap(a, b) < 0.25) {
      return WikidataQValidationResult(
        verdict: WikidataQValidationVerdict.review,
        code: 'V5_label_mismatch',
        detail: 'Wikidata label "$entityEnLabel" vs title "$title"',
      );
    }
  }

  return const WikidataQValidationResult(
    verdict: WikidataQValidationVerdict.pass,
    code: 'pass',
    detail: 'ok',
  );
}

String _normalizeLabel(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '');

double _tokenOverlap(String a, String b) {
  final ta = a.split(RegExp(r'\s+')).where((t) => t.length >= 2).toSet();
  final tb = b.split(RegExp(r'\s+')).where((t) => t.length >= 2).toSet();
  if (ta.isEmpty || tb.isEmpty) return a == b ? 1.0 : 0.0;
  return ta.intersection(tb).length / ta.union(tb).length;
}
