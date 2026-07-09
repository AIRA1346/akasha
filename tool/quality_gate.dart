// ignore_for_file: avoid_print
// Quality Gate MVP — titles.en `_isValidEnTitle` 기반 CI / release check.
//
// Usage:
//   dart run tool/quality_gate.dart              # report, exit 0
//   dart run tool/quality_gate.dart --warn       # warnings, exit 0
//   dart run tool/quality_gate.dart --strict     # invalid > 0 → exit 1
//   dart run tool/quality_gate.dart --release    # release block rules
//   dart run tool/quality_gate.dart --locale-minimum  # E3 ko+en coverage floor
//   dart run tool/quality_gate.dart --override   # bypass block (logged)

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'coverage_quality.dart';

void main(List<String> args) {
  final strict = args.contains('--strict');
  final release = args.contains('--release');
  final warn = args.contains('--warn');
  final localeMinimum = args.contains('--locale-minimum');
  final override = args.contains('--override');

  final root = _findProjectRoot();
  final works = loadRegistryWorkMaps(root);
  final overrideActive = override || _overrideFileActive(root);

  final scan = scanTitlesEnQuality(works);
  final localeScan = scanLocaleCoverage(works);
  _printReport(scan, localeScan, overrideActive: overrideActive);

  final block = scan.invalidEnCount > 0 || scan.sourceBreakageCount > 0;
  if (block && overrideActive) {
    print('\nOVERRIDE: quality block bypassed (maintainer)');
  }

  if (strict || release) {
    if (block && !overrideActive) {
      stderr.writeln(
        '\nQUALITY GATE FAIL: invalid_en=${scan.invalidEnCount} '
        'source_breakage=${scan.sourceBreakageCount}',
      );
      exit(1);
    }
  } else if (warn && block) {
    stderr.writeln(
      '\nQUALITY GATE WARN: invalid_en=${scan.invalidEnCount} '
      'source_breakage=${scan.sourceBreakageCount}',
    );
  }

  if (localeMinimum) {
    if (!localeScan.passesMinimum) {
      stderr.writeln(
        '\nLOCALE MINIMUM FAIL: titles_ko=${localeScan.titlesKoCount}/'
        '${localeScan.workCount} (${(localeScan.titlesKoRate * 100).toStringAsFixed(2)}%) '
        'titles_en_missing=${localeScan.titlesEnMissing}',
      );
      exit(1);
    }
  } else if (warn && !localeScan.passesMinimum) {
    stderr.writeln(
      '\nLOCALE MINIMUM WARN: titles_ko rate '
      '${(localeScan.titlesKoRate * 100).toStringAsFixed(2)}% · '
      'titles_en_missing=${localeScan.titlesEnMissing}',
    );
  }
}

void _printReport(
  QualityScanResult scan,
  LocaleCoverageScanResult localeScan, {
  required bool overrideActive,
}) {
  print('Quality Gate MVP — titles.en');
  print('  titles_en_populated: ${scan.titlesEnPopulated}');
  print('  invalid_en_count: ${scan.invalidEnCount}');
  print('  invalid_en_rate: ${scan.invalidEnRate.toStringAsFixed(4)}');
  print('  source_breakage_count: ${scan.sourceBreakageCount}');
  print('  status: ${scan.status}');
  print('Locale minimum (E3-B — coverage, not syntax):');
  print(
    '  titles_ko: ${localeScan.titlesKoCount}/${localeScan.workCount} '
    '(${(localeScan.titlesKoRate * 100).toStringAsFixed(2)}%) '
    'target>=${(LocaleCoverageScanResult.koMinimumRate * 100).toStringAsFixed(0)}% '
    'status=${localeScan.koStatus}',
  );
  print(
    '  titles_en_coverage: ${localeScan.titlesEnPopulated}/'
    '${localeScan.workCount} missing=${localeScan.titlesEnMissing} '
    'target=100% status=${localeScan.enCoverageStatus}',
  );
  if (overrideActive) print('  override: true');
  if (scan.byReason.isNotEmpty) {
    print('  by_reason: ${scan.byReason}');
  }
  if (scan.samples.isNotEmpty) {
    print('  samples:');
    for (final s in scan.samples) {
      print('    ${s['workId']}: ${s['titlesEn']} (${s['reason']})');
    }
  }
}

bool _overrideFileActive(Directory root) {
  final file = File(
    p.join(root.path, 'akasha-db', 'pipeline', 'quality_gate_override.json'),
  );
  if (!file.existsSync()) return false;
  try {
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final expires = raw['expiresAt']?.toString();
    if (expires == null || expires.isEmpty) return true;
    final exp = DateTime.tryParse(expires);
    if (exp == null) return true;
    return DateTime.now().toUtc().isBefore(exp);
  } catch (_) {
    return false;
  }
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
