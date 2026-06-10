// ignore_for_file: avoid_print
/// 402→5k Scale Simulation — SIM-A/B/C/D (Baseline v1 검증).
///
/// Usage:
///   dart run tool/scale_5k_sim.dart
///   dart run tool/scale_5k_sim.dart --sim a
///   dart run tool/scale_5k_sim.dart --sim a,b,c,d --seed 42
///
/// 산출물 (gitignored 권장):
///   akasha-db/pipeline/artifacts/scale_5k_sim/

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'dedupe_utils.dart';
import 'discovery/discovery_source_fetch.dart';
import 'discovery/contract_test_runner.dart';
import 'discovery/discovery_types.dart';
import 'discovery/registry_snapshot.dart';
import 'discovery/shadow_write_kpi.dart';
import 'discovery/shadow_write_runner.dart';
import 'registry_hash_utils.dart';
import 'registry_v3_utils.dart';

const _simSeed = 42;
const _simABatchSize = 500;
const _simBSyntheticNew = 4600;
const _simBDuplicateRate = 0.08;
const _simCTargetScale = 5000;
const _simCGapEnRate = 0.28;
const _simCEnrichEnRate = 0.70;
const _maintainerBudgetMinPerMonth = 20 * 60;
const _g1NetNewPerMonth = 300;
const _g1DedupeRecall = 0.90;

void main(List<String> args) async {
  final root = _findProjectRoot();
  final outDir = Directory(
    p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'scale_5k_sim'),
  );
  outDir.createSync(recursive: true);

  final seed = int.tryParse(_argValue(args, '--seed') ?? '') ?? _simSeed;
  final rng = Random(seed);
  final sims = _parseSims(args);

  print('scale_5k_sim — seed=$seed sims=${sims.join(",")}');
  print('  output: ${outDir.path}\n');

  final results = <Map<String, dynamic>>[];

  if (sims.contains('a')) {
    print('=== SIM-A (A1 throughput) ===');
    final r = await runSimA(root, rng);
    results.add(r);
    _printSimResult(r);
    print('');
  }

  if (sims.contains('b')) {
    print('=== SIM-B (A3 dedupe) ===');
    final r = runSimB(root, rng);
    results.add(r);
    _printSimResult(r);
    print('');
  }

  if (sims.contains('c')) {
    print('=== SIM-C (A2 stub-first / SW1) ===');
    final r = runSimC(root, rng);
    results.add(r);
    _printSimResult(r);
    print('');
  }

  if (sims.contains('d')) {
    print('=== SIM-D (A4 franchise labor) ===');
    final r = runSimD(root, rng);
    results.add(r);
    _printSimResult(r);
    print('');
  }

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'seed': seed,
    'results': results,
    'growthStrategyReview': results.any(
      (r) => r['assumptionId'] == 'A1' && r['verdict'] == 'FAIL',
    ),
  };

  final jsonPath = File(p.join(outDir.path, 'scale_5k_sim_report.json'));
  await jsonPath.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
  );
  print('Wrote: ${jsonPath.path}');
}

