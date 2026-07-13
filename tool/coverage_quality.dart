// Coverage Quality — titles.en 검증 규칙 (Quality Gate MVP).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// `titles.en` 검증 실패 사유.
enum InvalidEnReason {
  empty,
  tooShort,
  placeholder,
  hangulInEn,
  dateLike,
  malformed,
}

/// `titles.en` 검증 결과.
class EnTitleValidation {
  const EnTitleValidation({required this.valid, this.reason, this.value});

  final bool valid;
  final InvalidEnReason? reason;
  final String? value;

  static const ok = EnTitleValidation(valid: true);
}

final _hangul = RegExp(r'[\u3131-\uD79D]');

/// 연도만(`1984`)은 허용 — 구분자 포함 날짜형만 거부.
final _dateOnly = RegExp(r'^\d{4}([-/\.]\d{1,2}([-/\.]\d{1,2})?)+$');
final _controlChars = RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]');
final _literalPlaceholder = RegExp(
  r'^(TODO|TBD|null|undefined|N/?A)$',
  caseSensitive: false,
);

/// Sprint 03 `_isValidEnTitle` + MVP 확장 (date·literal placeholder·control chars).
EnTitleValidation validateEnTitle(String? raw) {
  if (raw == null) {
    return const EnTitleValidation(valid: false, reason: InvalidEnReason.empty);
  }
  final t = raw.trim();
  if (t.isEmpty) {
    return EnTitleValidation(
      valid: false,
      reason: InvalidEnReason.empty,
      value: raw,
    );
  }
  if (t.length < 2) {
    return EnTitleValidation(
      valid: false,
      reason: InvalidEnReason.tooShort,
      value: t,
    );
  }
  if (_controlChars.hasMatch(t)) {
    return EnTitleValidation(
      valid: false,
      reason: InvalidEnReason.malformed,
      value: t,
    );
  }
  if (t.contains('#=') || t.contains('{{') || t.contains('dataItem')) {
    return EnTitleValidation(
      valid: false,
      reason: InvalidEnReason.placeholder,
      value: t,
    );
  }
  if (_literalPlaceholder.hasMatch(t)) {
    return EnTitleValidation(
      valid: false,
      reason: InvalidEnReason.placeholder,
      value: t,
    );
  }
  if (_hangul.hasMatch(t)) {
    return EnTitleValidation(
      valid: false,
      reason: InvalidEnReason.hangulInEn,
      value: t,
    );
  }
  if (_dateOnly.hasMatch(t)) {
    return EnTitleValidation(
      valid: false,
      reason: InvalidEnReason.dateLike,
      value: t,
    );
  }
  return EnTitleValidation(valid: true, value: t);
}

bool isValidEnTitle(String? raw) => validateEnTitle(raw).valid;

String invalidEnReasonLabel(InvalidEnReason reason) => switch (reason) {
  InvalidEnReason.empty => 'empty',
  InvalidEnReason.tooShort => 'too_short',
  InvalidEnReason.placeholder => 'placeholder',
  InvalidEnReason.hangulInEn => 'hangul_in_en',
  InvalidEnReason.dateLike => 'date_like',
  InvalidEnReason.malformed => 'malformed',
};

/// Registry-wide titles.en quality scan.
class QualityScanResult {
  QualityScanResult({
    required this.titlesEnPopulated,
    required this.invalidEnCount,
    required this.invalidEnRate,
    required this.sourceBreakageCount,
    required this.byReason,
    required this.samples,
    required this.status,
  });

  final int titlesEnPopulated;
  final int invalidEnCount;
  final double invalidEnRate;
  final int sourceBreakageCount;
  final Map<String, int> byReason;
  final List<Map<String, dynamic>> samples;
  final String status;
}

const _maxSamples = 20;

