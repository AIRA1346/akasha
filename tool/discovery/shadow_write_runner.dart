// Shadow Write — Minimal Core Draft → wk_·shard·dedupe·registry_builder 시뮬레이션.
//
// 실제 shard 저장 없음.
library;

import 'dart:io';

import '../data_policy_utils.dart';
import '../dedupe_utils.dart';
import '../quality_score_utils.dart';
import '../registry_hash_utils.dart';
import '../registry_v3_utils.dart';
import '../wk_id_utils.dart';
import 'contract_test_runner.dart';
import 'registry_snapshot.dart';
import 'shadow_write_kpi.dart';

enum ShadowWriteOutcome {
  wouldCreate,
  wouldMerge,
  /// fuzzy title 중복 — dedupe 성공, 정책 실패 아님
  mergeCandidate,
  wouldReject,
}

class ShadowDraftInput {
  final Map<String, dynamic> draft;
  final ContractNodeOutcome contractOutcome;
  final String externalId;
  final String title;

  const ShadowDraftInput({
    required this.draft,
    required this.contractOutcome,
    required this.externalId,
    required this.title,
  });
}

class ShadowWriteResult {
  final ShadowWriteKpi kpi;
  final List<ShadowWriteItem> items;

  const ShadowWriteResult({required this.kpi, this.items = const []});
}

class ShadowWriteItem {
  final ShadowWriteOutcome outcome;
  final String? shadowWorkId;
  final String? targetShard;
  final int? qualityScore;
  final int? qualityTier;
  final String? reason;
  final String externalId;
  final String title;
  final Map<String, dynamic>? draft;
  final String? matchedWorkId;

  const ShadowWriteItem({
    required this.outcome,
    required this.externalId,
    required this.title,
    this.shadowWorkId,
    this.targetShard,
    this.qualityScore,
    this.qualityTier,
    this.reason,
    this.draft,
    this.matchedWorkId,
  });
}

class ShadowWriteRunner {
  final Directory projectRoot;
  final RegistrySnapshot registry;
  final Set<String> allowedPairs;
  final Map<String, Set<String>> franchisePeers;
  final int nextWkSequence;

  ShadowWriteRunner({
    required this.projectRoot,
    required this.registry,
    required this.allowedPairs,
    required this.franchisePeers,
    required this.nextWkSequence,
  });

  factory ShadowWriteRunner.fromProject(Directory projectRoot) {
    return ShadowWriteRunner(
      projectRoot: projectRoot,
      registry: RegistrySnapshot.load(projectRoot),
      allowedPairs: loadDedupeAllowedPairs(projectRoot),
      franchisePeers: loadFranchisePeers(projectRoot),
      nextWkSequence: readNextWkSequence(projectRoot) ?? 1,
    );
  }

