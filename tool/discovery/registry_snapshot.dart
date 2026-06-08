/// Registry in-memory snapshot (read-only) — Shadow Write dedupe·시뮬레이션용.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../dedupe_utils.dart';

class RegistryWorkEntry {
  final String workId;
  final String title;
  final String category;
  final int? releaseYear;
  final Map<String, String> externalIds;
  final List<String> legacyIds;
  final Set<String> normalizedTitles;
  final Map<String, dynamic> work;

  const RegistryWorkEntry({
    required this.workId,
    required this.title,
    required this.category,
    required this.releaseYear,
    required this.externalIds,
    required this.legacyIds,
    required this.normalizedTitles,
    required this.work,
  });
}

class RegistrySnapshot {
  final List<RegistryWorkEntry> works;
  final Map<String, RegistryWorkEntry> byWorkId;
  final Map<String, List<RegistryWorkEntry>> byExternalKey;
  final Map<String, List<RegistryWorkEntry>> byTitleKey;

  const RegistrySnapshot({
    required this.works,
    required this.byWorkId,
    required this.byExternalKey,
    required this.byTitleKey,
  });

  factory RegistrySnapshot.load(Directory projectRoot) {
    final works = <RegistryWorkEntry>[];
    final shardsRoot =
        Directory(p.join(projectRoot.path, 'akasha-db', 'shards'));

    if (shardsRoot.existsSync()) {
      for (final file in shardsRoot.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.json')) continue;
        final decoded = json.decode(file.readAsStringSync());
        if (decoded is! Map) continue;

        for (final entry in decoded.entries) {
          if (entry.value is! Map) continue;
          works.add(_entryFromShard(entry.key.toString(), entry.value as Map));
        }
      }
    }

    return RegistrySnapshot.fromWorks(works);
  }

  factory RegistrySnapshot.fromWorks(List<RegistryWorkEntry> works) {
    final byWorkId = <String, RegistryWorkEntry>{};
    final byExternalKey = <String, List<RegistryWorkEntry>>{};
    final byTitleKey = <String, List<RegistryWorkEntry>>{};

    for (final w in works) {
      byWorkId[w.workId] = w;
      w.externalIds.forEach((source, id) {
        final key = '${source.toLowerCase()}:$id';
        byExternalKey.putIfAbsent(key, () => []).add(w);
      });
      for (final norm in w.normalizedTitles) {
        if (norm.length < 2) continue;
        final key = '${w.category}::$norm';
        byTitleKey.putIfAbsent(key, () => []).add(w);
      }
    }

    return RegistrySnapshot(
      works: works,
      byWorkId: byWorkId,
      byExternalKey: byExternalKey,
      byTitleKey: byTitleKey,
    );
  }

  static RegistryWorkEntry _entryFromShard(String mapKey, Map raw) {
    final work = Map<String, dynamic>.from(raw);
    final workId = work['workId']?.toString() ?? mapKey;
    final title = work['title']?.toString() ?? workId;

    final externalIds = <String, String>{};
    final ext = work['externalIds'];
    if (ext is Map) {
      ext.forEach((k, v) {
        final val = v?.toString().trim();
        if (val != null && val.isNotEmpty) {
          externalIds[k.toString()] = val;
        }
      });
    }

    final legacyIds = <String>[];
    final legacy = work['legacyIds'];
    if (legacy is List) {
      for (final id in legacy) {
        final s = id.toString();
        if (s.isNotEmpty) legacyIds.add(s);
      }
    }

    final normalizedTitles = <String>{};
    void addTitle(String? t) {
      if (t == null || t.isEmpty) return;
      final n = normalizeTitle(t);
      if (n.isNotEmpty) normalizedTitles.add(n);
    }

    addTitle(title);
    final titles = work['titles'];
    if (titles is Map) {
      titles.forEach((_, v) => addTitle(v?.toString()));
    }
    final aliases = work['aliases'];
    if (aliases is List) {
      for (final a in aliases) {
        addTitle(a?.toString());
      }
    }

    return RegistryWorkEntry(
      workId: workId,
      title: title,
      category: work['category']?.toString() ?? 'unknown',
      releaseYear: work['releaseYear'] is int
          ? work['releaseYear'] as int
          : int.tryParse(work['releaseYear']?.toString() ?? ''),
      externalIds: externalIds,
      legacyIds: legacyIds,
      normalizedTitles: normalizedTitles,
      work: work,
    );
  }
}

int? readNextWkSequence(Directory projectRoot) {
  final file = File(p.join(projectRoot.path, 'akasha-db', 'id_registry.json'));
  if (!file.existsSync()) return 1;
  final decoded = json.decode(file.readAsStringSync());
  if (decoded is! Map) return 1;
  final next = int.tryParse(decoded['nextWorkId']?.toString() ?? '');
  return next != null && next > 0 ? next : 1;
}

Set<String> loadDedupeAllowedPairs(Directory projectRoot) {
  final allowed = <String>{};
  final path = p.join(projectRoot.path, 'akasha-db', 'dedupe_exceptions.json');
  final file = File(path);
  if (!file.existsSync()) return allowed;

  final raw = json.decode(file.readAsStringSync());
  if (raw is! Map) return allowed;
  final pairs = raw['allowedPairs'];
  if (pairs is! List) return allowed;

  for (final item in pairs) {
    if (item is! Map) continue;
    final a = item['wkA']?.toString() ?? item['a']?.toString();
    final b = item['wkB']?.toString() ?? item['b']?.toString();
    if (a == null || b == null) continue;
    allowed.add(pairKey(a, b));
  }
  return allowed;
}

Map<String, Set<String>> loadFranchisePeers(Directory projectRoot) {
  final peers = <String, Set<String>>{};
  final path = p.join(projectRoot.path, 'akasha-db', 'franchise_groups.json');
  final file = File(path);
  if (!file.existsSync()) return peers;

  final raw = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  raw.forEach((key, value) {
    if (key.startsWith('_') || value is! Map) return;
    final members =
        (value['members'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    for (final m in members) {
      peers.putIfAbsent(m, () => {}).addAll(members.where((x) => x != m));
    }
  });
  return peers;
}

bool releaseYearsCompatible(int? a, int? b) {
  if (a == null || b == null) return true;
  return (a - b).abs() <= 1;
}
