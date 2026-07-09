// Product Value Review — 5b 전 제품·정책 게이트.
library;

import 'dart:convert';

import '../data_policy_utils.dart';
import 'discovery_product_kpi.dart';
import 'registry_diff_compare.dart';
import 'registry_impact_selector.dart';
import 'user_value_assessment.dart';

/// 등록 동기 — 외부 spine 존재 vs 사용자 가치
enum AdditionDriver {
  userGap,
  externalSpineOnly,
  both,
  unclear,
}

class ProductValueReviewEntry {
  final ImpactSelectionScore selection;
  final bool resolvesUserSearchGap;
  final bool improvesRelationNetwork;
  final bool survivesWithoutExternalSpine;
  final bool lowMirroringRisk;
  final bool userValueBasedPriority;
  final AdditionDriver additionDriver;
  final bool productValuePassed;
  final List<String> policyNotes;
  final List<String> manualQuestions;

  const ProductValueReviewEntry({
    required this.selection,
    required this.resolvesUserSearchGap,
    required this.improvesRelationNetwork,
    required this.survivesWithoutExternalSpine,
    required this.lowMirroringRisk,
    required this.userValueBasedPriority,
    required this.additionDriver,
    required this.productValuePassed,
    required this.policyNotes,
    required this.manualQuestions,
  });

  Map<String, dynamic> toJson() => {
        'title': selection.item.title,
        'shadowWorkId': selection.item.shadowWorkId,
        'sourceExternalId': selection.item.externalId,
        'resolvesUserSearchGap': resolvesUserSearchGap,
        'improvesRelationNetwork': improvesRelationNetwork,
        'survivesWithoutExternalSpine': survivesWithoutExternalSpine,
        'lowMirroringRisk': lowMirroringRisk,
        'userValueBasedPriority': userValueBasedPriority,
        'additionDriver': additionDriver.name,
        'productValuePassed': productValuePassed,
        'policyNotes': policyNotes,
        'manualQuestions': manualQuestions,
      };
}

class ProductValueReviewReport {
  final List<ProductValueReviewEntry> entries;
  final DiscoveryProductKpi kpi;

  const ProductValueReviewReport({
    required this.entries,
    required this.kpi,
  });

