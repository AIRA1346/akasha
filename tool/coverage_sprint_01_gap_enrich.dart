// ignore_for_file: avoid_print
/// Coverage Sprint 01 — GAP Panel minimal enrich.
///
/// Usage:
///   dart run tool/coverage_sprint_01_gap_enrich.dart          # dry-run
///   dart run tool/coverage_sprint_01_gap_enrich.dart --apply

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final root = _findProjectRoot();
  final manifest = jsonDecode(
    File('${root.path}/akasha-db/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final patches = _gapEnrichPatches();
  var touched = 0;

  for (final shardMeta in manifest['shards'] as List) {
    final rel = (shardMeta as Map)['path'] as String;
    final file = File('${root.path}/akasha-db/$rel');
    final shard = Map<String, dynamic>.from(
      jsonDecode(file.readAsStringSync()) as Map,
    );
    var dirty = false;

    for (final entry in patches.entries) {
      final workId = entry.key;
      if (!shard.containsKey(workId)) continue;
      final work = Map<String, dynamic>.from(shard[workId] as Map);
      _mergePatch(work, entry.value);
      shard[workId] = work;
      dirty = true;
      touched++;
      print('${apply ? 'APPLY' : 'DRY'} $workId @ $rel');
    }

    if (dirty && apply) {
      file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(shard)}\n');
    }
  }

  print('');
  print(apply ? 'Applied $touched work patch(es).' : 'Dry-run: $touched work patch(es). Use --apply to write.');
  if (apply) {
    print('Next: dart run tool/registry_builder.dart --sync-assets');
  }
}

void _mergePatch(Map<String, dynamic> work, Map<String, dynamic> patch) {
  if (patch.containsKey('titles')) {
    final existing = work['titles'] is Map
        ? Map<String, dynamic>.from(work['titles'] as Map)
        : <String, dynamic>{};
    final incoming = patch['titles'] as Map<String, dynamic>;
    incoming.forEach((k, v) {
      if (v != null && v.toString().trim().isNotEmpty) {
        existing[k] = v;
      }
    });
    work['titles'] = existing;
  }

  if (patch.containsKey('aliases')) {
    final set = <String>{};
    if (work['aliases'] is List) {
      for (final a in work['aliases'] as List) {
        final s = a.toString().trim();
        if (s.isNotEmpty) set.add(s);
      }
    }
    for (final a in patch['aliases'] as List) {
      final s = a.toString().trim();
      if (s.isNotEmpty) set.add(s);
    }
    work['aliases'] = set.toList()..sort();
  }
}

