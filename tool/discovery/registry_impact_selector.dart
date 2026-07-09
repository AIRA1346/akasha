// Phase B — Registry Impact Test 후보 선정 (5~10건).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../dedupe_utils.dart';
import '../registry_v3_utils.dart';
import 'registry_coverage_utils.dart';
import 'registry_snapshot.dart';
import 'shadow_write_runner.dart';
import 'user_value_assessment.dart';

enum ImpactSelectionAxis { gap, coreWork, franchise }

class ImpactSelectionScore {
  final ShadowWriteItem item;
  final UserValueAssessment userValue;
  final GapFillAnalysis gap;
  final bool coreWork;
  final bool franchiseValue;
  final String? franchiseHint;
  final int impactScore;
  final List<ImpactSelectionAxis> axes;
  final List<String> reasons;

  const ImpactSelectionScore({
    required this.item,
    required this.userValue,
    required this.gap,
    required this.coreWork,
    required this.franchiseValue,
    required this.impactScore,
    required this.axes,
    required this.reasons,
    this.franchiseHint,
  });

  Map<String, dynamic> toJson() => {
        'sourceExternalId': item.externalId,
        'title': item.title,
        'shadowWorkId': item.shadowWorkId,
        'userValueTier': userValue.tier.name,
        'impactScore': impactScore,
        'axes': axes.map((a) => a.name).toList(),
        'reasons': reasons,
        'fillsGap': gap.fillsTitleGap,
        'novelSearchTokens': gap.novelSearchTokens.take(8).toList(),
        'franchiseHint': franchiseHint,
      };
}

class FranchiseAffinityIndex {
  final Map<String, String> normToGroupLabel;

  const FranchiseAffinityIndex({required this.normToGroupLabel});

  factory FranchiseAffinityIndex.load({
    required Directory projectRoot,
    required RegistrySnapshot registry,
  }) {
    final path = p.join(projectRoot.path, 'akasha-db', 'franchise_groups.json');
    final file = File(path);
    final normToGroup = <String, String>{};
    if (!file.existsSync()) {
      return FranchiseAffinityIndex(normToGroupLabel: normToGroup);
    }

    final raw = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    raw.forEach((groupId, value) {
      if (groupId.startsWith('_') || value is! Map) return;
      final map = Map<String, dynamic>.from(value);
      final label = map['displayName']?.toString() ?? groupId;

      void tag(String? text) {
        final n = normalizeTitle(text ?? '');
        if (n.length >= 3) normToGroup[n] = label;
      }

      tag(label);
      final members = map['members'] as List? ?? [];
      for (final m in members) {
        final workId = m.toString();
        final entry = registry.byWorkId[workId];
        if (entry == null) continue;
        for (final norm in entry.normalizedTitles) {
          if (norm.length >= 3) normToGroup[norm] = label;
        }
      }
    });

    return FranchiseAffinityIndex(normToGroupLabel: normToGroup);
  }

  String? matchCandidate(Set<String> titleNorms) {
    for (final norm in titleNorms) {
      if (norm.length < 4) continue;
      for (final entry in normToGroupLabel.entries) {
        if (norm == entry.key) return entry.value;
        if (norm.contains(entry.key) || entry.key.contains(norm)) {
          return entry.value;
        }
      }
    }
    return null;
  }
}

ImpactSelectionScore scoreImpactCandidate({
  required ShadowWriteItem item,
  required Map<String, dynamic> draft,
  required RegistryCoverageSnapshot coverage,
  required FranchiseAffinityIndex franchiseIndex,
}) {
  final gap = analyzeGapFill(draft: draft, before: coverage);
  final allTokens = buildWorkSearchTokens(
    legacyTitle: draft['title']?.toString() ?? '',
    titles: parseTitlesJson(draft['titles']),
    aliases: (draft['aliases'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const [],
    creator: draft['creator']?.toString() ?? '',
  );

  final userValue = assessUserValue(
    draft: draft,
    item: item,
    titleDistinctInRegistry: gap.fillsTitleGap,
    searchTokenCount: allTokens.length,
  );

  final aliases = (draft['aliases'] as List?)?.length ?? 0;
  final titles = parseTitlesJson(draft['titles']);
  final creator = draft['creator']?.toString().trim() ?? '';
  final coreWork = creator.isNotEmpty && titles.length >= 2 && aliases >= 2;

  final titleNorms = <String>{};
  void addNorm(String? t) {
    final n = normalizeTitle(t ?? '');
    if (n.isNotEmpty) titleNorms.add(n);
  }

  addNorm(draft['title']?.toString());
  titles.forEach((_, v) => addNorm(v));
  for (final a in (draft['aliases'] as List? ?? [])) {
    addNorm(a?.toString());
  }

  final franchiseHint = franchiseIndex.matchCandidate(titleNorms);
  final franchiseValue = franchiseHint != null;

  final axes = <ImpactSelectionAxis>[];
  final reasons = <String>[];
  var score = 0;

  if (gap.fillsTitleGap) {
    score += 4;
    axes.add(ImpactSelectionAxis.gap);
    reasons.add('Registry Gap — 정규화 제목 미등록');
  }
  if (gap.totalNewTokens > 0) {
    score += 2;
    reasons.add('신규 searchTokens ${gap.totalNewTokens}개');
  }

  if (coreWork) {
    score += 3;
    axes.add(ImpactSelectionAxis.coreWork);
    reasons.add('Core Work — creator·titles·aliases 충실');
  }

  if (franchiseValue) {
    score += 2;
    axes.add(ImpactSelectionAxis.franchise);
    reasons.add('Franchise 연결 가치 — $franchiseHint');
  }

  if (userValue.tier == UserValueTier.high) {
    score += 2;
  } else if (userValue.tier == UserValueTier.medium) {
    score += 1;
  }

  return ImpactSelectionScore(
    item: item,
    userValue: userValue,
    gap: gap,
    coreWork: coreWork,
    franchiseValue: franchiseValue,
    franchiseHint: franchiseHint,
    impactScore: score,
    axes: axes,
    reasons: reasons,
  );
}

/// Gap·Core·Franchise 축 + High User Value 우선, 5~10건
List<ImpactSelectionScore> selectImpactCandidates({
  required List<ImpactSelectionScore> scored,
  int minSelect = 5,
  int maxSelect = 10,
}) {
  final eligible = scored
      .where(
        (s) =>
            s.userValue.tier == UserValueTier.high ||
            (s.userValue.tier == UserValueTier.medium && s.impactScore >= 6),
      )
      .where((s) => s.gap.fillsTitleGap || s.coreWork)
      .toList()
    ..sort((a, b) => b.impactScore.compareTo(a.impactScore));

  if (eligible.isEmpty) return const [];

  final count = eligible.length < minSelect
      ? eligible.length
      : eligible.length.clamp(minSelect, maxSelect);

  return eligible.take(count).toList();
}
