/// Registry Snapshot Compare — 402 vs 412 가상 적용 diff.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../registry_v3_utils.dart';
import 'registry_impact_selector.dart';
import 'registry_snapshot.dart';
import 'registry_virtual_state.dart';

class CoverageMetrics {
  final int total;
  final int withCreator;
  final int withAliases;
  final int withReleaseYear;

  const CoverageMetrics({
    required this.total,
    required this.withCreator,
    required this.withAliases,
    required this.withReleaseYear,
  });

  double rate(int count) => total == 0 ? 0 : count / total;

  Map<String, dynamic> toJson() => {
        'total': total,
        'withCreator': withCreator,
        'withAliases': withAliases,
        'withReleaseYear': withReleaseYear,
        'creatorRate': rate(withCreator),
        'aliasRate': rate(withAliases),
        'releaseYearRate': rate(withReleaseYear),
      };
}

CoverageMetrics coverageMetricsForAnimation(RegistryVirtualState state) {
  final animation = state.entries.where((e) => e.category == 'animation');
  var creator = 0;
  var aliases = 0;
  var year = 0;
  final list = animation.toList();
  for (final e in list) {
    if (e.creator.isNotEmpty) creator++;
    if (e.aliases.isNotEmpty) aliases++;
    if (e.releaseYear != null && e.releaseYear! > 0) year++;
  }
  return CoverageMetrics(
    total: list.length,
    withCreator: creator,
    withAliases: aliases,
    withReleaseYear: year,
  );
}

class SearchQueryResult {
  final String query;
  final int hitCount;
  final List<String> topWorkIds;

  const SearchQueryResult({
    required this.query,
    required this.hitCount,
    required this.topWorkIds,
  });
}

List<VirtualWorkEntry> searchRegistry(
  String query,
  RegistryVirtualState state, {
  int limit = 10,
}) {
  final q = normalizeRegistryQuery(query);
  if (q.length < 2) return const [];

  final scored = <MapEntry<VirtualWorkEntry, int>>[];
  for (final e in state.entries) {
    var best = 0;
    for (final token in e.searchTokens) {
      final t = normalizeRegistryQuery(token);
      if (t.isEmpty) continue;
      if (t == q) {
        best = best < 100 ? 100 : best;
      } else if (t.contains(q) || q.contains(t)) {
        best = best < 50 ? 50 : best;
      }
    }
    if (best > 0) {
      scored.add(MapEntry(e, best + e.qualityScore));
    }
  }

  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.take(limit).map((e) => e.key).toList();
}

SearchQueryResult probeSearch(String query, RegistryVirtualState state) {
  final hits = searchRegistry(query, state);
  return SearchQueryResult(
    query: query,
    hitCount: hits.length,
    topWorkIds: hits.map((e) => e.workId).toList(),
  );
}

class SearchWin {
  final String query;
  final int hitsBefore;
  final int hitsAfter;
  final String? newTopTitle;
  final String? newTopWorkId;
  final int? rankAfter;

  const SearchWin({
    required this.query,
    required this.hitsBefore,
    required this.hitsAfter,
    this.newTopTitle,
    this.newTopWorkId,
    this.rankAfter,
  });

  bool get wasZeroBefore => hitsBefore == 0;
  bool get improves => hitsAfter > hitsBefore;

  Map<String, dynamic> toJson() => {
        'query': query,
        'hitsBefore': hitsBefore,
        'hitsAfter': hitsAfter,
        'newTopTitle': newTopTitle,
        'newTopWorkId': newTopWorkId,
        'rankAfter': rankAfter,
      };
}

class FranchiseDiffEntry {
  final String franchiseLabel;
  final String addedTitle;
  final String addedWorkId;

  const FranchiseDiffEntry({
    required this.franchiseLabel,
    required this.addedTitle,
    required this.addedWorkId,
  });
}

class RegistryDiffResult {
  final int entriesBefore;
  final int entriesAfter;
  final List<SearchWin> searchWins;
  final int zeroToHitCount;
  final CoverageMetrics coverageBefore;
  final CoverageMetrics coverageAfter;
  final List<FranchiseDiffEntry> franchiseGains;
  final List<String> userVisibleWins;
  final bool diffStrong;
  final bool recommend5bPatch;

  const RegistryDiffResult({
    required this.entriesBefore,
    required this.entriesAfter,
    required this.searchWins,
    required this.zeroToHitCount,
    required this.coverageBefore,
    required this.coverageAfter,
    required this.franchiseGains,
    required this.userVisibleWins,
    required this.diffStrong,
    required this.recommend5bPatch,
  });

