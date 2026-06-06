import 'enums.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 샤딩 레지스트리 메타데이터 모델
// ════════════════════════════════════════════════════════════════

class RegistryShardMeta {
  final String id;
  final MediaCategory category;
  final String path;
  final bool eager;
  final int entryCount;

  const RegistryShardMeta({
    required this.id,
    required this.category,
    required this.path,
    this.eager = false,
    this.entryCount = 0,
  });

  factory RegistryShardMeta.fromJson(Map<String, dynamic> json) {
    final categoryStr = json['category']?.toString() ?? 'manga';
    return RegistryShardMeta(
      id: json['id']?.toString() ?? '',
      category: MediaCategory.values.firstWhere(
        (e) => e.name == categoryStr,
        orElse: () => MediaCategory.manga,
      ),
      path: json['path']?.toString() ?? '',
      eager: json['eager'] == true,
      entryCount: int.tryParse(json['entryCount']?.toString() ?? '') ?? 0,
    );
  }
}

class RegistryManifest {
  final int version;
  final List<RegistryShardMeta> shards;

  const RegistryManifest({
    required this.version,
    required this.shards,
  });

  factory RegistryManifest.fromJson(Map<String, dynamic> json) {
    final shardList = (json['shards'] as List?) ?? const [];
    return RegistryManifest(
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
      shards: shardList
          .whereType<Map>()
          .map((e) => RegistryShardMeta.fromJson(Map<String, dynamic>.from(e)))
          .where((s) => s.id.isNotEmpty && s.path.isNotEmpty)
          .toList(),
    );
  }

  RegistryShardMeta? shardById(String id) {
    for (final shard in shards) {
      if (shard.id == id) return shard;
    }
    return null;
  }

  List<RegistryShardMeta> eagerShards() =>
      shards.where((s) => s.eager).toList();
}

class RegistrySearchIndexEntry {
  final String workId;
  final String title;
  final String shardId;
  final MediaCategory category;
  final AppDomain domain;

  const RegistrySearchIndexEntry({
    required this.workId,
    required this.title,
    required this.shardId,
    required this.category,
    required this.domain,
  });

  factory RegistrySearchIndexEntry.fromJson(Map<String, dynamic> json) {
    final categoryStr = json['category']?.toString() ?? 'manga';
    final domainStr = json['domain']?.toString() ?? 'subculture';
    return RegistrySearchIndexEntry(
      workId: json['workId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      shardId: json['shardId']?.toString() ?? '',
      category: MediaCategory.values.firstWhere(
        (e) => e.name == categoryStr,
        orElse: () => MediaCategory.manga,
      ),
      domain: AppDomain.values.firstWhere(
        (e) => e.name == domainStr,
        orElse: () => AppDomain.subculture,
      ),
    );
  }
}
