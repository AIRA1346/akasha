// ignore_for_file: avoid_print
/// Search Index Validation — synthetic scale 실측 (리팩터링 아님).
///
/// Usage:
///   dart run tool/search_index_validation.dart
///   dart run tool/search_index_validation.dart --scales 10000,100000
///   dart run tool/search_index_validation.dart --scales all --skip-1m
///
/// 산출물 (gitignored):
///   akasha-db/pipeline/artifacts/search_index_validation/
///     search_index_{scale}.json
///     search_index_validation_report.md

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'registry_hash_utils.dart';
import 'registry_v3_utils.dart';

const _defaultScales = [402, 10000, 100000, 300000, 1000000];
const _githubHardLimitBytes = 100 * 1024 * 1024;
const _githubWarnBytes = 50 * 1024 * 1024;

const _categories = [
  'animation',
  'manga',
  'webtoon',
  'game',
  'book',
  'movie',
  'drama',
];

void main(List<String> args) async {
  final root = _findProjectRoot();
  final outDir = Directory(
    p.join(
      root.path,
      'akasha-db',
      'pipeline',
      'artifacts',
      'search_index_validation',
    ),
  );
  outDir.createSync(recursive: true);

  final scales = _parseScales(args);
  final searchIterations = int.tryParse(_argValue(args, '--search-iterations') ?? '') ?? 200;
  final realBaseline = File(p.join(root.path, 'akasha-db', 'search_index.json'));

  print('search_index_validation — Architecture Validation');
  print('  scales: ${scales.join(', ')}');
  print('  output: ${outDir.path}');
  print('');

  final results = <ValidationResult>[];

  if (realBaseline.existsSync() && scales.contains(402)) {
    print('Baseline: real search_index.json (402)');
    results.add(
      await _benchmarkFile(
        label: '402_real',
        workCount: 402,
        file: realBaseline,
        searchIterations: searchIterations,
        synthetic: false,
      ),
    );
  }

  for (final scale in scales) {
    if (scale == 402) continue;
    print('Synthetic: $scale works');
    final file = File(p.join(outDir.path, 'search_index_$scale.json'));
    final bytesPerWork = await _writeSyntheticIndex(scale, file);
    results.add(
      await _benchmarkFile(
        label: '${scale}_synthetic',
        workCount: scale,
        file: file,
        searchIterations: searchIterations,
        synthetic: true,
        bytesPerWork: bytesPerWork,
      ),
    );
  }

  final report = _formatReport(results);
  final reportFile = File(
    p.join(outDir.path, 'search_index_validation_report.md'),
  );
  await reportFile.writeAsString(report);

  print('');
  print('Wrote: ${reportFile.path}');
  print(report);

  final failed = results.where((r) => r.githubHardLimit).length;
  if (failed > 0) {
    stderr.writeln('\nNOTE: $failed scale(s) exceed GitHub 100MB single-file limit');
    exit(1);
  }
}

class ValidationResult {
  final String label;
  final int workCount;
  final bool synthetic;
  final int fileBytes;
  final double bytesPerWork;
  final int parseMs;
  final int rssBeforeBytes;
  final int rssAfterParseBytes;
  final int rssDeltaBytes;
  final int searchMs;
  final int searchIterations;
  final int hitsPerQuery;
  final bool githubWarn;
  final bool githubHardLimit;

  const ValidationResult({
    required this.label,
    required this.workCount,
    required this.synthetic,
    required this.fileBytes,
    required this.bytesPerWork,
    required this.parseMs,
    required this.rssBeforeBytes,
    required this.rssAfterParseBytes,
    required this.rssDeltaBytes,
    required this.searchMs,
    required this.searchIterations,
    required this.hitsPerQuery,
    required this.githubWarn,
    required this.githubHardLimit,
  });
}