  ShadowWriteResult run(List<ShadowDraftInput> inputs) {
    var wouldCreate = 0;
    var wouldMerge = 0;
    var mergeCandidates = 0;
    var wouldReject = 0;
    final shardDist = <String, int>{};
    final scoreDist = <String, int>{};
    final tierDist = <String, int>{};
    final scores = <int>[];
    final items = <ShadowWriteItem>[];
    final pendingCreates = <_PendingCreate>[];

    var seq = nextWkSequence;

    for (final input in inputs) {
      final draft = Map<String, dynamic>.from(input.draft);

      if (input.contractOutcome == ContractNodeOutcome.dedupeCandidate) {
        wouldMerge++;
        items.add(
          ShadowWriteItem(
            outcome: ShadowWriteOutcome.wouldMerge,
            externalId: input.externalId,
            title: input.title,
            reason: 'contract:external_id_already_in_registry',
          ),
        );
        continue;
      }

      if (input.contractOutcome != ContractNodeOutcome.minimalCoreDraft) {
        wouldReject++;
        items.add(
          ShadowWriteItem(
            outcome: ShadowWriteOutcome.wouldReject,
            externalId: input.externalId,
            title: input.title,
            reason: 'contract:${input.contractOutcome.name}',
          ),
        );
        continue;
      }

      final mergeMatch = _findExternalMerge(draft);
      if (mergeMatch != null) {
        wouldMerge++;
        items.add(
          ShadowWriteItem(
            outcome: ShadowWriteOutcome.wouldMerge,
            externalId: input.externalId,
            title: input.title,
            reason: 'externalId:$mergeMatch',
          ),
        );
        continue;
      }

      final fuzzyMatch = _findFuzzyDuplicate(draft, pendingCreates);
      if (fuzzyMatch != null) {
        mergeCandidates++;
        items.add(
          ShadowWriteItem(
            outcome: ShadowWriteOutcome.mergeCandidate,
            externalId: input.externalId,
            title: input.title,
            draft: Map<String, dynamic>.from(draft),
            matchedWorkId: fuzzyMatch,
            reason: 'fuzzyTitle:$fuzzyMatch',
          ),
        );
        continue;
      }

      final shadowWk = formatWkId(seq++);
      draft['workId'] = shadowWk;

      final shardPath = v4ShardPath(
        draft['category']?.toString() ?? 'unknown',
        shardHexForWorkId(shadowWk),
      );
      final policyIssues = lintWorkEntry(
        workId: shadowWk,
        work: draft,
        relativePath: shardPath,
      );
      if (policyIssues.isNotEmpty) {
        wouldReject++;
        items.add(
          ShadowWriteItem(
            outcome: ShadowWriteOutcome.wouldReject,
            externalId: input.externalId,
            title: input.title,
            shadowWorkId: shadowWk,
            reason: 'policy:${policyIssues.first.rule}',
          ),
        );
        continue;
      }

      final signals = resolveQualitySignals(draft, franchiseMember: false);
      final score = computeQualityScore(draft, signals);
      final tier = qualityTierFromScore(score);

      wouldCreate++;
      scores.add(score);
      final shardKey = shardPath;
      shardDist[shardKey] = (shardDist[shardKey] ?? 0) + 1;
      scoreDist[_scoreBucket(score)] = (scoreDist[_scoreBucket(score)] ?? 0) + 1;
      tierDist['$tier'] = (tierDist['$tier'] ?? 0) + 1;

      pendingCreates.add(_PendingCreate.fromDraft(draft, shadowWk));

      items.add(
        ShadowWriteItem(
          outcome: ShadowWriteOutcome.wouldCreate,
          externalId: input.externalId,
          title: input.title,
          shadowWorkId: shadowWk,
          targetShard: shardPath,
          qualityScore: score,
          qualityTier: tier,
          draft: Map<String, dynamic>.from(draft),
        ),
      );
    }

    final duplicateRate = inputs.isEmpty
        ? 0.0
        : (wouldMerge + mergeCandidates) / inputs.length;

    final simulation = _simulateRegistryBuild(pendingCreates);

    return ShadowWriteResult(
      kpi: ShadowWriteKpi(
        inputDrafts: inputs.length,
        wouldCreate: wouldCreate,
        wouldMerge: wouldMerge,
        mergeCandidates: mergeCandidates,
        wouldReject: wouldReject,
        targetShardDistribution: shardDist,
        qualityScoreDistribution: scoreDist,
        qualityTierDistribution: tierDist,
        duplicateRate: duplicateRate,
        qualityScoreMin: scores.isEmpty ? 0 : scores.reduce((a, b) => a < b ? a : b),
        qualityScoreMax: scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b),
        qualityScoreMean: scores.isEmpty
            ? 0
            : scores.reduce((a, b) => a + b) / scores.length,
        registrySimulation: simulation,
      ),
      items: items,
    );
  }

  String? _findExternalMerge(Map<String, dynamic> draft) {
    final ext = draft['externalIds'];
    if (ext is! Map) return null;
    for (final entry in ext.entries) {
      final source = entry.key.toString().toLowerCase();
      final id = entry.value?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      final key = '$source:$id';
      final matches = registry.byExternalKey[key];
      if (matches != null && matches.isNotEmpty) {
        return matches.first.workId;
      }
    }
    return null;
  }

  String? _findFuzzyDuplicate(
    Map<String, dynamic> draft,
    List<_PendingCreate> pending,
  ) {
    final category = draft['category']?.toString() ?? '';
    final year = draft['releaseYear'] is int
        ? draft['releaseYear'] as int
        : int.tryParse(draft['releaseYear']?.toString() ?? '');
    final norms = _normalizedTitlesFromDraft(draft);

    for (final norm in norms) {
      if (norm.length < 2) continue;
      final key = '$category::$norm';
      final registryHits = registry.byTitleKey[key] ?? const [];
      for (final hit in registryHits) {
        if (!releaseYearsCompatible(year, hit.releaseYear)) continue;
        return hit.workId;
      }
      for (final pendingItem in pending) {
        if (pendingItem.category != category) continue;
        if (!pendingItem.normalizedTitles.contains(norm)) continue;
        if (!releaseYearsCompatible(year, pendingItem.releaseYear)) continue;
        return pendingItem.shadowWorkId;
      }
    }
    return null;
  }

  RegistryBuildSimulation _simulateRegistryBuild(List<_PendingCreate> creates) {
    final sw = Stopwatch()..start();
    final allWorks = <String, Map<String, dynamic>>{};
    for (final w in registry.works) {
      allWorks[w.workId] = Map<String, dynamic>.from(w.work);
    }

    for (final c in creates) {
      allWorks[c.shadowWorkId] = Map<String, dynamic>.from(c.draft);
    }

    var searchBuilt = 0;
    for (final entry in allWorks.entries) {
      final work = entry.value;
      final title = work['title']?.toString() ?? '';
      final titles = parseTitlesJson(work['titles']);
      final aliases = (work['aliases'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[];
      final signals = resolveQualitySignals(work, franchiseMember: false);
      final score = computeQualityScore(work, signals);
      final tier = qualityTierFromScore(score);
      buildWorkSearchTokens(
        legacyTitle: title,
        titles: titles,
        aliases: aliases,
        creator: work['creator']?.toString() ?? '',
        tags: (work['tags'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );
      searchBuilt++;
      // score·tier는 search_index 파생값 — 시뮬레이션에서 계산만 확인
      if (score < 0 || tier < 0) {
        throw StateError('invalid derived quality');
      }
    }

    sw.stop();
    return RegistryBuildSimulation(
      existingEntryCount: registry.works.length,
      projectedEntryCount: allWorks.length,
      durationMs: sw.elapsedMilliseconds,
      searchIndexEntriesBuilt: searchBuilt,
    );
  }

  static String _scoreBucket(int score) {
    if (score < 20) return '0-19';
    if (score < 40) return '20-39';
    if (score < 60) return '40-59';
    if (score < 80) return '60-79';
    return '80-100';
  }

  static Set<String> _normalizedTitlesFromDraft(Map<String, dynamic> draft) {
    final norms = <String>{};
    void add(String? t) {
      if (t == null || t.isEmpty) return;
      final n = normalizeTitle(t);
      if (n.isNotEmpty) norms.add(n);
    }

    add(draft['title']?.toString());
    final titles = draft['titles'];
    if (titles is Map) {
      titles.forEach((_, v) => add(v?.toString()));
    }
    final aliases = draft['aliases'];
    if (aliases is List) {
      for (final a in aliases) {
        add(a?.toString());
      }
    }
    return norms;
  }
}

class _PendingCreate {
  final String shadowWorkId;
  final String category;
  final int? releaseYear;
  final Set<String> normalizedTitles;
  final Map<String, dynamic> draft;

  _PendingCreate({
    required this.shadowWorkId,
    required this.category,
    required this.releaseYear,
    required this.normalizedTitles,
    required this.draft,
  });

  factory _PendingCreate.fromDraft(Map<String, dynamic> draft, String wk) {
    return _PendingCreate(
      shadowWorkId: wk,
      category: draft['category']?.toString() ?? '',
      releaseYear: draft['releaseYear'] is int
          ? draft['releaseYear'] as int
          : int.tryParse(draft['releaseYear']?.toString() ?? ''),
      normalizedTitles: ShadowWriteRunner._normalizedTitlesFromDraft(draft),
      draft: draft,
    );
  }
}

/// Contract Test 노드 → Shadow Draft 입력 목록
List<ShadowDraftInput> shadowInputsFromNodes(
  ContractTestRunner contractRunner,
  List<Map<String, dynamic>> nodes,
) {
  return nodes.map((node) {
    final record = contractRunner.classifyNode(node);
    return ShadowDraftInput(
      draft: record.draft ?? const {},
      contractOutcome: record.outcome,
      externalId: record.externalId,
      title: record.title,
    );
  }).toList();
}
