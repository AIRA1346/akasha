// Registry Coverage·검색 토큰 집합 (Impact Test용).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../dedupe_utils.dart';
import '../registry_v3_utils.dart';
import 'registry_snapshot.dart';

class RegistryCoverageSnapshot {
  final int totalEntries;
  final int animationEntries;
  final Set<String> searchTokens;
  final Set<String> normalizedTitles;

  const RegistryCoverageSnapshot({
    required this.totalEntries,
    required this.animationEntries,
    required this.searchTokens,
    required this.normalizedTitles,
  });
}

RegistryCoverageSnapshot loadRegistryCoverage(Directory projectRoot) {
  final registry = RegistrySnapshot.load(projectRoot);
  final tokens = <String>{};
  final norms = <String>{};

  for (final w in registry.works) {
    norms.addAll(w.normalizedTitles);
    final work = w.work;
    final built = buildWorkSearchTokens(
      legacyTitle: w.title,
      titles: parseTitlesJson(work['titles']),
      aliases: (work['aliases'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      creator: work['creator']?.toString() ?? '',
      tags: (work['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
    tokens.addAll(built);
    tokens.addAll(built.map(normalizeRegistryQuery));
  }

  final searchIndexPath =
      File(p.join(projectRoot.path, 'akasha-db', 'search_index.json'));
  if (searchIndexPath.existsSync()) {
    final raw = json.decode(searchIndexPath.readAsStringSync());
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map) continue;
        final st = entry['searchTokens'];
        if (st is List) {
          for (final t in st) {
            final s = t?.toString().trim() ?? '';
            if (s.isNotEmpty) tokens.add(s);
          }
        }
        final title = entry['title']?.toString() ?? '';
        final n = normalizeTitle(title);
        if (n.isNotEmpty) norms.add(n);
      }
    }
  }

  final animationCount =
      registry.works.where((w) => w.category == 'animation').length;

  return RegistryCoverageSnapshot(
    totalEntries: registry.works.length,
    animationEntries: animationCount,
    searchTokens: tokens,
    normalizedTitles: norms,
  );
}

/// 신규 draft가 채우는 검색 Gap 수
GapFillAnalysis analyzeGapFill({
  required Map<String, dynamic> draft,
  required RegistryCoverageSnapshot before,
}) {
  final title = draft['title']?.toString() ?? '';
  final titles = parseTitlesJson(draft['titles']);
  final aliases = (draft['aliases'] as List?)
          ?.map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      const <String>[];
  final tokens = buildWorkSearchTokens(
    legacyTitle: title,
    titles: titles,
    aliases: aliases,
    creator: draft['creator']?.toString() ?? '',
  );

  final novelTokens = <String>[];
  for (final t in tokens) {
    final norm = normalizeRegistryQuery(t);
    if (!before.searchTokens.contains(t) && !before.searchTokens.contains(norm)) {
      novelTokens.add(t);
    }
  }

  final titleNorms = <String>{};
  void addNorm(String? raw) {
    final n = normalizeTitle(raw ?? '');
    if (n.isNotEmpty) titleNorms.add(n);
  }

  addNorm(title);
  titles.forEach((_, v) => addNorm(v));
  for (final a in aliases) {
    addNorm(a);
  }

  final fillsTitleGap = titleNorms.any((n) => !before.normalizedTitles.contains(n));

  return GapFillAnalysis(
    fillsTitleGap: fillsTitleGap,
    novelSearchTokens: novelTokens,
    totalNewTokens: novelTokens.length,
  );
}

class GapFillAnalysis {
  final bool fillsTitleGap;
  final List<String> novelSearchTokens;
  final int totalNewTokens;

  const GapFillAnalysis({
    required this.fillsTitleGap,
    required this.novelSearchTokens,
    required this.totalNewTokens,
  });
}
