// ignore_for_file: avoid_print
// Sprint 04 Phase B ??E1 Steam cohort quality audit (read-only).
//
// Usage: dart run tool/archive/coverage_sprint_04_e1_audit.dart [--write-json]
//
// ?∞Ï∂ú: akasha-db/pipeline/artifacts/coverage_dashboard/sprint_04_e1_audit.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../coverage_quality.dart';

void main(List<String> args) {
  final writeJson = args.contains('--write-json');
  final root = _root();
  final works = loadRegistryWorkMaps(root);
  final byId = {for (final w in works) w['workId']?.toString() ?? '': w};
  final steamIndex = _buildSteamIndex(works);
  final franchiseOf = _loadFranchiseMembership(root);

  final candidates = <Map<String, dynamic>>[];
  for (final work in works) {
    if (_externalIds(work).isNotEmpty) continue;
    final steamId = _resolveSteamAppId(work);
    if (steamId == null) continue;
    if ((work['category']?.toString() ?? '') != 'game') continue;

    final posterId = _steamAppIdFromPoster(work['posterPath']?.toString() ?? '');
    final legacyId = _steamAppIdFromLegacy(work['legacyIds']);
    final acquisition = _acquisitionMethod(posterId, legacyId, steamId);

    final risks = _assessRisks(
      work: work,
      steamId: steamId,
      posterId: posterId,
      legacyId: legacyId,
      steamIndex: steamIndex,
      franchiseOf: franchiseOf,
      byId: byId,
    );
    final severity = _overallSeverity(risks);

    candidates.add({
      'workId': work['workId']?.toString() ?? '',
      'title': work['title']?.toString() ?? '',
      'titlesEn': (work['titles'] as Map?)?['en']?.toString(),
      'currentExternalIds': _externalIds(work),
      'proposedSteamAppId': steamId,
      'acquisition': acquisition,
      'posterAppId': posterId,
      'legacyAppId': legacyId,
      'risks': risks,
      'severity': severity,
    });
  }

  candidates.sort(
    (a, b) => (a['workId'] as String).compareTo(b['workId'] as String),
  );

  final summary = {
    'total': candidates.length,
    'low': candidates.where((c) => c['severity'] == 'LOW').length,
    'medium': candidates.where((c) => c['severity'] == 'MEDIUM').length,
    'high': candidates.where((c) => c['severity'] == 'HIGH').length,
    'applyRecommended': candidates.every((c) => c['severity'] != 'HIGH'),
  };

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'phase': 'Sprint 04 Phase B',
    'mode': 'audit_only',
    'cohort': 'E1 Steam',
    'summary': summary,
    'items': candidates,
  };

  print(jsonEncode(summary));

  if (writeJson) {
    final outDir = Directory(
      p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
    )..createSync(recursive: true);
    final out = File(p.join(outDir.path, 'sprint_04_e1_audit.json'));
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('Wrote ${out.path}');
  }
}

String _acquisitionMethod(String? posterId, String? legacyId, String steamId) {
  if (posterId == steamId && legacyId == steamId) return 'direct';
  if (posterId == steamId) {
    return legacyId != null ? 'direct' : 'direct';
  }
  if (legacyId == steamId) return 'fallback';
  return 'fallback';
}

