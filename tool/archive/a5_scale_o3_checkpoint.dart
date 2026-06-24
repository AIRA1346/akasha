// ignore_for_file: avoid_print
/// A5 Scale ??O3 G2 throughput checkpoint ?办稖 (SD1).
///
/// Usage:
///   dart run tool/archive/a5_scale_o3_checkpoint.dart [--apply]
///   dart run tool/archive/a5_scale_o3_checkpoint.dart --as-of 2026-07-09 --apply
///
/// ?办稖: akasha-db/pipeline/artifacts/coverage_dashboard/scale_o3_checkpoint.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Scale @410 baseline ?错泟 Maintainer net insert (frozen day-0 session).
const maintainerNetFrom410 = 12;

/// SD1.1 路 SD1.2
final clockStart = DateTime.utc(2026, 6, 9);
final checkpointDate = DateTime.utc(2026, 7, 9);

/// Discovery G2 臧�??(??net insert)
const g2RateLowPerMonth = 3000;
const g2RateHighPerMonth = 5000;

void main(List<String> args) {
  final apply = args.contains('--apply');
  final asOf = _parseAsOf(args) ?? DateTime.now().toUtc();
  final root = _root();

  final manifest = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'manifest.json')).readAsStringSync(),
  ) as Map<String, dynamic>;
  final entryCount = manifest['entryCount'] as int? ?? 0;

  final elapsedDays = _elapsedDays(clockStart, asOf);
  final daysToCheckpoint = _elapsedDays(asOf, checkpointDate).clamp(0, 9999);
  final atCheckpoint = !asOf.isBefore(checkpointDate);

  final monthlyRate = elapsedDays > 0
      ? maintainerNetFrom410 / elapsedDays * 30
      : null;

  String? g2Signal;
  if (monthlyRate != null) {
    if (monthlyRate >= g2RateLowPerMonth) {
      g2Signal = 'consistent';
    } else if (monthlyRate >= g2RateLowPerMonth * 0.1) {
      g2Signal = 'below_hypothesis_measurable';
    } else {
      g2Signal = 'below_hypothesis_critical';
    }
  }

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'observation': 'O3',
    'asOf': _dateLabel(asOf),
    'clockStart': _dateLabel(clockStart),
    'checkpointDate': _dateLabel(checkpointDate),
    'atCheckpoint': atCheckpoint,
    'daysToCheckpoint': daysToCheckpoint,
    'elapsedDays': elapsedDays,
    'baselineWorks': 410,
    'currentWorks': entryCount,
    'maintainerNetFrom410': maintainerNetFrom410,
    'expansionNetFrom410': entryCount - 410 - maintainerNetFrom410,
    'o3Excluded': 'Pilot 402??10 路 Expansion batch5/6/7',
    'monthlyRateMaintainer': monthlyRate,
    'monthlyRateRounded': monthlyRate?.toStringAsFixed(1),
    'g2HypothesisPerMonth': {'low': g2RateLowPerMonth, 'high': g2RateHighPerMonth},
    'g2Signal': g2Signal ?? 'pending_elapsed_days',
    'sd26Hold': true,
    'formula': 'maintainer_net / elapsed_days * 30',
    'note': elapsedDays == 0
        ? 'day-0 ?胳厴 ??rate??elapsed>0 ?愲姅 checkpoint?愳劀 ?办稖'
        : null,
  };

  print('=== O3 checkpoint (@${_dateLabel(asOf)}) ===');
  print('elapsed_days: $elapsedDays');
  print('maintainer net (@410): $maintainerNetFrom410');
  print('current works: $entryCount');
  if (monthlyRate != null) {
    print('monthly rate (Maintainer): ${monthlyRate.toStringAsFixed(1)}/month');
    print('G2 signal: $g2Signal');
  } else {
    print('monthly rate: pending (elapsed_days=0)');
  }
  print('checkpoint: ${_dateLabel(checkpointDate)} (${daysToCheckpoint}d remaining)');

  if (apply) {
    final outDir = Directory(
      p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
    );
    outDir.createSync(recursive: true);
    final out = File(p.join(outDir.path, 'scale_o3_checkpoint.json'));
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('Wrote ${out.path}');
  } else {
    print('Dry-run ??pass --apply to write report');
  }
}

DateTime? _parseAsOf(List<String> args) {
  final i = args.indexOf('--as-of');
  if (i < 0 || i + 1 >= args.length) return null;
  final parts = args[i + 1].split('-');
  if (parts.length != 3) return null;
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

int _elapsedDays(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  final d = b.difference(a).inDays;
  return d < 0 ? 0 : d;
}

String _dateLabel(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Directory _root() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
