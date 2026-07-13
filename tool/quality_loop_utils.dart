// Contribution → Quality Loop — fixWork 필드를 작품에 반영하고
// 검증 신호(qualitySignals)를 갱신하는 순수 로직.
//
// 원칙 (docs/data-policy.md):
// - 카운터(userFixCount) 저장 금지 — "몇 명이 고쳤나"가 아니라 "무엇이 검증됐나"
// - qualitySignals = 원본, qualityScore/Tier = 파생 (registry_builder가 계산)
library;

/// fixWork 필드가 승인됐을 때 켜지는 검증 신호.
/// 값이 null이면 검증 신호 없이 필드만 반영한다.
const fixFieldToVerifiedSignal = <String, String?>{
  'externalIds': 'externalIdVerified',
  'franchise': 'franchiseVerified',
  'franchiseId': 'franchiseVerified',
  // 사실 필드 — 반영만, 검증 신호 없음
  'title': null,
  'titles': null,
  'creator': null,
  'releaseYear': null,
  'tags': null,
  'aliases': null,
  'category': null,
  'domain': null,
};

/// 작품 본문에 직접 기록하지 않는 필드 (franchise는 franchise_groups.json 소관)
const fixFieldsNotWrittenToWork = {'franchise', 'franchiseId'};

class QualityLoopResult {
  final Map<String, dynamic> work;
  final Set<String> appliedFields;
  final Set<String> verifiedSignals;
  final List<String> skippedFields;

  const QualityLoopResult({
    required this.work,
    required this.appliedFields,
    required this.verifiedSignals,
    required this.skippedFields,
  });
}

/// [work]에 [fields]를 반영하고 qualitySignals를 갱신한 새 맵을 반환.
/// 입력 맵은 변형하지 않는다.
QualityLoopResult applyFixToWork(
  Map<String, dynamic> work,
  Map<String, dynamic> fields,
) {
  final next = Map<String, dynamic>.from(work);
  final applied = <String>{};
  final verified = <String>{};
  final skipped = <String>[];

  final existingSignals = next['qualitySignals'] is Map
      ? Map<String, dynamic>.from(next['qualitySignals'] as Map)
      : <String, dynamic>{};

  for (final entry in fields.entries) {
    final key = entry.key;
    final value = entry.value;

    if (!fixFieldToVerifiedSignal.containsKey(key)) {
      skipped.add(key);
      continue;
    }

    if (key == 'externalIds') {
      final merged = next['externalIds'] is Map
          ? Map<String, dynamic>.from(next['externalIds'] as Map)
          : <String, dynamic>{};
      if (value is Map) {
        value.forEach((k, v) {
          final id = v?.toString().trim() ?? '';
          if (k != null && id.isNotEmpty) merged[k.toString()] = id;
        });
      }
      next['externalIds'] = merged;
    } else if (!fixFieldsNotWrittenToWork.contains(key)) {
      next[key] = value;
    }

    applied.add(key);

    final signal = fixFieldToVerifiedSignal[key];
    if (signal != null) {
      existingSignals[signal] = true;
      verified.add(signal);
    }
  }

  if (existingSignals.isNotEmpty) {
    next['qualitySignals'] = existingSignals;
  }

  return QualityLoopResult(
    work: next,
    appliedFields: applied,
    verifiedSignals: verified,
    skippedFields: skipped,
  );
}