Future<Map<String, dynamic>> runSimA(Directory root, Random rng) async {
  const channelId = 'wikidata_manga';
  const config = DiscoveryChannelConfig(
    id: channelId,
    source: 'wikidata',
    category: 'manga',
    domain: 'subculture',
    enabled: false,
    dailyLimit: 500,
    trialBatchSize: 100,
    cursorPath: 'pipeline/discovery/cursors/wikidata_manga.json',
  );

  final contract = ContractTestRunner.fromProject(
    channelId: channelId,
    config: config,
    projectRoot: root,
  );

  var source = 'live_wikidata';
  List<Map<String, dynamic>> nodes;
  try {
    nodes = await fetchDiscoveryBatch(
      config: DiscoveryChannelConfig(
        id: config.id,
        source: config.source,
        category: config.category,
        domain: config.domain,
        enabled: config.enabled,
        dailyLimit: config.dailyLimit,
        trialBatchSize: _simABatchSize,
        cursorPath: config.cursorPath,
      ),
      projectRoot: root,
    );
    if (nodes.length < 100) {
      throw StateError('insufficient live nodes: ${nodes.length}');
    }
  } catch (e) {
    source = 'synthetic_fallback';
    stderr.writeln('SIM-A live fetch failed ($e) — synthetic fallback');
    nodes = _syntheticWikidataNodes(
      rng,
      _simABatchSize,
      contract.registryExternalIds,
    );
  }

  final contractKpi = contract.runOnNodes(nodes);
  final shadowInputs = shadowInputsFromNodes(contract, nodes);
  final shadow = ShadowWriteRunner.fromProject(root).run(shadowInputs);

  final netPerBatch = shadow.kpi.wouldCreate;
  final weeklyNet = netPerBatch;
  final monthlyNet = (weeklyNet * 4.33).round();
  final dailyNet = (netPerBatch * 30).round();

  final maintainerMinPerBatch = _estimateMaintainerMinutes(shadow.kpi);
  final maintainerMinPerMonthWeekly = (maintainerMinPerBatch * 4.33).round();
  final throughputPass = monthlyNet >= _g1NetNewPerMonth;
  final burdenPass = maintainerMinPerMonthWeekly <= _maintainerBudgetMinPerMonth;

  String verdict;
  if (throughputPass && burdenPass) {
    verdict = 'PASS';
  } else if (throughputPass || burdenPass) {
    verdict = 'PARTIAL';
  } else {
    verdict = 'FAIL';
  }

  return {
    'sim': 'SIM-A',
    'assumptionId': 'A1',
    'verdict': verdict,
    'observations': {
      'source': source,
      'inputNodes': nodes.length,
      'contract': contractKpi.toJson(),
      'shadow': shadow.kpi.toJson(),
      'netWouldCreatePerBatch': netPerBatch,
      'projectedNetPerMonth_weeklyBatch': monthlyNet,
      'projectedNetPerMonth_dailyBatch': dailyNet,
      'g1ThresholdNetPerMonth': _g1NetNewPerMonth,
      'maintainerMinutesPerBatch': maintainerMinPerBatch,
      'maintainerMinutesPerMonth_weeklyBatch': maintainerMinPerMonthWeekly,
      'maintainerBudgetMinutesPerMonth': _maintainerBudgetMinPerMonth,
      'throughputPass': throughputPass,
      'burdenPass': burdenPass,
      'conversionRate':
          nodes.isEmpty ? 0.0 : netPerBatch / nodes.length,
      'rejectRate': nodes.isEmpty
          ? 0.0
          : shadow.kpi.wouldReject / nodes.length,
      'dedupeRate': nodes.isEmpty
          ? 0.0
          : (shadow.kpi.wouldMerge + shadow.kpi.mergeCandidates) / nodes.length,
    },
    'impact': verdict == 'FAIL'
        ? 'G1(5k) 공급 경로 미성립 — Growth Strategy 재검토 대상 (루트 가정 붕괴)'
        : verdict == 'PARTIAL'
            ? 'throughput 또는 운영 부담 중 하나만 G1-1 충족 — 파이프라인·운영 조정 필요'
            : 'G1-1 게이트 충족 가능 — 실확장 파일럿 착수 전제 성립',
    'baselineChangeRequired': verdict == 'FAIL',
    'growthStrategyReview': verdict == 'FAIL',
  };
}

