// ignore_for_file: avoid_print
/// Sprint 04-R2 Phase C — E1 cohort 15건 resolution runner.
///
/// 근거 문서:
/// - docs/sprint-04-e1-post-gate-audit.md (REVIEW 7 / BLOCK 8)
/// - docs/sprint-04-high-risk-disposition.md (HIGH 4 disposition)
/// - 2026-06-10 외부 검증: appId 2358720=Black Myth: Wukong (NIKKE Steam 미출시),
///   appId 3511790=Songs of Conquest DLC (Blue Archive 실제 appId=3557620),
///   wk_144=원판(2011, appId 72850) — SE(489830)와 별개 listing.
///
/// Usage:
///   dart run tool/coverage_sprint_04_e1_resolution.dart            # dry-run
///   dart run tool/coverage_sprint_04_e1_resolution.dart --apply
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'quality_loop_utils.dart';

/// posterPath 제거 sentinel.
const _removePoster = '__REMOVE__';

class _Patch {
  const _Patch({
    required this.workId,
    required this.wave,
    this.expectTitleEnPrefix,
    this.newTitleEn,
    this.newPoster,
    this.attachSteamId,
  });

  final String workId;
  final String wave;

  /// 안전 가드 — 현재 titles.en이 이 prefix로 시작해야 적용.
  final String? expectTitleEnPrefix;
  final String? newTitleEn;
  final String? newPoster;
  final String? attachSteamId;
}

const _patches = <_Patch>[
  // W1 — REVIEW 7건 (E4 token overlap only) · 인적 승인 2026-06-10
  _Patch(workId: 'wk_000000143', wave: 'W1_review', attachSteamId: '620'),
  _Patch(workId: 'wk_000000145', wave: 'W1_review', attachSteamId: '413150'),
  _Patch(workId: 'wk_000000146', wave: 'W1_review', attachSteamId: '292030'),
  _Patch(workId: 'wk_000000276', wave: 'W1_review', attachSteamId: '524220'),
  _Patch(workId: 'wk_000000278', wave: 'W1_review', attachSteamId: '921570'),
  _Patch(workId: 'wk_000000279', wave: 'W1_review', attachSteamId: '1687950'),
  _Patch(workId: 'wk_000000289', wave: 'W1_review', attachSteamId: '638970'),

  // W2 — E2 BLOCK 4건: steam_fetch 프로모 배너 오염 정리 후 attach (appId 정합)
  _Patch(
    workId: 'wk_000000267',
    wave: 'W2_e2_title_fix',
    expectTitleEnPrefix: 'Save ',
    newTitleEn: 'Celeste',
    attachSteamId: '504230',
  ),
  _Patch(
    workId: 'wk_000000268',
    wave: 'W2_e2_title_fix',
    expectTitleEnPrefix: 'Save ',
    newTitleEn: 'Danganronpa: Trigger Happy Havoc',
    attachSteamId: '413410',
  ),
  _Patch(
    workId: 'wk_000000275',
    wave: 'W2_e2_title_fix',
    expectTitleEnPrefix: 'Save ',
    newTitleEn: 'Monster Hunter: World',
    attachSteamId: '582010',
  ),
  _Patch(
    workId: 'wk_000000286',
    wave: 'W2_e2_title_fix',
    expectTitleEnPrefix: 'Save ',
    newTitleEn: 'UNDERTALE',
    attachSteamId: '391540',
  ),

  // W3 — 블루 아카이브: poster appId 3511790은 타 게임 DLC → 제거.
  // 실제 Blue Archive Steam appId 3557620 (2025-07 출시) attach.
  _Patch(
    workId: 'wk_000000266',
    wave: 'W3_blue_archive',
    expectTitleEnPrefix: 'Save ',
    newTitleEn: 'Blue Archive',
    newPoster: _removePoster,
    attachSteamId: '3557620',
  ),

  // W4 — FFXIV: fetch 실패 placeholder 복구 + attach (appId 39210 정합)
  _Patch(
    workId: 'wk_000000270',
    wave: 'W4_ffxiv',
    expectTitleEnPrefix: 'Site Error',
    newTitleEn: 'FINAL FANTASY XIV Online',
    attachSteamId: '39210',
  ),

  // W5 — 스카이림 wk_144: 원판(2011) work를 SE 데이터 오염에서 분리 정정.
  // 원판 listing appId 72850 attach → wk_111(SE·489830)과 E3/E5 충돌 해소.
  _Patch(
    workId: 'wk_000000144',
    wave: 'W5_skyrim_split',
    expectTitleEnPrefix: 'The Elder Scrolls V: Skyrim Special Edition',
    newTitleEn: 'The Elder Scrolls V: Skyrim',
    newPoster:
        'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/72850/library_600x900.jpg',
    attachSteamId: '72850',
  ),

  // W6 — 니케 wk_277: en·poster가 Black Myth: Wukong 데이터로 오염.
  // NIKKE는 Steam 미출시 → steam attach 없음, identity만 복구.
  _Patch(
    workId: 'wk_000000277',
    wave: 'W6_nikke_identity',
    expectTitleEnPrefix: 'Black Myth: Wukong',
    newTitleEn: 'GODDESS OF VICTORY: NIKKE',
    newPoster: _removePoster,
  ),
];