  Map<String, dynamic> toJson() => {
        'entriesBefore': entriesBefore,
        'entriesAfter': entriesAfter,
        'zeroToHitCount': zeroToHitCount,
        'searchWins': searchWins.map((s) => s.toJson()).toList(),
        'coverageBefore': coverageBefore.toJson(),
        'coverageAfter': coverageAfter.toJson(),
        'franchiseGains': franchiseGains
            .map(
              (f) => {
                'franchise': f.franchiseLabel,
                'title': f.addedTitle,
                'workId': f.addedWorkId,
              },
            )
            .toList(),
        'userVisibleWins': userVisibleWins,
        'diffStrong': diffStrong,
        'recommend5bPatch': recommend5bPatch,
      };
}

RegistryDiffResult compareRegistrySnapshots({
  required RegistryVirtualState before,
  required RegistryVirtualState after,
  required List<ImpactSelectionScore> selected,
}) {
  final probes = <String>{};
  for (final s in selected) {
    final draft = s.item.draft ?? {};
    final title = draft['title']?.toString().trim() ?? '';
    if (title.length >= 2) probes.add(title);
    final titles = parseTitlesJson(draft['titles']);
    for (final v in titles.values) {
      if (v.length >= 2) probes.add(v);
    }
    final aliases = draft['aliases'];
    if (aliases is List && aliases.isNotEmpty) {
      final a = aliases.first?.toString().trim() ?? '';
      if (a.length >= 2) probes.add(a);
    }
  }

  final searchWins = <SearchWin>[];
  var zeroToHit = 0;
  final userWins = <String>[];

  final selectedIds =
      selected.map((s) => s.item.shadowWorkId).whereType<String>().toSet();

  for (final query in probes) {
    final b = probeSearch(query, before);
    final a = probeSearch(query, after);

    String? topTitle;
    String? topId;
    int? rank;
    for (var i = 0; i < a.topWorkIds.length; i++) {
      final id = a.topWorkIds[i];
      if (selectedIds.contains(id)) {
        topId = id;
        topTitle =
            selected.firstWhere((s) => s.item.shadowWorkId == id).item.title;
        rank = i + 1;
        break;
      }
    }

    if (topId == null) continue;

    final win = SearchWin(
      query: query,
      hitsBefore: b.hitCount,
      hitsAfter: a.hitCount,
      newTopTitle: topTitle,
      newTopWorkId: topId,
      rankAfter: rank,
    );
    searchWins.add(win);

    if (win.wasZeroBefore && win.hitsAfter > 0) {
      zeroToHit++;
      userWins.add(
        '「$query」: 이전 0건 → ${a.hitCount}건 발견 '
        '("$topTitle" / $topId, rank $rank)',
      );
    } else if (win.improves) {
      userWins.add(
        '「$query」: ${b.hitCount}건 → ${a.hitCount}건 (신규 작품 검색 포함, rank $rank)',
      );
    }
  }

  final covBefore = coverageMetricsForAnimation(before);
  final covAfter = coverageMetricsForAnimation(after);

  final franchiseGains = <FranchiseDiffEntry>[];
  for (final s in selected) {
    if (!s.franchiseValue || s.franchiseHint == null) continue;
    franchiseGains.add(
      FranchiseDiffEntry(
        franchiseLabel: s.franchiseHint!,
        addedTitle: s.item.title,
        addedWorkId: s.item.shadowWorkId ?? '',
      ),
    );
  }

  final creatorDelta =
      covAfter.rate(covAfter.withCreator) - covBefore.rate(covBefore.withCreator);
  final aliasDelta =
      covAfter.rate(covAfter.withAliases) - covBefore.rate(covBefore.withAliases);
  final yearDelta = covAfter.rate(covAfter.withReleaseYear) -
      covBefore.rate(covBefore.withReleaseYear);

  final minZeroHits = (selected.length / 2).ceil().clamp(1, selected.length);
  final minUserWins = selected.length >= 5 ? 3 : 1;
  final diffStrong = zeroToHit >= minZeroHits &&
      creatorDelta >= 0 &&
      aliasDelta >= 0 &&
      yearDelta >= 0 &&
      userWins.length >= minUserWins;

  final recommend5b = diffStrong && zeroToHit >= 5;

  return RegistryDiffResult(
    entriesBefore: before.entries.length,
    entriesAfter: after.entries.length,
    searchWins: searchWins,
    zeroToHitCount: zeroToHit,
    coverageBefore: covBefore,
    coverageAfter: covAfter,
    franchiseGains: franchiseGains,
    userVisibleWins: userWins,
    diffStrong: diffStrong,
    recommend5bPatch: recommend5b,
  );
}

RegistryVirtualState buildAfterState({
  required Directory projectRoot,
  required List<ImpactSelectionScore> selected,
}) {
  final before = RegistryVirtualState.fromSnapshot(
    RegistrySnapshot.load(projectRoot),
  );
  final drafts = selected
      .map((s) => s.item.draft)
      .whereType<Map<String, dynamic>>()
      .toList();
  return before.withAddedDrafts(drafts);
}
