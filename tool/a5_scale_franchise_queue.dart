// ignore_for_file: avoid_print
/// A5 Scale — O12 franchise 수동 큐 스냅샷.
///
/// Usage: dart run tool/a5_scale_franchise_queue.dart [--apply]
///
/// 산출: akasha-db/pipeline/artifacts/coverage_dashboard/scale_franchise_o12.json

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// SD4.3 — franchise 클러스터 1건 수동 연결 추정 (maintainer-minutes).
const _minutesPerCluster = 15.0;

void main(List<String> args) {
  final apply = args.contains('--apply');
  final minMembers = _readMinMembers(args);
  final root = _root();

  final manifest = jsonDecode(
    File(p.join(root.path, 'akasha-db', 'manifest.json')).readAsStringSync(),
  ) as Map<String, dynamic>;
  final works = manifest['entryCount'] as int? ?? manifest['works'] as int? ?? 0;

  final indexPath = p.join(root.path, 'assets', 'registry', 'search_index.json');
  final groupsPath = p.join(root.path, 'assets', 'registry', 'franchise_groups.json');

  final index = json.decode(File(indexPath).readAsStringSync()) as List;
  final groupsRaw =
      json.decode(File(groupsPath).readAsStringSync()) as Map<String, dynamic>;

  final memberToFranchise = <String, String>{};
  groupsRaw.forEach((franchiseId, value) {
    if (value is! Map) return;
    final members =
        (value['members'] as List?)?.map((e) => e.toString()) ?? [];
    for (final member in members) {
      memberToFranchise[member] = franchiseId;
    }
  });

  final clusters = <String, List<Map<String, dynamic>>>{};
  for (final entry in index) {
    if (entry is! Map) continue;
    final map = Map<String, dynamic>.from(entry);
    final workId = map['workId']?.toString() ?? '';
    if (workId.isEmpty) continue;
    final stem = _franchiseStem(workId);
    if (stem.isEmpty) continue;
    final domainPrefix = workId.startsWith('gen_') ? 'gen' : 'sub';
    final key = '$domainPrefix::$stem';
    clusters.putIfAbsent(key, () => []).add(map);
  }

  final queue = <Map<String, dynamic>>[];
  var uncoveredMembers = 0;

  for (final entry in clusters.entries) {
    final members = entry.value;
    if (members.length < minMembers) continue;

    final categories = members.map((m) => m['category']?.toString()).toSet();
    if (categories.length < 2) continue;

    final franchiseIds = <String>{};
    var uncovered = 0;
    final workIds = <String>[];
    for (final m in members) {
      final workId = m['workId']?.toString() ?? '';
      workIds.add(workId);
      final fid = memberToFranchise[workId];
      if (fid == null) {
        uncovered++;
      } else {
        franchiseIds.add(fid);
      }
    }

    if (uncovered == 0 && franchiseIds.length == 1) continue;

    uncoveredMembers += uncovered;
    queue.add({
      'clusterKey': entry.key,
      'memberCount': members.length,
      'mediaCount': categories.length,
      'uncoveredMembers': uncovered,
      'franchiseIdCount': franchiseIds.length,
      'workIds': workIds,
      'suggestedPrimaryWorkId': _suggestPrimary(workIds),
      'estimatedMinutes': _minutesPerCluster,
    });
  }

  final totalMinutes = queue.length * _minutesPerCluster;
  final extrapolate = (int targetWorks) {
    final factor = works == 0 ? 1.0 : targetWorks / works;
    return {
      'targetWorks': targetWorks,
      'queueClustersEst': (queue.length * factor).round(),
      'uncoveredMembersEst': (uncoveredMembers * factor).round(),
      'estimatedMinutes': (totalMinutes * factor).round(),
    };
  };

  print('=== Scale O12 franchise queue (@$works works) ===\n');
  print('Clusters needing attention: ${queue.length}');
  print('Uncovered members: $uncoveredMembers');
  print('Estimated queue minutes: $totalMinutes');

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'observation': 'O12',
    'works': works,
    'minMembers': minMembers,
    'queueClusters': queue.length,
    'uncoveredMembers': uncoveredMembers,
    'minutesPerCluster': _minutesPerCluster,
    'estimatedMinutesTotal': totalMinutes,
    'extrapolationLinear': [extrapolate(5000), extrapolate(50000)],
    'clusters': queue,
    'status': queue.length <= 50 ? 'PASS' : 'REVIEW',
  };

  if (apply) {
    final outDir = Directory(
      p.join(root.path, 'akasha-db', 'pipeline', 'artifacts', 'coverage_dashboard'),
    );
    outDir.createSync(recursive: true);
    final out = File(p.join(outDir.path, 'scale_franchise_o12.json'));
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    print('Wrote ${out.path}');
  } else {
    print('Dry-run — pass --apply to write report');
  }
}

int _readMinMembers(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--min-members=')) {
      return int.tryParse(arg.split('=').last) ?? 2;
    }
  }
  return 2;
}

String _franchiseStem(String workId) {
  final withoutYear = workId.replaceFirst(RegExp(r'_\d{4}$'), '');
  final match = RegExp(
    r'^(?:sub|gen)_(?:manga|webtoon|animation|game|book|movie|drama)_(.+)$',
  ).firstMatch(withoutYear);
  if (match == null) return '';

  var slug = match.group(1)!;
  slug = slug
      .replaceAll(RegExp(r'-light-novel$'), '')
      .replaceAll(RegExp(r'-anime$'), '')
      .replaceAll(RegExp(r'-sub$'), '')
      .replaceAll(RegExp(r'-manga$'), '');
  return slug.toLowerCase();
}

String _suggestPrimary(List<String> workIds) {
  for (final id in workIds) {
    if (id.contains('_manga_')) return id;
  }
  for (final id in workIds) {
    if (id.contains('_book_')) return id;
  }
  return workIds.first;
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
