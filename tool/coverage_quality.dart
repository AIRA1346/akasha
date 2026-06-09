/// Coverage Quality — titles.en 검증 규칙 (Quality Gate MVP).
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
final _dateOnly = RegExp(
  r'^\d{4}([-/\.]\d{1,2}([-/\.]\d{1,2})?)+$',
);
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
    return EnTitleValidation(valid: false, reason: InvalidEnReason.empty, value: raw);
  }
  if (t.length < 2) {
    return EnTitleValidation(valid: false, reason: InvalidEnReason.tooShort, value: t);
  }
  if (_controlChars.hasMatch(t)) {
    return EnTitleValidation(valid: false, reason: InvalidEnReason.malformed, value: t);
  }
  if (t.contains('#=') || t.contains('{{') || t.contains('dataItem')) {
    return EnTitleValidation(valid: false, reason: InvalidEnReason.placeholder, value: t);
  }
  if (_literalPlaceholder.hasMatch(t)) {
    return EnTitleValidation(valid: false, reason: InvalidEnReason.placeholder, value: t);
  }
  if (_hangul.hasMatch(t)) {
    return EnTitleValidation(valid: false, reason: InvalidEnReason.hangulInEn, value: t);
  }
  if (_dateOnly.hasMatch(t)) {
    return EnTitleValidation(valid: false, reason: InvalidEnReason.dateLike, value: t);
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
  final manifest = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'manifest.json')).readAsStringSync(),
  ) as Map<String, dynamic>;

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
        if (method != null) 'method': method,
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
  final external = work['externalIds'];
  if (external is Map) {
    if (external.containsKey('tmdb') || external.containsKey('steam')) return true;
  }
  final poster = work['posterPath']?.toString() ?? '';
  if (poster.contains('steam/apps/') || poster.contains('image.tmdb.org')) {
    return true;
  }
  return false;
}