Map<String, dynamic> _assessRisks({
  required Map<String, dynamic> work,
  required String steamId,
  required String? posterId,
  required String? legacyId,
  required Map<String, List<String>> steamIndex,
  required Map<String, String> franchiseOf,
  required Map<String, Map<String, dynamic>> byId,
}) {
  final title = work['title']?.toString() ?? '';
  final titleEn =
      (work['titles'] as Map?)?['en']?.toString().toLowerCase() ?? '';
  final combined = '$title $titleEn'.toLowerCase();

  // duplicate externalId
  final dupOwners = (steamIndex[steamId] ?? [])
      .where((id) => id != work['workId']?.toString())
      .toList();
  final duplicate = dupOwners.isNotEmpty;

  // wrong game mapping
  final posterLegacyMismatch = posterId != null &&
      legacyId != null &&
      posterId != legacyId;
  final staleSteamPromo = RegExp(
    r'^save\s+\d+%\s+on\s+',
    caseSensitive: false,
  ).hasMatch(titleEn.trim());
  final crossGameEn = _crossGameTitleMismatch(title, titleEn);
  final wrongMapping =
      posterLegacyMismatch || staleSteamPromo || crossGameEn;
  final wrongMappingDetail = posterLegacyMismatch
      ? 'poster appId ($posterId) != legacy appId ($legacyId)'
      : staleSteamPromo
      ? 'titles.en is Steam promo scrape, not work identity'
      : crossGameEn
      ? 'titles.en names a different game than titles.ko'
      : null;

  // remake / remaster
  final remasterAppIds = {
    '489830', // Skyrim SE
    '1687950', // P5 Royal
  };
  final remasterKeywords = [
    'special edition',
    'goty',
    'royal',
    'remaster',
    'definitive',
    'director',
  ];
  final remasterTitleHit = remasterKeywords.any(combined.contains);
  final remasterAppHit = remasterAppIds.contains(steamId);
  final remakeRemaster = remasterAppHit && !remasterTitleHit;

  // edition / version
  final editionKeywords = [
    ' ii',
    ' iii',
    ' 2',
    ' 3',
    '0',
    'ver.',
    'edition',
  ];
  final editionAppSuspects = {
    '489830': ['special edition', 'se'],
    '1687950': ['royal', 'Î°úÏó¥'],
  };
  var editionVersion = false;
  if (editionAppSuspects.containsKey(steamId)) {
    final hints = editionAppSuspects[steamId]!;
    editionVersion = !hints.any(combined.contains);
  }

  // franchise confusion
  final workId = work['workId']?.toString() ?? '';
  final franchiseId = franchiseOf[workId];
  var franchiseConfusion = false;
  if (franchiseId != null) {
    final siblings = franchiseOf.entries
        .where((e) => e.value == franchiseId && e.key != workId)
        .map((e) => e.key)
        .toList();
    final gameSiblings = siblings
        .where((id) => (byId[id]?['category']?.toString() ?? '') == 'game')
        .toList();
    if (gameSiblings.isNotEmpty) {
      final siblingSteam = gameSiblings
          .map((id) => _externalIds(byId[id] ?? {})['steam'])
          .whereType<String>()
          .toSet();
      if (siblingSteam.isNotEmpty && !siblingSteam.contains(steamId)) {
        franchiseConfusion = true;
      }
      if (gameSiblings.length >= 2) franchiseConfusion = true;
    }
  }

  return {
    'wrong_game_mapping': {
      'present': wrongMapping,
      'level': wrongMapping
          ? (posterLegacyMismatch || crossGameEn ? 'HIGH' : 'MEDIUM')
          : 'none',
      'detail': wrongMappingDetail,
    },
    'remake_remaster_confusion': {
      'present': remakeRemaster,
      'level': remakeRemaster ? 'MEDIUM' : 'none',
      'detail': remakeRemaster
          ? 'remaster-class appId $steamId without matching title token'
          : null,
    },
    'edition_version_confusion': {
      'present': editionVersion,
      'level': editionVersion ? 'MEDIUM' : 'none',
      'detail': editionVersion
          ? 'edition-specific appId without edition token in title'
          : null,
    },
    'franchise_confusion': {
      'present': franchiseConfusion,
      'level': franchiseConfusion ? 'MEDIUM' : 'none',
      'detail': franchiseConfusion
          ? 'franchise siblings with distinct game entries'
          : null,
    },
    'duplicate_externalId': {
      'present': duplicate,
      'level': duplicate ? 'HIGH' : 'none',
      'detail': duplicate ? 'steam:$steamId already on $dupOwners' : null,
    },
    'slug_search_path': {
      'present': false,
      'level': 'none',
      'detail': 'E1 cohort uses deterministic poster/legacy only',
    },
  };
}

String _overallSeverity(Map<String, dynamic> risks) {
  var max = 0;
  for (final entry in risks.entries) {
    if (entry.value is! Map) continue;
    final level = (entry.value as Map)['level']?.toString() ?? 'none';
    final score = switch (level) {
      'HIGH' => 3,
      'MEDIUM' => 2,
      'LOW' => 1,
      _ => 0,
    };
    if (score > max) max = score;
  }
  return switch (max) {
    3 => 'HIGH',
    2 => 'MEDIUM',
    _ => 'LOW',
  };
}

bool _crossGameTitleMismatch(String titleKo, String titleEn) {
  final en = titleEn.toLowerCase();
  final ko = titleKo.toLowerCase();
  if (en.isEmpty) return false;
  const mismatches = [
    (ko: '?àÏ?', enNeedle: 'wukong'),
    (ko: 'Î∏îÎ£® ?ÑÏπ¥?¥Î∏å', enNeedle: 'songs of conquest'),
    (ko: '?åÏù¥???êÌ?ÏßÄ', enNeedle: 'site error'),
  ];
  for (final m in mismatches) {
    if (ko.contains(m.ko) && en.contains(m.enNeedle)) return true;
  }
  return false;
}

Map<String, List<String>> _buildSteamIndex(List<Map<String, dynamic>> works) {
  final index = <String, List<String>>{};
  for (final work in works) {
    final wid = work['workId']?.toString() ?? '';
    final steam = _externalIds(work)['steam'];
    if (steam == null) continue;
    index.putIfAbsent(steam, () => []).add(wid);
  }
  return index;
}

Map<String, String> _loadFranchiseMembership(Directory root) {
  final file = File(p.join(root.path, 'assets', 'registry', 'franchise_groups.json'));
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final out = <String, String>{};
  raw.forEach((fid, value) {
    if (fid.startsWith('_') || value is! Map) return;
    final members = (value['members'] as List?)?.map((e) => e.toString()) ?? [];
    for (final m in members) {
      out[m] = fid;
    }
  });
  return out;
}

Map<String, String> _externalIds(Map<String, dynamic> work) {
  final raw = work['externalIds'];
  if (raw is! Map) return {};
  final out = <String, String>{};
  raw.forEach((k, v) {
    final id = v?.toString().trim() ?? '';
    if (id.isNotEmpty) out[k.toString()] = id;
  });
  return out;
}

String? _resolveSteamAppId(Map<String, dynamic> work) {
  return _steamAppIdFromPoster(work['posterPath']?.toString() ?? '') ??
      _steamAppIdFromLegacy(work['legacyIds']);
}

String? _steamAppIdFromPoster(String poster) {
  final match = RegExp(r'/steam/apps/(\d+)/').firstMatch(poster);
  return match?.group(1);
}

String? _steamAppIdFromLegacy(dynamic legacyIds) {
  if (legacyIds is! List) return null;
  for (final raw in legacyIds) {
    final match = RegExp(r'appid(\d+)').firstMatch(raw?.toString() ?? '');
    if (match != null) return match.group(1);
  }
  return null;
}

Directory _root() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