Future<double> _writeSyntheticIndex(int count, File file) async {
  final sink = file.openWrite(encoding: utf8);
  sink.writeln('[');

  for (var i = 1; i <= count; i++) {
    final workId = 'wk_${i.toString().padLeft(9, '0')}';
    final category = _categories[i % _categories.length];
    final hex = shardHexForWorkId(workId);
    final shardId = '${category}_$hex';
    final title = 'Synthetic Registry Work $i';
    final creator = 'Creator Studio ${i % 97}';
    final tags = [
      'tag${i % 11}',
      'genre${i % 17}',
      if (i % 3 == 0) '명작',
      if (i % 5 == 0) 'SF',
    ];
    final aliases = [
      if (i % 4 == 0) 'Alias-$i',
      if (i % 7 == 0) 'シンセティック$i',
    ];
    final titles = {
      'en': title,
      if (i % 2 == 0) 'ja': '合成作品$i',
      if (i % 3 == 0) 'ko': '합성 작품 $i',
    };
    final searchTokens = buildWorkSearchTokens(
      legacyTitle: title,
      titles: titles,
      aliases: aliases,
      creator: creator,
      tags: tags,
    );

    final entry = <String, dynamic>{
      'workId': workId,
      'title': title,
      'shardId': shardId,
      'category': category,
      'domain': i.isEven ? 'subculture' : 'generalCulture',
      'creator': creator,
      'tags': tags,
      'searchTokens': searchTokens,
      'titles': titles,
      if (i % 2 == 0)
        'posterPath':
            'https://image.tmdb.org/t/p/w500/synthetic_${i % 1000}.jpg',
      'qualityScore': 40 + (i % 50),
      'qualityTier': 2 + (i % 3),
    };

    if (i > 1) sink.writeln(',');
    sink.write('  ');
    sink.write(const JsonEncoder.withIndent('  ').convert(entry).replaceAll(
          '\n',
          '\n  ',
        ));
  }

  sink.writeln();
  sink.writeln(']');
  await sink.close();
  final bytes = await file.length();
  return count == 0 ? 0 : bytes / count;
}

Future<ValidationResult> _benchmarkFile({
  required String label,
  required int workCount,
  required File file,
  required int searchIterations,
  required bool synthetic,
  double? bytesPerWork,
}) async {
  final fileBytes = await file.length();
  final rssBefore = ProcessInfo.currentRss;

  final swParse = Stopwatch()..start();
  final raw = await file.readAsString();
  final decoded = json.decode(raw);
  swParse.stop();

  final entries = <Map<String, dynamic>>[];
  if (decoded is List) {
    for (final item in decoded) {
      if (item is Map) {
        entries.add(Map<String, dynamic>.from(item));
      }
    }
  }

  final rssAfterParse = ProcessInfo.currentRss;

  final queries = <String>[
    'monster',
    'synthetic',
    '合成',
    'creator studio 42',
    'tag7',
    'wk_000001234',
    'animation',
    '명작',
  ];

  final swSearch = Stopwatch()..start();
  var totalHits = 0;
  for (var i = 0; i < searchIterations; i++) {
    final q = queries[i % queries.length];
    totalHits += _countQueryHits(entries, q);
  }
  swSearch.stop();

  final perWork = bytesPerWork ?? (workCount == 0 ? 0 : fileBytes / workCount);

  return ValidationResult(
    label: label,
    workCount: workCount,
    synthetic: synthetic,
    fileBytes: fileBytes,
    bytesPerWork: perWork,
    parseMs: swParse.elapsedMilliseconds,
    rssBeforeBytes: rssBefore,
    rssAfterParseBytes: rssAfterParse,
    rssDeltaBytes: rssAfterParse - rssBefore,
    searchMs: swSearch.elapsedMilliseconds,
    searchIterations: searchIterations,
    hitsPerQuery: searchIterations == 0 ? 0 : totalHits ~/ searchIterations,
    githubWarn: fileBytes >= _githubWarnBytes,
    githubHardLimit: fileBytes >= _githubHardLimitBytes,
  );
}