Map<String, dynamic> runSimB(Directory root, Random rng) {
  final registry = RegistrySnapshot.load(root);
  final runner = ShadowWriteRunner.fromProject(root);

  final uniqueDrafts = _syntheticGrowthDrafts(
    rng: rng,
    count: _simBSyntheticNew,
    registry: registry,
    duplicateRate: 0,
    startSeq: registry.works.length + 1,
  );

  final duplicateDrafts = _syntheticGrowthDrafts(
    rng: rng,
    count: (_simBSyntheticNew * _simBDuplicateRate).round(),
    registry: registry,
    duplicateRate: 1.0,
    startSeq: registry.works.length + _simBSyntheticNew + 1,
  );

  final allInputs = <ShadowDraftInput>[
    ...uniqueDrafts.map(
      (d) => ShadowDraftInput(
        draft: d,
        contractOutcome: ContractNodeOutcome.minimalCoreDraft,
        externalId: d['externalIds']?['sim']?.toString() ?? '',
        title: d['title']?.toString() ?? '',
      ),
    ),
    ...duplicateDrafts.map(
      (d) => ShadowDraftInput(
        draft: d,
        contractOutcome: ContractNodeOutcome.minimalCoreDraft,
        externalId: d['externalIds']?['sim']?.toString() ?? '',
        title: d['title']?.toString() ?? '',
      ),
    ),
  ];
  allInputs.shuffle(rng);

  final shadow = runner.run(allInputs);

  final intentionalDuplicates = duplicateDrafts.length;
  var preCaught = 0;
  for (final item in shadow.items) {
    if (item.outcome == ShadowWriteOutcome.wouldMerge ||
        item.outcome == ShadowWriteOutcome.mergeCandidate) {
      final ext = item.externalId;
      if (duplicateDrafts.any(
        (d) => d['externalIds']?['sim']?.toString() == ext,
      )) {
        preCaught++;
      }
    }
  }

  final preRecall =
      intentionalDuplicates == 0 ? 1.0 : preCaught / intentionalDuplicates;

  final slipped = <ShadowWriteItem>[];
  for (final item in shadow.items) {
    if (item.outcome != ShadowWriteOutcome.wouldCreate) continue;
    if (duplicateDrafts.any(
      (d) => d['externalIds']?['sim']?.toString() == item.externalId,
    )) {
      slipped.add(item);
    }
  }

  final virtualWorks = [
    ...registry.works.map((w) => _workRefFromEntry(w)),
    ...shadow.items
        .where((i) => i.outcome == ShadowWriteOutcome.wouldCreate)
        .map(
          (i) => _WorkRef(
            workId: i.shadowWorkId ?? 'wk_PENDING',
            title: i.title,
            category: i.draft?['category']?.toString() ?? '',
            releaseYear: i.draft?['releaseYear'] is int
                ? i.draft!['releaseYear'] as int
                : null,
            externalIds: _parseExternalIds(i.draft?['externalIds']),
            legacyIds: const [],
          ),
        ),
  ];

  final postIssues = _detectDedupeIssues(virtualWorks, const {}, const {});
  final slippedIds = slipped.map((s) => s.shadowWorkId).whereType<String>().toSet();
  var postResidual = 0;
  for (final issue in postIssues) {
    final ids = issue.works.map((w) => w.workId).toSet();
    if (ids.any(slippedIds.contains)) postResidual++;
  }

  final prePass = preRecall >= _g1DedupeRecall;
  final postPass = postResidual == 0;

  String verdict;
  if (prePass && postPass) {
    verdict = 'PASS';
  } else if (prePass || postPass) {
    verdict = 'PARTIAL';
  } else {
    verdict = 'FAIL';
  }

  return {
    'sim': 'SIM-B',
    'assumptionId': 'A3',
    'verdict': verdict,
    'observations': {
      'registryBaseline': registry.works.length,
      'syntheticUnique': uniqueDrafts.length,
      'intentionalDuplicates': intentionalDuplicates,
      'duplicateRate': _simBDuplicateRate,
      'shadowKpi': shadow.kpi.toJson(),
      'preInsertRecall': preRecall,
      'preInsertCaught': preCaught,
      'preInsertThreshold': _g1DedupeRecall,
      'slippedWouldCreate': slipped.length,
      'postInsertResidualIssues': postResidual,
      'postInsertTotalIssues': postIssues.length,
    },
    'impact': verdict == 'FAIL'
        ? '배치 유입 시 중복 wk_ 오염 — ingest 게이트 Baseline 추가 필요'
        : verdict == 'PARTIAL'
            ? '사후 dedupe_linter는 보완 가능하나 pre-insert recall 부족 — shadow_write 의존 위험'
            : '5k 구간 사후 dedupe + shadow_write로 A3 유지 가능',
    'baselineChangeRequired': verdict != 'PASS',
    'growthStrategyReview': false,
  };
}

Map<String, dynamic> runSimC(Directory root, Random rng) {
  final baselineIndex = _loadSearchIndex(root);
  final queries = _loadGsQueries(root);
  final evalQueries = queries.where((q) => !q.excludeFromRecall).toList();

  final baselineRecall = _recallAtK(baselineIndex, evalQueries, k: 10);

  final gapIndex = _buildScaledIndex(
    baselineIndex: baselineIndex,
    targetCount: _simCTargetScale,
    enRate: _simCGapEnRate,
    rng: rng,
    label: 'gap',
  );
  final enrichIndex = _buildScaledIndex(
    baselineIndex: baselineIndex,
    targetCount: _simCTargetScale,
    enRate: _simCEnrichEnRate,
    rng: rng,
    label: 'enrich',
  );

  final gapRecall = _recallAtK(gapIndex, evalQueries, k: 10);
  final enrichRecall = _recallAtK(enrichIndex, evalQueries, k: 10);

  final gapEnRate = _measureEnRate(gapIndex);
  final enrichEnRate = _measureEnRate(enrichIndex);

  final enrichMaintains =
      enrichRecall.rate >= baselineRecall.rate - 0.01;
  final gapDegrades = gapRecall.rate < baselineRecall.rate - 0.02;

  String verdict;
  if (enrichMaintains && !gapDegrades) {
    verdict = 'PASS';
  } else if (enrichMaintains || gapRecall.rate >= baselineRecall.rate - 0.05) {
    verdict = 'PARTIAL';
  } else {
    verdict = 'FAIL';
  }

  return {
    'sim': 'SIM-C',
    'assumptionId': 'A2',
    'verdict': verdict,
    'observations': {
      'evalQueryCount': evalQueries.length,
      'baseline402': {
        'recallAt10': baselineRecall.rate,
        'hits': baselineRecall.hits,
        'enTitleRate': _measureEnRate(baselineIndex),
      },
      'synthetic5k_gap': {
        'recallAt10': gapRecall.rate,
        'hits': gapRecall.hits,
        'enTitleRate': gapEnRate,
        'deltaVsBaseline': gapRecall.rate - baselineRecall.rate,
      },
      'synthetic5k_enrich': {
        'recallAt10': enrichRecall.rate,
        'hits': enrichRecall.hits,
        'enTitleRate': enrichEnRate,
        'deltaVsBaseline': enrichRecall.rate - baselineRecall.rate,
      },
      'tokenCollisionNote':
          '5k 확장 시 searchTokens 부분일치 stub이 recall@10 순위를 밀어낼 수 있음',
    },
    'impact': verdict == 'FAIL'
        ? 'stub-first 대량 유입이 SW1 recall 저하 — enrich SLA를 G1 전제로 승격 필요'
        : verdict == 'PARTIAL'
            ? 'enrich 규율 없이 확장 시 품질 리스크 — G1-3 조건부 통과'
            : 'enrich 목표(70%+) 적용 시 5k에서 SW1 recall 유지 가능',
    'baselineChangeRequired': verdict == 'FAIL',
    'growthStrategyReview': false,
  };
}

