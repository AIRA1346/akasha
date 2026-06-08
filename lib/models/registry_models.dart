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
  /// v4 — 샤드 JSON 본문 SHA-256 (증분 sync)
  final String? sha256;

  const RegistryShardMeta({
    required this.id,
    required this.category,
    required this.path,
    this.eager = false,
    this.entryCount = 0,
    this.sha256,
  });

  factory RegistryShardMeta.fromJson(Map<String, dynamic> json) {
    final categoryStr = json['category']?.toString() ?? 'manga';
    final sha = json['sha256']?.toString();
    return RegistryShardMeta(
      id: json['id']?.toString() ?? '',
      category: MediaCategory.values.firstWhere(
        (e) => e.name == categoryStr,
        orElse: () => MediaCategory.manga,
      ),
      path: json['path']?.toString() ?? '',
      eager: json['eager'] == true,
      entryCount: int.tryParse(json['entryCount']?.toString() ?? '') ?? 0,
      sha256: sha != null && sha.isNotEmpty ? sha : null,
    );
  }
}

class RegistryManifest {
  final int version;
  final String? generatedAt;
  final List<RegistryShardMeta> shards;
  /// v4 — `hash(wk_) % 2^shardBits`
  final int? shardBits;
  final int? entryCount;

  const RegistryManifest({
    required this.version,
    this.generatedAt,
    required this.shards,
    this.shardBits,
    this.entryCount,
  });

  factory RegistryManifest.fromJson(Map<String, dynamic> json) {
    final shardList = (json['shards'] as List?) ?? const [];
    return RegistryManifest(
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
      generatedAt: json['generatedAt']?.toString(),
      shardBits: int.tryParse(json['shardBits']?.toString() ?? ''),
      entryCount: int.tryParse(json['entryCount']?.toString() ?? ''),
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
  final String creator;
  final List<String> tags;
  final String? posterPath;
  /// v3 — 교차 언어·별칭 검색용 (registry_builder가 생성)
  final List<String> searchTokens;
  /// 빌드 시 파생 — shard에 저장하지 않음
  final int qualityScore;
  final int qualityTier;

  const RegistrySearchIndexEntry({
    required this.workId,
    required this.title,
    required this.shardId,
    required this.category,
    required this.domain,
    this.creator = '',
    this.tags = const [],
    this.posterPath,
    this.searchTokens = const [],
    this.qualityScore = 0,
    this.qualityTier = 0,
  });

  factory RegistrySearchIndexEntry.fromJson(Map<String, dynamic> json) {
    final categoryStr = json['category']?.toString() ?? 'manga';
    final domainStr = json['domain']?.toString() ?? 'subculture';
    final poster = json['posterPath']?.toString();
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
      creator: json['creator']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      posterPath:
          poster != null && poster.isNotEmpty ? poster : null,
      searchTokens: (json['searchTokens'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      qualityScore:
          int.tryParse(json['qualityScore']?.toString() ?? '') ?? 0,
      qualityTier: int.tryParse(json['qualityTier']?.toString() ?? '') ?? 0,
    );
  }
}