/// akasha-db manifest shards → work maps.
List<Map<String, dynamic>> loadRegistryWorkMaps(Directory root) {
  final manifest =
      jsonDecode(
            File(
              p.join(root.path, 'akasha-db', 'manifest.json'),
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  final out = <Map<String, dynamic>>[];
  for (final shardMeta in manifest['shards'] as List) {
    final path = p.join(
      root.path,
      'akasha-db',
      (shardMeta as Map)['path'] as String,
    );
    final shard = jsonDecode(File(path).readAsStringSync()) as Map;
    for (final entry in shard.entries) {
      if (entry.value is! Map) continue;
      out.add(Map<String, dynamic>.from(entry.value as Map));
    }
  }
  return out;
}

QualityScanResult scanTitlesEnQuality(List<Map<String, dynamic>> works) {
  var populated = 0;
  var invalid = 0;
  var sourceBreakage = 0;
  final byReason = <String, int>{};
  final samples = <Map<String, dynamic>>[];

  for (final work in works) {
    final titles = work['titles'];
    if (titles is! Map) continue;
    final en = titles['en']?.toString();
    if (en == null || en.trim().isEmpty) continue;
    populated++;

    final v = validateEnTitle(en);
    if (v.valid) continue;

    invalid++;
    final label = invalidEnReasonLabel(v.reason!);
    byReason[label] = (byReason[label] ?? 0) + 1;

    if (hasAutoSourceTrace(work)) sourceBreakage++;

    if (samples.length < _maxSamples) {
      final ext = work['extensions'];
      final method = ext is Map ? ext['coverageSprint03']?.toString() : null;
      samples.add({
        'workId': work['workId']?.toString() ?? '',
        'titlesEn': en,
        'reason': label,
        'method': ?method,
      });
    }
  }

  final rate = populated == 0 ? 0.0 : invalid / populated;
  return QualityScanResult(
    titlesEnPopulated: populated,
    invalidEnCount: invalid,
    invalidEnRate: rate,
    sourceBreakageCount: sourceBreakage,
    byReason: byReason,
    samples: samples,
    status: invalid == 0 ? 'PASS' : 'FAIL',
  );
}

/// auto-source 흔적 — source_breakage_count 근사.
bool hasAutoSourceTrace(Map<String, dynamic> work) {
  final ext = work['extensions'];
  if (ext is Map) {
    final method = ext['coverageSprint03']?.toString() ?? '';
    if (method == 'tmdb_fetch' || method == 'steam_fetch') return true;
  }
  return false;
}

bool _nonEmptyStr(String? s) => s != null && s.trim().isNotEmpty;

/// E3-B — `titles.ko` 또는 primary `title` 보유 (표시 fallback).
bool hasKoDisplayTitle(Map<String, dynamic> work) {
  final titles = work['titles'];
  if (titles is Map && _nonEmptyStr(titles['ko']?.toString())) return true;
  return _nonEmptyStr(work['title']?.toString());
}

bool hasPopulatedEnTitle(Map<String, dynamic> work) {
  final titles = work['titles'];
  if (titles is! Map) return false;
  return isValidEnTitle(titles['en']?.toString());
}

/// 글로벌 v1.1 locale minimum — coverage 수치 (품질과 분리).
class LocaleCoverageScanResult {
  LocaleCoverageScanResult({
    required this.workCount,
    required this.titlesKoCount,
    required this.titlesKoRate,
    required this.titlesEnPopulated,
    required this.titlesEnMissing,
    required this.titlesEnRate,
    required this.koStatus,
    required this.enCoverageStatus,
  });

  final int workCount;
  final int titlesKoCount;
  final double titlesKoRate;
  final int titlesEnPopulated;
  final int titlesEnMissing;
  final double titlesEnRate;
  final String koStatus;
  final String enCoverageStatus;

  static const double koMinimumRate = 0.99;
  static const double enMinimumRate = 1.0;

  bool get passesMinimum =>
      titlesKoRate >= koMinimumRate && titlesEnRate >= enMinimumRate;
}

LocaleCoverageScanResult scanLocaleCoverage(List<Map<String, dynamic>> works) {
  final total = works.length;
  var ko = 0;
  var enPopulated = 0;
  for (final work in works) {
    if (hasKoDisplayTitle(work)) ko++;
    if (hasPopulatedEnTitle(work)) enPopulated++;
  }
  final koRate = total == 0 ? 0.0 : ko / total;
  final enRate = total == 0 ? 0.0 : enPopulated / total;
  return LocaleCoverageScanResult(
    workCount: total,
    titlesKoCount: ko,
    titlesKoRate: koRate,
    titlesEnPopulated: enPopulated,
    titlesEnMissing: total - enPopulated,
    titlesEnRate: enRate,
    koStatus: koRate >= LocaleCoverageScanResult.koMinimumRate
        ? 'PASS'
        : 'FAIL',
    enCoverageStatus: enRate >= LocaleCoverageScanResult.enMinimumRate
        ? 'PASS'
        : 'FAIL',
  );
}