  Map<String, dynamic> toJson() => {
        'kpi': kpi.toJson(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}

ProductValueReviewReport buildProductValueReview({
  required List<ImpactSelectionScore> selected,
  required RegistryDiffResult diff,
}) {
  final gapResolvedIds = <String>{};
  for (final win in diff.searchWins) {
    if (win.wasZeroBefore &&
        win.newTopWorkId != null &&
        win.hitsAfter > 0) {
      gapResolvedIds.add(win.newTopWorkId!);
      // primary title probe만 Gap 해소로 카운트 (별칭 중복 방지)
      if (win.query == win.newTopTitle) {
        gapResolvedIds.add(win.newTopWorkId!);
      }
    }
  }

  // 작품별: 제목 exact match zeroToHit
  final primaryGapIds = <String>{};
  for (final s in selected) {
    final title = s.item.title;
    final id = s.item.shadowWorkId;
    if (id == null) continue;
    for (final win in diff.searchWins) {
      if (win.query == title && win.wasZeroBefore && win.newTopWorkId == id) {
        primaryGapIds.add(id);
      }
    }
  }

  final entries = <ProductValueReviewEntry>[];
  var passed = 0;
  var gapResolved = 0;
  var independent = 0;
  var highUv = 0;

  for (final s in selected) {
    final entry = _reviewEntry(
      s,
      primaryGapResolved: primaryGapIds.contains(s.item.shadowWorkId),
    );
    entries.add(entry);
    if (entry.productValuePassed) passed++;
    if (entry.resolvesUserSearchGap) gapResolved++;
    if (entry.survivesWithoutExternalSpine) independent++;
    if (s.userValue.tier == UserValueTier.high) highUv++;
  }

  return ProductValueReviewReport(
    entries: entries,
    kpi: DiscoveryProductKpi(
      selectedCount: selected.length,
      productValuePassedCount: passed,
      searchGapResolvedCount: gapResolved,
      independentValueCount: independent,
      userValueHighCount: highUv,
    ),
  );
}

ProductValueReviewEntry _reviewEntry(
  ImpactSelectionScore s, {
  required bool primaryGapResolved,
}) {
  final draft = s.item.draft ?? {};
  final workId = s.item.shadowWorkId ?? 'wk_PENDING';
  final policyIssues = lintWorkEntry(
    workId: workId,
    work: draft,
    relativePath: s.item.targetShard ?? 'shards/animation/00.json',
  );

  final identity = _assessIdentityForProduct(draft, workId);
  final lowMirroring = policyIssues.isEmpty &&
      !draft.containsKey('description') &&
      !draft.containsKey('tags') &&
      !draft.containsKey('posterPath');

  final resolvesGap = primaryGapResolved || s.gap.fillsTitleGap;
  final improvesNetwork =
      s.franchiseValue || (s.coreWork && s.item.draft?['creator'] != null);

  final survives = identity.akashaIdentitySufficient &&
      (identity.hasIntrinsicMetadata);

  final userValuePriority = s.userValue.tier == UserValueTier.high &&
      s.axes.isNotEmpty &&
      !s.reasons.any((r) => r.toLowerCase().contains('anilist'));

  final driver = _additionDriver(
    selection: s,
    resolvesGap: resolvesGap,
    survives: survives,
  );

  final policyNotes = <String>[
    'Discovery ≠ Mirroring: Minimal Core만, wikidata=spine',
    '동기: ${driver.name} — ${_driverLabel(driver)}',
  ];
  if (lowMirroring) {
    policyNotes.add('미러링 리스크 낮음 — description/poster/tags 없음');
  } else {
    policyNotes.add('미러링 리스크 검토 필요');
  }

  final manualQuestions = <String>[
    ProductReviewQuestions.searchGap,
    ProductReviewQuestions.relationNetwork,
    ProductReviewQuestions.survivesWithoutExternalSpine,
    ProductReviewQuestions.mirroringPerception,
    ProductReviewQuestions.userValuePriority,
  ];

  final passed = resolvesGap &&
      survives &&
      lowMirroring &&
      userValuePriority &&
      driver != AdditionDriver.externalSpineOnly;

  return ProductValueReviewEntry(
    selection: s,
    resolvesUserSearchGap: resolvesGap,
    improvesRelationNetwork: improvesNetwork,
    survivesWithoutExternalSpine: survives,
    lowMirroringRisk: lowMirroring,
    userValueBasedPriority: userValuePriority,
    additionDriver: driver,
    productValuePassed: passed,
    policyNotes: policyNotes,
    manualQuestions: manualQuestions,
  );
}

class ProductReviewQuestions {
  static const searchGap =
      '이 작품은 현재 사용자 검색 Gap을 해결하는가?';
  static const relationNetwork =
      'AKASHA 내부 추천/관계망 품질을 높이는가?';
  static const survivesWithoutExternalSpine =
      'Wikidata spine 없이도 AKASHA에 남아야 하는가?';
  static const mirroringPerception =
      '외부 DB 복제라고 오해받지 않는가?';
  static const userValuePriority =
      '등록 우선순위가 User Value 기반인가? (외부 DB 존재 때문이 아님)';
}

AdditionDriver _additionDriver({
  required ImpactSelectionScore selection,
  required bool resolvesGap,
  required bool survives,
}) {
  final spineSignal = selection.item.externalId.isNotEmpty;
  if (resolvesGap && survives && spineSignal) {
    return AdditionDriver.both;
  }
  if (resolvesGap && survives) return AdditionDriver.userGap;
  if (spineSignal && !resolvesGap) return AdditionDriver.externalSpineOnly;
  return AdditionDriver.unclear;
}

String _driverLabel(AdditionDriver d) => switch (d) {
      AdditionDriver.userGap => '사용자 Gap·AKASHA 가치 (wikidata는 spine)',
      AdditionDriver.externalSpineOnly => '외부 spine 존재 위주 — 5b 부적합',
      AdditionDriver.both =>
        'Gap 해소 + AKASHA 정체성; wikidata는 spine 참조만',
      AdditionDriver.unclear => '수동 판단 필요',
    };

class _ProductIdentity {
  final bool akashaIdentitySufficient;
  final bool hasIntrinsicMetadata;

  const _ProductIdentity({
    required this.akashaIdentitySufficient,
    required this.hasIntrinsicMetadata,
  });
}

_ProductIdentity _assessIdentityForProduct(
  Map<String, dynamic> draft,
  String workId,
) {
  final title = draft['title']?.toString().trim() ?? '';
  final category = draft['category']?.toString() ?? '';
  final year = draft['releaseYear'];
  final creator = draft['creator']?.toString().trim() ?? '';
  final titles = draft['titles'];
  final hasTitles = titles is Map && titles.isNotEmpty;
  final aliases = draft['aliases'];
  final hasAliases = aliases is List && aliases.isNotEmpty;

  final sufficient =
      workId.startsWith('wk_') && title.isNotEmpty && category.isNotEmpty;
  final intrinsic = (year != null || creator.isNotEmpty) &&
      (hasTitles || hasAliases || title.length >= 3);

  return _ProductIdentity(
    akashaIdentitySufficient: sufficient && (year != null || title.length >= 4),
    hasIntrinsicMetadata: intrinsic,
  );
}

String formatProductValueMarkdown(ProductValueReviewReport report) {
  final k = report.kpi;
  final buf = StringBuffer();

  buf.writeln('# Product Value Review');
  buf.writeln();
  buf.writeln('> **5b Patch 보류** — 기술 검증 완료, 제품·정책 검증 단계');
  buf.writeln('> 핵심: 외부 DB에 **존재해서** 추가 ≠ 사용자에게 **가치 있어서** 추가');
  buf.writeln();
  buf.writeln('## Discovery KPI (Product)');
  buf.writeln();
  buf.writeln('| KPI | 값 | 의미 |');
  buf.writeln('|-----|-----|------|');
  buf.writeln(
    '| userValueCoverage | ${(k.userValueCoverage * 100).toStringAsFixed(1)}% | '
    'Product Review 통과 (${k.productValuePassedCount}/${k.selectedCount}) |',
  );
  buf.writeln(
    '| userSearchGapResolved | ${(k.userSearchGapResolved * 100).toStringAsFixed(1)}% | '
    '사용자 검색 Gap 해소 (${k.searchGapResolvedCount}/${k.selectedCount}) |',
  );
  buf.writeln(
    '| independentRegistryValue | ${(k.independentRegistryValue * 100).toStringAsFixed(1)}% | '
    'spine 없이 AKASHA 가치 (${k.independentValueCount}/${k.selectedCount}) |',
  );
  buf.writeln('| recommend5bPatch | **${k.recommend5bPatch}** | Product 통과 후 patch |');
  buf.writeln();
  buf.writeln('기존 KPI: `wouldCreate` · `coverageDelta` · `zeroToHit` (기술)');
  buf.writeln();

  buf.writeln('## 작품별 검토');
  buf.writeln();
  for (var i = 0; i < report.entries.length; i++) {
    final e = report.entries[i];
    final s = e.selection;
    buf.writeln('### ${i + 1}. ${s.item.title}');
    buf.writeln();
    buf.writeln('| | |');
    buf.writeln('|--|--|');
    buf.writeln('| wk_ (shadow) | `${s.item.shadowWorkId}` |');
    buf.writeln('| wikidata (spine) | `${s.item.externalId}` |');
    buf.writeln('| additionDriver | **${e.additionDriver.name}** |');
    buf.writeln('| productValuePassed | **${e.productValuePassed}** |');
    buf.writeln();
    buf.writeln('#### 정책 질문 (자동 힌트)');
    buf.writeln();
    buf.writeln(
      '| 질문 | 힌트 |',
    );
    buf.writeln('|------|------|');
    buf.writeln(
      '| ${ProductReviewQuestions.searchGap} | ${e.resolvesUserSearchGap} |',
    );
    buf.writeln(
      '| ${ProductReviewQuestions.relationNetwork} | ${e.improvesRelationNetwork} |',
    );
    buf.writeln(
      '| ${ProductReviewQuestions.survivesWithoutExternalSpine} | ${e.survivesWithoutExternalSpine} |',
    );
    buf.writeln(
      '| ${ProductReviewQuestions.mirroringPerception} | ${e.lowMirroringRisk} |',
    );
    buf.writeln(
      '| ${ProductReviewQuestions.userValuePriority} | ${e.userValueBasedPriority} |',
    );
    buf.writeln();
    for (final n in e.policyNotes) {
      buf.writeln('- $n');
    }
    buf.writeln();
    buf.writeln('#### 수동 확인');
    buf.writeln();
    for (final q in e.manualQuestions) {
      buf.writeln('- [ ] $q');
    }
    buf.writeln();
    buf.writeln('---');
    buf.writeln();
  }

  buf.writeln('## 5b Patch 정책');
  buf.writeln();
  buf.writeln('- **현재: 보류** (기술 문제 아님, 제품·정책 문제)');
  buf.writeln('- patch 조건: 본 Product Value Review **수동 통과**');
  buf.writeln('- `mergeCandidate` → wikidata **링크 큐** (신규 wk_ 아님)');
  buf.writeln('- AKASHA ≠ Wikidata 미러링; 정체성 = `wk_` Registry');
  buf.writeln();

  if (!k.recommend5bPatch) {
    buf.writeln(
      '**자동 게이트 미달** — 수동 Product Review 후 선정·기준 재검토.',
    );
  } else {
    buf.writeln(
      '**자동 게이트 통과** — 수동 Product Review 체크리스트 확인 후 5b 검토.',
    );
  }
  buf.writeln();

  return buf.toString();
}

String formatProductValueJson(ProductValueReviewReport report) {
  return const JsonEncoder.withIndent('  ').convert(report.toJson());
}