Map<String, dynamic> runSimD(Directory root, Random rng) {
  final memberToFranchise = _loadFranchiseMemberMap(root);
  final baselineIndex = _loadSearchIndex(root);
  final baselineClusters = _franchiseClusters(baselineIndex, memberToFranchise);

  var scaledIndex = _buildScaledIndex(
    baselineIndex: baselineIndex,
    targetCount: _simCTargetScale,
    enRate: _simCGapEnRate,
    rng: rng,
    label: 'franchise',
    franchiseSkew: false,
  );
  scaledIndex = _injectCrossMediaIpPairs(
    index: scaledIndex,
    pairCount: 60,
    rng: rng,
    memberToFranchise: memberToFranchise,
  );
  final scaledClusters = _franchiseClusters(scaledIndex, memberToFranchise);

  const minutesPerCluster = 15.0;
  const minutesPerUncoveredMember = 5.0;

  final baselineLabor = _estimateFranchiseLabor(
    baselineClusters,
    minutesPerCluster: minutesPerCluster,
    minutesPerMember: minutesPerUncoveredMember,
  );
  final scaledLabor = _estimateFranchiseLabor(
    scaledClusters,
    minutesPerCluster: minutesPerCluster,
    minutesPerMember: minutesPerUncoveredMember,
  );

  final activeClusters =
      scaledClusters.uncoveredClusters - scaledClusters.deferredClusters;
  final activeLabor = activeClusters * minutesPerCluster +
      scaledClusters.uncoveredMembers * minutesPerUncoveredMember;
  final deltaClusters =
      scaledClusters.uncoveredClusters - baselineClusters.uncoveredClusters;
  final deltaLabor = activeLabor - baselineLabor;
  final laborHours5k = activeLabor / 60;

  // maintainer 25% 시간을 franchise에 할당 (월 5h)
  const monthlyFranchiseCapacityMin = _maintainerBudgetMinPerMonth * 0.25;
  final backlogMonths = deltaLabor / monthlyFranchiseCapacityMin;

  String verdict;
  if (activeLabor <= 2400 && backlogMonths <= 6) {
    verdict = 'PASS';
  } else if (activeLabor <= 4800 && backlogMonths <= 12) {
    verdict = 'PARTIAL';
  } else {
    verdict = 'FAIL';
  }

  return {
    'sim': 'SIM-D',
    'assumptionId': 'A4',
    'verdict': verdict,
    'observations': {
      'baseline402': baselineClusters.toJson(),
      'scaled5k': scaledClusters.toJson(),
      'baselineLaborMinutes': baselineLabor.round(),
      'scaled5kLaborMinutes_allClusters': scaledLabor.round(),
      'scaled5kLaborMinutes_activeClusters': activeLabor.round(),
      'activeClusters_afterDefer': activeClusters,
      'deltaLaborMinutes': deltaLabor.round(),
      'deltaLaborHours': (deltaLabor / 60).toStringAsFixed(1),
      'estimatedBacklogMonths_at25pctMaintainer': backlogMonths.toStringAsFixed(1),
      'injectedCrossMediaPairs': 60,
      'assumption':
          '지연 생성 — 2×2 소규모 defer + 60 IP 신규 크로스미디어 쌍 주입, 활성 클러스터당 15분 + 미커버 멤버 5분',
    },
    'impact': verdict == 'FAIL'
        ? '5k에서 franchise 수동 큐 폭발 — 지연 생성 정책·headcount 전제 재검토'
        : verdict == 'PARTIAL'
            ? '지연 생성으로 버틸 수 있으나 큐 누적 시작 — G1 중 tier 정책 수치화 필요'
            : '5k 구간 franchise 운영 비용 통제 가능',
    'baselineChangeRequired': verdict == 'FAIL',
    'growthStrategyReview': false,
  };
}

// --- Helpers ---

int _estimateMaintainerMinutes(ShadowWriteKpi kpi) {
  const mergeCandidateMin = 8;
  const wouldCreateMin = 1;
  const batchOverheadMin = 60;
  return batchOverheadMin +
      kpi.mergeCandidates * mergeCandidateMin +
      kpi.wouldCreate * wouldCreateMin;
}