void main(List<String> args) {
  final apply = args.contains('--apply');
  final root = _findProjectRoot();
  final manifest =
      jsonDecode(
            File(p.join(root.path, 'akasha-db', 'manifest.json'))
                .readAsStringSync(),
          )
          as Map<String, dynamic>;

  final shards = <_ShardFile>[];
  for (final raw in manifest['shards'] as List) {
    final path = p.join(root.path, 'akasha-db', (raw as Map)['path'] as String);
    shards.add(
      _ShardFile(
        File(path),
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
      ),
    );
  }

  final byWorkId = <String, _ShardFile>{};
  final steamOwners = <String, String>{};
  var externalCount = 0;
  var totalWorks = 0;
  for (final shard in shards) {
    for (final entry in shard.works.entries) {
      totalWorks++;
      byWorkId[entry.key] = shard;
      final work = entry.value as Map;
      final ext = work['externalIds'];
      if (ext is Map && ext.isNotEmpty) externalCount++;
      final steam = ext is Map ? ext['steam']?.toString() : null;
      if (steam != null && steam.isNotEmpty) steamOwners[steam] = entry.key;
    }
  }

  final results = <Map<String, dynamic>>[];
  final errors = <String>[];
  final touched = <_ShardFile>{};
  var attached = 0;

  for (final patch in _patches) {
    final shard = byWorkId[patch.workId];
    if (shard == null) {
      errors.add('${patch.workId}: not found in any shard');
      continue;
    }
    final work = Map<String, dynamic>.from(shard.works[patch.workId] as Map);
    final titles = work['titles'] is Map
        ? Map<String, dynamic>.from(work['titles'] as Map)
        : <String, dynamic>{};
    final currentEn = titles['en']?.toString() ?? '';

    // 가드 1 — 기대 상태 확인 (이미 처리됐거나 데이터가 변했으면 skip)
    if (patch.expectTitleEnPrefix != null &&
        !currentEn.startsWith(patch.expectTitleEnPrefix!)) {
      errors.add(
        '${patch.workId}: titles.en guard mismatch '
        '(expected prefix "${patch.expectTitleEnPrefix}", got "$currentEn")',
      );
      continue;
    }

    // 가드 2 — attach 대상은 externalIds가 비어 있어야 함
    final existingExt = work['externalIds'];
    if (patch.attachSteamId != null &&
        existingExt is Map &&
        existingExt.isNotEmpty) {
      errors.add('${patch.workId}: externalIds already present, skip attach');
      continue;
    }

    // 가드 3 — E3/E5: candidate appId가 다른 work에 이미 부착되어 있으면 차단
    if (patch.attachSteamId != null) {
      final owner = steamOwners[patch.attachSteamId];
      if (owner != null && owner != patch.workId) {
        errors.add(
          '${patch.workId}: steam:${patch.attachSteamId} already owned by $owner (E3/E5)',
        );
        continue;
      }
    }

    final fields = <String, dynamic>{};
    if (patch.newTitleEn != null) {
      titles['en'] = patch.newTitleEn;
      fields['titles'] = titles;
    }
    if (patch.newPoster != null && patch.newPoster != _removePoster) {
      fields['posterPath'] = patch.newPoster;
    }
    if (patch.attachSteamId != null) {
      fields['externalIds'] = {'steam': patch.attachSteamId};
    }

    var next = applyFixToWork(work, fields).work;
    if (patch.newPoster == _removePoster) {
      next = Map<String, dynamic>.from(next)..remove('posterPath');
      final signals = next['qualitySignals'];
      if (signals is Map) {
        final cleaned = Map<String, dynamic>.from(signals)
          ..remove('hasPoster')
          ..remove('posterVerified');
        if (cleaned.isEmpty) {
          next.remove('qualitySignals');
        } else {
          next['qualitySignals'] = cleaned;
        }
      }
    }

    final extensions = next['extensions'] is Map
        ? Map<String, dynamic>.from(next['extensions'] as Map)
        : <String, dynamic>{};
    if (patch.attachSteamId != null) {
      extensions['coverageSprint04ExternalId'] = 'steam';
    }
    extensions['coverageSprint04R2Fix'] = patch.wave;
    next['extensions'] = extensions;

    if (apply) {
      shard.works[patch.workId] = next;
      touched.add(shard);
    }
    if (patch.attachSteamId != null) {
      steamOwners[patch.attachSteamId!] = patch.workId;
      attached++;
    }

    results.add({
      'workId': patch.workId,
      'wave': patch.wave,
      'titleEn': {'before': currentEn, 'after': patch.newTitleEn ?? currentEn},
      'posterChanged': patch.newPoster != null,
      'posterRemoved': patch.newPoster == _removePoster,
      'attached': patch.attachSteamId == null
          ? null
          : 'steam:${patch.attachSteamId}',
    });
  }

  if (apply && errors.isEmpty) {
    for (final shard in touched) {
      shard.write();
    }
  }

  final outDir = Directory(
    p.join(
      root.path,
      'akasha-db',
      'pipeline',
      'artifacts',
      'coverage_dashboard',
    ),
  )..createSync(recursive: true);
  final reportFile = File(
    p.join(outDir.path, 'sprint_04_e1_resolution_report.json'),
  );
  reportFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'mode': apply ? 'apply' : 'dry-run',
      'totalWorks': totalWorks,
      'externalIdBefore': externalCount,
      'externalIdAfter': externalCount + attached,
      'coverageAfter': totalWorks == 0
          ? 0
          : (externalCount + attached) / totalWorks,
      'patches': results,
      'errors': errors,
    }),
  );

  print(
    jsonEncode({
      'mode': apply ? 'apply' : 'dry-run',
      'patched': results.length,
      'attached': attached,
      'externalId': '${externalCount + attached}/$totalWorks',
      'errors': errors.length,
      'report': p.relative(reportFile.path, from: root.path),
    }),
  );
  if (errors.isNotEmpty) {
    for (final e in errors) {
      stderr.writeln('ERROR: $e');
    }
    exitCode = 2;
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      stderr.writeln('ERROR: project root not found');
      exit(1);
    }
    dir = parent;
  }
}

class _ShardFile {
  _ShardFile(this.file, this.works);

  final File file;
  final Map<String, dynamic> works;

  void write() {
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(works)}\n',
    );
  }
}
