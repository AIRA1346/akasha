// ignore_for_file: avoid_print
/// 프랜차이즈 그룹 누락 후보를 탐지합니다.
///
/// Usage: dart run tool/franchise_linter.dart [--min-members=2]
///
/// search_index.json의 workId 슬러그를 정규화해 같은 IP 후보를 묶고,
/// franchise_groups.json에 아직 없는 클러스터를 출력합니다.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final minMembers = _readMinMembers(args);
  final root = _findProjectRoot();
  final indexPath = '${root.path}/assets/registry/search_index.json';
  final groupsPath = '${root.path}/assets/registry/franchise_groups.json';

  final index = json.decode(File(indexPath).readAsStringSync()) as List;
  final groupsRaw =
      json.decode(File(groupsPath).readAsStringSync()) as Map<String, dynamic>;

  final memberToFranchise = <String, String>{};
  groupsRaw.forEach((franchiseId, value) {
    if (value is! Map) return;
    final members = (value['members'] as List?)?.map((e) => e.toString()) ?? [];
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

  var issueCount = 0;

  print('Franchise linter — min members: $minMembers\n');

  for (final entry in clusters.entries) {
    final members = entry.value;
    if (members.length < minMembers) continue;

    final categories = members.map((m) => m['category']?.toString()).toSet();
    if (categories.length < 2) continue;

    final franchiseIds = <String>{};
    var uncovered = 0;
    for (final m in members) {
      final workId = m['workId']?.toString() ?? '';
      final fid = memberToFranchise[workId];
      if (fid == null) {
        uncovered++;
      } else {
        franchiseIds.add(fid);
      }
    }

    if (uncovered == 0 && franchiseIds.length == 1) continue;

    issueCount++;
    final titles = members.map((m) => m['title']?.toString() ?? '').toList();
    final workIds = members.map((m) => m['workId']?.toString() ?? '').toList();
    final primary = _suggestPrimary(workIds);

    print('─ ${entry.key} (${members.length} works, ${categories.length} media)');
    for (var i = 0; i < members.length; i++) {
      final wid = workIds[i];
      final fid = memberToFranchise[wid];
      final tag = fid == null ? 'MISSING' : fid;
      print('  [$tag] ${titles[i]} ($wid)');
    }
    print('  suggested primaryWorkId: $primary');
    print('  suggested displayName: ${titles[workIds.indexOf(primary)]}');
    print('');
  }

  if (issueCount == 0) {
    print('No uncovered multi-media clusters found.');
  } else {
    print('$issueCount cluster(s) need franchise_groups.json attention.');
  }

  exit(issueCount > 0 ? 1 : 0);
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

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