List<Map<String, dynamic>> _syntheticAnilistNodes(
  Random rng,
  int count,
  Set<String> registryAnilistIds,
) {
  final nodes = <Map<String, dynamic>>[];
  for (var i = 0; i < count; i++) {
    final id = 900000 + i;
    final inRegistry = registryAnilistIds.contains('$id');
    if (inRegistry) continue;
    nodes.add({
      'id': id,
      'format': 'TV',
      'title': {
        'romaji': 'Simu Anime $id',
        'english': rng.nextDouble() < 0.7 ? 'Simu Anime $id' : null,
        'native': 'シミュアニメ$id',
      },
      'synonyms': ['SA$id'],
      'startDate': {'year': 2000 + (i % 25)},
      'seasonYear': 2000 + (i % 25),
      'studios': {
        'nodes': [
          {'name': 'Studio ${i % 40}'},
        ],
      },
    });
  }
  while (nodes.length < count) {
    final id = 910000 + nodes.length;
    nodes.add({
      'id': id,
      'format': 'TV',
      'title': {
        'romaji': 'Extra Simu $id',
        'english': 'Extra Simu $id',
        'native': 'エクストラ$id',
      },
      'startDate': {'year': 2015},
      'studios': {'nodes': [{'name': 'Studio X'}]},
    });
  }
  return nodes.take(count).toList();
}

List<Map<String, dynamic>> _syntheticWikidataNodes(
  Random rng,
  int count,
  Set<String> registryWikidataIds,
) {
  final nodes = <Map<String, dynamic>>[];
  for (var i = 0; i < count; i++) {
    final qid = 'Q${950000 + i}';
    if (registryWikidataIds.contains(qid)) continue;
    nodes.add({
      'qid': qid,
      'title': 'Simu Manga $qid',
      'titles': {
        'en': 'Simu Manga $qid',
        if (rng.nextDouble() < 0.5) 'ja': 'シミュ漫画$i',
      },
      'releaseYear': 2000 + (i % 25),
      'creator': 'Mangaka ${i % 40}',
      'category': 'manga',
    });
  }
  while (nodes.length < count) {
    final qid = 'Q${960000 + nodes.length}';
    nodes.add({
      'qid': qid,
      'title': 'Extra Simu $qid',
      'releaseYear': 2015,
      'category': 'manga',
    });
  }
  return nodes.take(count).toList();
}

List<Map<String, dynamic>> _syntheticGrowthDrafts({
  required Random rng,
  required int count,
  required RegistrySnapshot registry,
  required double duplicateRate,
  required int startSeq,
}) {
  final drafts = <Map<String, dynamic>>[];
  final pool = registry.works;
  for (var i = 0; i < count; i++) {
    final seq = startSeq + i;
    if (duplicateRate > 0 && pool.isNotEmpty) {
      final src = pool[rng.nextInt(pool.length)];
      final mode = rng.nextInt(3);
      if (mode == 0) {
        drafts.add({
          'title': src.title,
          'category': src.category,
          'domain': 'subculture',
          'releaseYear': src.releaseYear,
          'creator': 'Dup Studio',
          'externalIds': Map<String, String>.from(src.externalIds),
          'aliases': ['dup-$seq'],
        });
        continue;
      }
      if (mode == 1) {
        drafts.add({
          'title': src.title,
          'category': src.category,
          'domain': 'subculture',
          'releaseYear': src.releaseYear,
          'creator': 'Dup Studio',
          'externalIds': {'sim': 'dup-ext-$seq'},
        });
        continue;
      }
      drafts.add({
        'title': '${src.title} (Sim Duplicate)',
        'category': src.category,
        'domain': 'subculture',
        'releaseYear': src.releaseYear,
        'creator': 'Dup Studio',
        'externalIds': {'sim': 'dup-fuzzy-$seq'},
        'titles': {'en': src.title},
      });
      continue;
    }

    drafts.add({
      'title': 'Growth Work $seq',
      'category': _categories[rng.nextInt(_categories.length)],
      'domain': 'subculture',
      'releaseYear': 1990 + (seq % 35),
      'creator': 'Growth Studio ${seq % 50}',
      'externalIds': {'sim': 'growth-$seq'},
      'titles': {
        if (rng.nextDouble() < 0.5) 'en': 'Growth Work $seq',
        if (rng.nextDouble() < 0.3) 'ja': '成長作品$seq',
      },
      'aliases': ['GW$seq'],
    });
  }
  return drafts;
}

const _categories = [
  'animation',
  'manga',
  'game',
  'book',
  'movie',
];