Map<String, Map<String, dynamic>> _gapEnrichPatches() => {
      'wk_000000343': {
        'titles': {
          'ko': '귀멸의 칼날',
          'en': 'Demon Slayer: Kimetsu no Yaiba',
          'ja': '鬼滅の刃',
          'zh': '鬼灭之刃',
          'romaji': 'Kimetsu no Yaiba',
        },
        'aliases': ['Demon Slayer', 'Kimetsu no Yaiba'],
      },
      'wk_000000188': {
        'titles': {
          'ko': '귀멸의 칼날',
          'en': 'Demon Slayer: Kimetsu no Yaiba',
          'ja': '鬼滅の刃',
          'zh': '鬼灭之刃',
          'romaji': 'Kimetsu no Yaiba',
        },
        'aliases': ['Demon Slayer', 'Kimetsu no Yaiba'],
      },
      'wk_000000387': {
        'titles': {
          'ko': '스파이 패밀리',
          'en': 'Spy x Family',
          'ja': 'SPY×FAMILY',
          'romaji': 'Spy x Family',
        },
        'aliases': ['Spy Family', 'SPY×FAMILY'],
      },
      'wk_000000239': {
        'titles': {
          'ko': '스파이 패밀리',
          'en': 'Spy x Family',
          'ja': 'SPY×FAMILY',
          'romaji': 'Spy x Family',
        },
        'aliases': ['Spy Family', 'SPY×FAMILY'],
      },
      'wk_000000325': {
        'titles': {
          'ko': '강철의 연금술사',
          'en': 'Fullmetal Alchemist',
          'ja': '鋼の錬金術師',
          'romaji': 'Hagane no Renkinjutsushi',
        },
        'aliases': ['FMA', 'Fullmetal Alchemist'],
      },
      'wk_000000194': {
        'titles': {
          'ko': '강철의 연금술사 BROTHERHOOD',
          'en': 'Fullmetal Alchemist: Brotherhood',
          'ja': '鋼の錬金術師 FULLMETAL ALCHEMIST',
          'romaji': 'Hagane no Renkinjutsushi',
        },
        'aliases': ['FMA', 'Fullmetal Alchemist', 'Brotherhood'],
      },
      'wk_000000354': {
        'titles': {
          'ko': '무직전생',
          'en': 'Mushoku Tensei: Jobless Reincarnation',
          'ja': '無職転生',
          'romaji': 'Mushoku Tensei',
        },
        'aliases': ['Mushoku Tensei', 'Jobless Reincarnation'],
      },
      'wk_000000257': {
        'titles': {
          'ko': '무직전생',
          'en': 'Mushoku Tensei: Jobless Reincarnation',
          'ja': '無職転生',
          'romaji': 'Mushoku Tensei',
        },
        'aliases': ['Mushoku Tensei', 'Jobless Reincarnation'],
      },
      'wk_000000230': {
        'titles': {
          'ko': 'Re:제로',
          'en': 'Re:Zero − Starting Life in Another World',
          'ja': 'Re:ゼロから始める異世界生活',
          'romaji': 'Re:Zero',
        },
        'aliases': ['Re:Zero', 'Re:ゼロ', 'Re Zero'],
      },
      'wk_000000375': {
        'titles': {
          'ko': 'Re:제로부터 시작하는 이세계 생활',
          'en': 'Re:Zero − Starting Life in Another World',
          'ja': 'Re:ゼロから始める異世界生活',
          'romaji': 'Re:Zero',
        },
        'aliases': ['Re:Zero', 'Re:ゼロ', 'Re Zero'],
      },
      'wk_000000291': {
        'titles': {
          'ko': '20세기 소년',
          'en': '20th Century Boys',
          'ja': '20世紀少年',
          'romaji': '20th Century Boys',
        },
        'aliases': ['20th Century Boys'],
      },
      'wk_000000187': {
        'titles': {
          'zh': '死亡笔记',
        },
        'aliases': ['死亡笔记'],
      },
      'wk_000000218': {
        'titles': {
          'zh': '火影忍者',
        },
        'aliases': ['火影忍者'],
      },
      'wk_000000010': {
        'titles': {
          'ko': '반지의 제왕: 반지 원정대',
          'en': 'The Lord of the Rings: The Fellowship of the Ring',
        },
        'aliases': [
          'Lord of the Rings',
          'The Lord of the Rings',
          'The Fellowship of the Ring',
        ],
      },
      'wk_000000158': {
        'titles': {
          'ko': '반지의 제왕: 반지 원정대',
          'en': 'The Lord of the Rings: The Fellowship of the Ring',
        },
        'aliases': [
          'Lord of the Rings',
          'The Lord of the Rings',
          'The Fellowship of the Ring',
        ],
      },
      'wk_000000310': {
        'titles': {
          'ko': '단다단',
          'en': 'Dandadan',
          'ja': 'ダンダダン',
          'romaji': 'Dandadan',
        },
        'aliases': ['Dandadan', 'ダンダダン'],
      },
      'wk_000000185': {
        'titles': {
          'ko': '단다단',
          'en': 'Dandadan',
          'ja': 'ダンダダン',
          'romaji': 'Dandadan',
        },
        'aliases': ['Dandadan', 'ダンダダン'],
      },
    };

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('project root not found');
}