int _countQueryHits(List<Map<String, dynamic>> entries, String query) {
  final q = normalizeRegistryQuery(query);
  if (q.isEmpty) return 0;

  var hits = 0;
  for (final entry in entries) {
    final tokens = (entry['searchTokens'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    var matched = false;
    for (final token in tokens) {
      if (token.contains(q)) {
        matched = true;
        break;
      }
    }
    if (!matched) {
      final title =
          entry['title']?.toString().toLowerCase().replaceAll(' ', '') ?? '';
      final creator =
          entry['creator']?.toString().toLowerCase().replaceAll(' ', '') ?? '';
      if (title.contains(q) || creator.contains(q)) matched = true;
    }
    if (matched) hits++;
  }
  return hits;
}

String _formatReport(List<ValidationResult> results) {
  final buf = StringBuffer();
  buf.writeln('# Search Index Validation Report');
  buf.writeln();
  buf.writeln('> Architecture Validation — 리팩터링 아님');
  buf.writeln('> synthetic `search_index.json` 규모별 실측');
  buf.writeln();
  buf.writeln('## 측정 항목');
  buf.writeln();
  buf.writeln('| 항목 | 설명 |');
  buf.writeln('|------|------|');
  buf.writeln('| fileBytes | 디스크 파일 크기 |');
  buf.writeln('| parseMs | `readAsString` + `json.decode` |');
  buf.writeln('| rssDelta | parse 전후 RSS 증가 (Dart VM, native) |');
  buf.writeln('| searchMs | 선형 scan × N회 (앱 `shardIdsForQuery` 동형) |');
  buf.writeln('| githubHardLimit | 단일 파일 100MB 초과 |');
  buf.writeln();
  buf.writeln('## 결과');
  buf.writeln();
  buf.writeln(
    '| scale | file | bytes/work | parse | RSS Δ | search (${
      results.isEmpty ? '?' : results.first.searchIterations
    }×) | ms/query | Git 100MB |',
  );
  buf.writeln('|-------|------|------------|-------|-------|--------|----------|-----------|');

  for (final r in results) {
    final msPerQuery =
        r.searchIterations == 0 ? 0 : r.searchMs / r.searchIterations;
    buf.writeln(
      '| ${r.label} | ${_fmtBytes(r.fileBytes)} | '
      '${r.bytesPerWork.toStringAsFixed(1)} | ${r.parseMs}ms | '
      '${_fmtBytes(r.rssDeltaBytes)} | ${r.searchMs}ms | '
      '${msPerQuery.toStringAsFixed(2)}ms | '
      '${r.githubHardLimit ? '**FAIL**' : (r.githubWarn ? 'WARN' : 'OK')} |',
    );
  }

  buf.writeln();
  buf.writeln('## 임계 판정');
  buf.writeln();

  final firstHard = results.where((r) => r.githubHardLimit).map((r) => r.label);
  if (firstHard.isNotEmpty) {
    buf.writeln(
      '- GitHub 100MB 단일 파일: **${firstHard.first}** 에서 초과',
    );
  } else {
    buf.writeln('- GitHub 100MB 단일 파일: 이번 측정 범위 내 미초과');
  }

  final slowParse = results.where((r) => r.parseMs > 3000).toList();
  if (slowParse.isNotEmpty) {
    buf.writeln(
      '- parse > 3s: ${slowParse.map((r) => r.label).join(', ')}',
    );
  }

  final highRss = results.where((r) => r.rssDeltaBytes > 200 * 1024 * 1024).toList();
  if (highRss.isNotEmpty) {
    buf.writeln(
      '- RSS Δ > 200MB: ${highRss.map((r) => r.label).join(', ')}',
    );
  }

  buf.writeln();
  buf.writeln('## 해석');
  buf.writeln();
  buf.writeln(
    '- 이 보고서는 **search_index가 첫 병목인지 최종 확정**하기 위한 실측이다.',
  );
  buf.writeln(
    '- 구조 변경(샤드화 / inverted index / SQLite FTS)은 이 결과 합의 후에만 논의한다.',
  );
  buf.writeln();
  buf.writeln('## 재현');
  buf.writeln();
  buf.writeln('```bash');
  buf.writeln('dart run tool/search_index_validation.dart');
  buf.writeln('```');
  buf.writeln();

  return buf.toString();
}

String _fmtBytes(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)}KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
}

List<int> _parseScales(List<String> args) {
  if (args.contains('--skip-1m')) {
    return _defaultScales.where((s) => s != 1000000).toList();
  }
  final raw = _argValue(args, '--scales');
  if (raw == null || raw == 'all') return List<int>.from(_defaultScales);
  return raw
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .where((n) => n > 0)
      .toList();
}

String? _argValue(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx >= 0 && idx + 1 < args.length) return args[idx + 1];
  return null;
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
