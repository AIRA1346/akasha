// ignore_for_file: avoid_print
/// akasha-db posterPath URL policy — [docs/akasha-db-policy.md](../docs/akasha-db-policy.md)
///
/// - absoluteDenylist: any occurrence fails CI (e.g. justwatch)
/// - incrementDenylist: count must not exceed baseline (e.g. legacy anilistcdn)
library;

import 'dart:convert';
import 'dart:io';

/// Zero-tolerance domains/patterns (existing catalog included).
const absoluteDenylistPatterns = [
  'justwatch.com',
  'justwatch.io',
];

/// Legacy domains — existing URLs may remain; CI fails only if count increases.
const incrementDenylistPatterns = [
  'anilistcdn',
];

const posterUrlBaselineFile = 'akasha-db/poster_url_baseline.json';

class PosterUrlScanResult {
  final int workCount;
  final Map<String, int> patternCounts;
  final List<String> violations;

  const PosterUrlScanResult({
    required this.workCount,
    required this.patternCounts,
    required this.violations,
  });
}

PosterUrlScanResult scanRegistryPosters(Directory projectRoot) {
  final shardsRoot = Directory('${projectRoot.path}/akasha-db/shards');
  final patternCounts = <String, int>{
    for (final p in [...absoluteDenylistPatterns, ...incrementDenylistPatterns])
      p: 0,
  };
  final violations = <String>[];
  var workCount = 0;

  if (!shardsRoot.existsSync()) {
    return PosterUrlScanResult(
      workCount: 0,
      patternCounts: patternCounts,
      violations: ['akasha-db/shards not found'],
    );
  }

  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is! Map) continue;

    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      workCount++;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key.toString();
      final poster = work['posterPath']?.toString() ?? '';

      if (poster.isEmpty) continue;

      if (!poster.startsWith('http://') && !poster.startsWith('https://')) {
        violations.add(
          '$workId: posterPath must be http(s) URL, got "$poster"',
        );
        continue;
      }

      if (_looksSelfHosted(poster)) {
        violations.add('$workId: self-hosted posterPath prohibited: $poster');
      }

      final lower = poster.toLowerCase();
      for (final pattern in absoluteDenylistPatterns) {
        if (lower.contains(pattern)) {
          patternCounts[pattern] = (patternCounts[pattern] ?? 0) + 1;
          violations.add('$workId: absolute denylist ($pattern): $poster');
        }
      }
      for (final pattern in incrementDenylistPatterns) {
        if (lower.contains(pattern)) {
          patternCounts[pattern] = (patternCounts[pattern] ?? 0) + 1;
        }
      }
    }
  }

  return PosterUrlScanResult(
    workCount: workCount,
    patternCounts: patternCounts,
    violations: violations,
  );
}

bool _looksSelfHosted(String url) {
  final lower = url.toLowerCase();
  return lower.contains('akasha-db/posters/') ||
      lower.contains('raw.githubusercontent.com/') &&
          lower.contains('/posters/');
}

Map<String, int> readPosterBaseline(Directory projectRoot) {
  final file = File('${projectRoot.path}/$posterUrlBaselineFile');
  if (!file.existsSync()) return {};
  try {
    final decoded = json.decode(file.readAsStringSync());
    if (decoded is! Map) return {};
    return decoded.map(
      (key, value) => MapEntry(key.toString(), int.tryParse('$value') ?? 0),
    );
  } catch (_) {
    return {};
  }
}

void writePosterBaseline(Directory projectRoot, Map<String, int> counts) {
  final file = File('${projectRoot.path}/$posterUrlBaselineFile');
  file.parent.createSync(recursive: true);
  final encoder = const JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(counts)}\n');
}

/// Returns non-empty error messages (CI should fail).
List<String> validatePosterScan(
  PosterUrlScanResult scan,
  Map<String, int> baseline,
) {
  final errors = <String>[];

  for (final v in scan.violations) {
    if (v.contains('absolute denylist') ||
        v.contains('self-hosted') ||
        v.contains('must be http')) {
      errors.add(v);
    }
  }

  for (final pattern in incrementDenylistPatterns) {
    final current = scan.patternCounts[pattern] ?? 0;
    final allowed = baseline[pattern];
    if (allowed == null) {
      errors.add(
        'poster baseline missing "$pattern" — run: '
        'dart run tool/ci_registry_check.dart --update-poster-baseline',
      );
      continue;
    }
    if (current > allowed) {
      errors.add(
        'poster denylist "$pattern": count $current > baseline $allowed '
        '(신규 PR에서 금지 CDN 추가됨)',
      );
    }
  }

  return errors;
}

/// Shard validation (registry_builder) — allows legacy increment-denylist URLs.
String? validatePosterUrlForShard(String? posterPath) {
  if (posterPath == null || posterPath.isEmpty) return null;
  if (!posterPath.startsWith('http://') && !posterPath.startsWith('https://')) {
    return 'posterPath must be http(s) URL or null';
  }
  if (_looksSelfHosted(posterPath)) {
    return 'self-hosted posterPath prohibited';
  }
  final lower = posterPath.toLowerCase();
  for (final pattern in absoluteDenylistPatterns) {
    if (lower.contains(pattern)) {
      return 'poster URL matches denylist: $pattern';
    }
  }
  return null;
}

/// Strict check for new PRs / docs — blocks increment denylist too.
String? validateNewPosterUrl(String? posterPath) {
  final base = validatePosterUrlForShard(posterPath);
  if (base != null) return base;
  final lower = posterPath!.toLowerCase();
  for (final pattern in incrementDenylistPatterns) {
    if (lower.contains(pattern)) {
      return 'poster URL matches increment denylist: $pattern (legacy only)';
    }
  }
  return null;
}