List<Map<String, dynamic>> _loadSearchIndex(Directory root) {
  final path = File(p.join(root.path, 'akasha-db', 'search_index.json'));
  final decoded = json.decode(path.readAsStringSync());
  if (decoded is! List) return [];
  return decoded
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

double _measureEnRate(List<Map<String, dynamic>> index) {
  if (index.isEmpty) return 0;
  var withEn = 0;
  for (final e in index) {
    final titles = e['titles'];
    if (titles is Map && titles['en']?.toString().trim().isNotEmpty == true) {
      withEn++;
    }
  }
  return withEn / index.length;
}

class _RecallResult {
  final double rate;
  final int hits;
  const _RecallResult(this.rate, this.hits);
}

_RecallResult _recallAtK(
  List<Map<String, dynamic>> index,
  List<_GsQuery> queries, {
  required int k,
}) {
  if (queries.isEmpty) return const _RecallResult(0, 0);
  var hits = 0;
  for (final q in queries) {
    if (q.expectedWorkIds.isEmpty) continue;
    final matched = _searchTopK(index, q.query, k);
    final ok = q.expectedWorkIds.any(matched.contains) ||
        q.acceptableWorkIds.any(matched.contains);
    if (ok) hits++;
  }
  final evaluable =
      queries.where((q) => q.expectedWorkIds.isNotEmpty).length;
  return _RecallResult(evaluable == 0 ? 0 : hits / evaluable, hits);
}

List<String> _searchTopK(List<Map<String, dynamic>> index, String query, int k) {
  final q = query.toLowerCase().replaceAll(' ', '');
  if (q.isEmpty) return [];

  final hits = <_ScoredHit>[];
  for (final entry in index) {
    final tokens = (entry['searchTokens'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    var match = false;
    for (final token in tokens) {
      if (token.contains(q)) {
        match = true;
        break;
      }
    }
    if (!match) {
      final title = entry['title']?.toString().toLowerCase().replaceAll(' ', '') ?? '';
      if (title.contains(q)) match = true;
    }
    if (!match) continue;
    hits.add(
      _ScoredHit(
        entry['workId']?.toString() ?? '',
        (entry['qualityScore'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  hits.sort((a, b) => b.score.compareTo(a.score));
  return hits.take(k).map((h) => h.workId).where((id) => id.isNotEmpty).toList();
}

class _ScoredHit {
  final String workId;
  final int score;
  const _ScoredHit(this.workId, this.score);
}

List<Map<String, dynamic>> _buildScaledIndex({
  required List<Map<String, dynamic>> baselineIndex,
  required int targetCount,
  required double enRate,
  required Random rng,
  required String label,
  bool franchiseSkew = false,
}) {
  final out = baselineIndex.map((e) => Map<String, dynamic>.from(e)).toList();
  var seq = out.length + 1;
  final franchiseStems = [
    'naruto',
    'sao',
    'demonslayer',
    'fma',
    'spyfamily',
    'onepiece',
    'pokemon',
    'marvel',
  ];

  while (out.length < targetCount) {
    final workId = 'wk_${seq.toString().padLeft(9, '0')}';
    final category = _categories[seq % _categories.length];
    final hex = shardHexForWorkId(workId);
    final stem = franchiseSkew
        ? franchiseStems[seq % franchiseStems.length]
        : 'growth';
    final title = franchiseSkew
        ? '${stem[0].toUpperCase()}${stem.substring(1)} Spinoff $seq'
        : 'Growth $category ${seq.toString().padLeft(5, '0')}';
    final hasEn = rng.nextDouble() < enRate;
    final titles = <String, String>{
      if (hasEn) 'en': title,
      if (rng.nextDouble() < 0.25) 'ja': '成長$seq',
      if (rng.nextDouble() < 0.10) 'ko': '성장 $seq',
    };
    final aliases = <String>[
      if (rng.nextDouble() < 0.15) stem,
      if (rng.nextDouble() < 0.10) 'stub$seq',
    ];
    final creator = 'Studio ${seq % 80}';
    final searchTokens = buildWorkSearchTokens(
      legacyTitle: title,
      titles: titles,
      aliases: aliases,
      creator: creator,
      tags: const [],
    );

    out.add({
      'workId': workId,
      'title': title,
      'shardId': '${category}_$hex',
      'category': category,
      'domain': 'subculture',
      'creator': creator,
      'tags': [],
      'searchTokens': searchTokens,
      if (titles.isNotEmpty) 'titles': titles,
      'qualityScore': 35 + (seq % 30),
      'qualityTier': 2 + (seq % 2),
    });
    seq++;
  }
  return out;
}

class _GsQuery {
  final String id;
  final String query;
  final List<String> expectedWorkIds;
  final List<String> acceptableWorkIds;
  final bool excludeFromRecall;
  const _GsQuery({
    required this.id,
    required this.query,
    required this.expectedWorkIds,
    this.acceptableWorkIds = const [],
    this.excludeFromRecall = false,
  });
}

List<_GsQuery> _loadGsQueries(Directory root) {
  final path = File(p.join(root.path, 'docs', 'global-search-query-set.md'));
  if (!path.existsSync()) return [];
  final lines = path.readAsLinesSync();
  final queries = <_GsQuery>[];

  for (final line in lines) {
    if (!line.startsWith('| GS')) continue;
    if (line.contains('id | query')) continue;
    final parts = line.split('|').map((s) => s.trim()).toList();
    if (parts.length < 8) continue;
    final id = parts[1];
    final query = parts[2].replaceAll('`', '');
    final expectedRaw = parts[3];
    final exclude = expectedRaw.contains('미수록') ||
        expectedRaw.contains('NOT_IN_REGISTRY') ||
        expectedRaw.trim() == '—' ||
        expectedRaw.contains('402에') && !expectedRaw.contains('wk_');
    final ids = RegExp(r'wk_\d+')
        .allMatches(expectedRaw)
        .map((m) => m.group(0)!)
        .toList();
    queries.add(
      _GsQuery(
        id: id,
        query: query,
        expectedWorkIds: ids,
        excludeFromRecall: exclude,
      ),
    );
  }
  return queries;
}

class _FranchiseClusterStats {
  final int titleStemClusters;
  final int multiMediaClusters;
  final int uncoveredClusters;
  final int uncoveredMembers;
  final int deferredClusters;

  const _FranchiseClusterStats({
    required this.titleStemClusters,
    required this.multiMediaClusters,
    required this.uncoveredClusters,
    required this.uncoveredMembers,
    required this.deferredClusters,
  });

  Map<String, dynamic> toJson() => {
        'titleStemClusters': titleStemClusters,
        'multiMediaClusters': multiMediaClusters,
        'uncoveredClusters': uncoveredClusters,
        'uncoveredMembers': uncoveredMembers,
        'deferredClusters_tier2': deferredClusters,
      };
}

Map<String, String> _loadFranchiseMemberMap(Directory root) {
  final path = File(p.join(root.path, 'akasha-db', 'franchise_groups.json'));
  if (!path.existsSync()) return {};
  final raw = json.decode(path.readAsStringSync());
  if (raw is! Map) return {};
  final out = <String, String>{};
  raw.forEach((franchiseId, value) {
    if (franchiseId.startsWith('_')) return;
    if (value is! Map) return;
    final members =
        (value['members'] as List?)?.map((e) => e.toString()) ?? const [];
    for (final member in members) {
      out[member] = franchiseId;
    }
  });
  return out;
}

_FranchiseClusterStats _franchiseClusters(
  List<Map<String, dynamic>> index,
  Map<String, String> memberToFranchise,
) {
  final clusters = <String, List<Map<String, dynamic>>>{};
  for (final entry in index) {
    final workId = entry['workId']?.toString() ?? '';
    final stem = _ipTitleStem(entry['title']?.toString() ?? '');
    if (stem.isEmpty) continue;
    clusters.putIfAbsent(stem, () => []).add(entry);
  }

  var multi = 0;
  var uncovered = 0;
  var uncoveredMembers = 0;
  var deferred = 0;

  for (final members in clusters.values) {
    if (members.length < 2) continue;
    final categories = members.map((m) => m['category']?.toString()).toSet();
    if (categories.length < 2) continue;
    multi++;

    final franchiseIds = <String>{};
    var missing = 0;
    for (final m in members) {
      final wid = m['workId']?.toString() ?? '';
      final fid = memberToFranchise[wid];
      if (fid == null) {
        missing++;
      } else {
        franchiseIds.add(fid);
      }
    }

    if (missing == 0 && franchiseIds.length == 1) continue;

    uncovered++;
    uncoveredMembers += missing;

    // ADR-006 지연 생성: 2작품·2매체 소규모 클러스터는 tier-2 defer
    if (members.length <= 2 && categories.length == 2) {
      deferred++;
    }
  }

  return _FranchiseClusterStats(
    titleStemClusters: clusters.length,
    multiMediaClusters: multi,
    uncoveredClusters: uncovered,
    uncoveredMembers: uncoveredMembers,
    deferredClusters: deferred,
  );
}

List<Map<String, dynamic>> _injectCrossMediaIpPairs({
  required List<Map<String, dynamic>> index,
  required int pairCount,
  required Random rng,
  required Map<String, String> memberToFranchise,
}) {
  final out = List<Map<String, dynamic>>.from(index);
  var seq = out.length + 1;
  const mediaPairs = [
    ['animation', 'manga'],
    ['animation', 'game'],
    ['manga', 'movie'],
    ['game', 'book'],
  ];

  for (var p = 0; p < pairCount; p++) {
    final ip = 'simip${p.toString().padLeft(3, '0')}';
    final pair = mediaPairs[p % mediaPairs.length];
    for (final category in pair) {
      final workId = 'wk_${seq.toString().padLeft(9, '0')}';
      if (memberToFranchise.containsKey(workId)) continue;
      final hex = shardHexForWorkId(workId);
      final title = '${ip[0].toUpperCase()}${ip.substring(1)} $category';
      out.add({
        'workId': workId,
        'title': title,
        'shardId': '${category}_$hex',
        'category': category,
        'domain': 'subculture',
        'creator': 'Sim IP Studio $p',
        'tags': [ip],
        'searchTokens': buildWorkSearchTokens(
          legacyTitle: title,
          titles: {'en': title, 'ja': 'シム$ip'},
          aliases: [ip],
          creator: 'Sim IP Studio $p',
          tags: [ip],
        ),
        'titles': {'en': title, 'ja': 'シム$ip'},
        'qualityScore': 55,
        'qualityTier': 3,
      });
      seq++;
    }
  }
  return out;
}

String _ipTitleStem(String title) {
  final norm = normalizeTitle(title);
  if (norm.length < 4) return '';
  // 공통 IP 접두 (Growth Stub 12345 → growthstu)
  final stemLen = norm.length < 8 ? 4 : 8;
  return norm.substring(0, stemLen);
}

double _estimateFranchiseLabor(
  _FranchiseClusterStats stats, {
  required double minutesPerCluster,
  required double minutesPerMember,
}) {
  return stats.uncoveredClusters * minutesPerCluster +
      stats.uncoveredMembers * minutesPerMember;
}

class _WorkRef {
  final String workId;
  final String title;
  final String category;
  final int? releaseYear;
  final Map<String, String> externalIds;
  final List<String> legacyIds;
  const _WorkRef({
    required this.workId,
    required this.title,
    required this.category,
    required this.releaseYear,
    required this.externalIds,
    required this.legacyIds,
  });
}

_WorkRef _workRefFromEntry(RegistryWorkEntry e) => _WorkRef(
      workId: e.workId,
      title: e.title,
      category: e.category,
      releaseYear: e.releaseYear,
      externalIds: e.externalIds,
      legacyIds: e.legacyIds,
    );

Map<String, String> _parseExternalIds(dynamic raw) {
  if (raw is! Map) return {};
  return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
}

class _DedupeIssue {
  final String signal;
  final List<_WorkRef> works;
  const _DedupeIssue({required this.signal, required this.works});
}

List<_DedupeIssue> _detectDedupeIssues(
  List<_WorkRef> works,
  Set<String> allowedPairs,
  Map<String, Set<String>> franchisePeers,
) {
  final issues = <_DedupeIssue>[];

  final byExternal = <String, List<_WorkRef>>{};
  for (final w in works) {
    w.externalIds.forEach((source, value) {
      final id = value.trim();
      if (id.isEmpty) return;
      final key = '${source.toLowerCase()}:$id';
      byExternal.putIfAbsent(key, () => []).add(w);
    });
  }

  for (final group in byExternal.values) {
    if (group.length < 2) continue;
    for (var i = 0; i < group.length; i++) {
      for (var j = i + 1; j < group.length; j++) {
        final a = group[i];
        final b = group[j];
        if (a.category != b.category) continue;
        if (isPairAllowed(a.workId, b.workId, allowedPairs)) continue;
        if (isFranchiseSibling(a.workId, b.workId, franchisePeers)) continue;
        issues.add(_DedupeIssue(signal: 'externalId', works: [a, b]));
      }
    }
  }

  final byTitle = <String, List<_WorkRef>>{};
  for (final w in works) {
    final norm = normalizeTitle(w.title);
    if (norm.length < 2) continue;
    final key = '${w.category}::$norm';
    byTitle.putIfAbsent(key, () => []).add(w);
  }

  for (final group in byTitle.values) {
    final distinct = <String, _WorkRef>{};
    for (final w in group) {
      distinct[w.workId] = w;
    }
    final list = distinct.values.toList();
    if (list.length < 2) continue;
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i];
        final b = list[j];
        if (!releaseYearsCompatible(a.releaseYear, b.releaseYear)) continue;
        if (isPairAllowed(a.workId, b.workId, allowedPairs)) continue;
        if (isFranchiseSibling(a.workId, b.workId, franchisePeers)) continue;
        issues.add(_DedupeIssue(signal: 'fuzzyTitle', works: [a, b]));
      }
    }
  }

  return issues;
}

void _printSimResult(Map<String, dynamic> r) {
  print('  ${r['assumptionId']} ${r['sim']}: ${r['verdict']}');
  print('  observations: ${json.encode(r['observations'])}');
  print('  impact: ${r['impact']}');
  print('  baselineChangeRequired: ${r['baselineChangeRequired']}');
}

List<String> _parseSims(List<String> args) {
  final raw = _argValue(args, '--sim');
  if (raw == null || raw.isEmpty) return ['a', 'b', 'c', 'd'];
  return raw.split(',').map((s) => s.trim().toLowerCase()).toList();
}

String? _argValue(List<String> args, String name) {
  for (final arg in args) {
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('project root not found');
}
