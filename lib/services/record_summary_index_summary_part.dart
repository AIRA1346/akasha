part of 'record_summary_index_service.dart';

class VaultRecordSummary {
  const VaultRecordSummary({
    required this.id,
    required this.recordKind,
    required this.entityType,
    required this.title,
    required this.relativePath,
    this.category,
    this.creator,
    this.releaseYear,
    this.rating,
    this.workStatus,
    this.myStatus,
    this.tags = const [],
    this.addedAt,
    this.updatedAt,
    this.posterPath,
    this.entitySubtype,
  });

  final String id;
  final RecordKind recordKind;
  final String entityType;
  final String title;
  final String relativePath;
  final String? category;
  final String? creator;
  final int? releaseYear;
  final double? rating;
  final String? workStatus;
  final String? myStatus;
  final List<String> tags;
  final DateTime? addedAt;
  final DateTime? updatedAt;
  final String? posterPath;
  final String? entitySubtype;

  List<String> get normalizedTags => tags
      .map(RecordSummaryIndexService._normalizeTag)
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList(growable: false);

  static Future<VaultRecordSummary> fromWorkItem({
    required String vaultPath,
    required AkashaItem item,
    required String absolutePath,
  }) async {
    final stat = await _tryStat(absolutePath);
    return VaultRecordSummary(
      id: item.workId,
      recordKind: RecordKind.workJournal,
      entityType: 'work',
      title: item.title,
      relativePath: RecordSummaryIndexService._relativePath(
        vaultPath,
        absolutePath,
      ),
      category: item.category.name,
      creator: item.creator.isEmpty ? null : item.creator,
      releaseYear: item.releaseYear,
      rating: item.rating,
      workStatus: item.workStatusLabel.isEmpty ? null : item.workStatusLabel,
      myStatus: item.myStatusLabel.isEmpty ? null : item.myStatusLabel,
      tags: List<String>.from(item.tags),
      addedAt: item.addedAt,
      updatedAt: item.recordMetadata.updatedAt ?? stat?.modified.toUtc(),
      posterPath: item.posterPath,
    );
  }

  static Future<VaultRecordSummary> fromEntityEntry({
    required String vaultPath,
    required EntityJournalEntry entry,
  }) async {
    final stat = await _tryStat(entry.storagePath);
    return VaultRecordSummary(
      id: entry.entityId,
      recordKind: RecordKind.entityJournal,
      entityType: entry.entityType.name,
      title: entry.title,
      relativePath: RecordSummaryIndexService._relativePath(
        vaultPath,
        entry.storagePath,
      ),
      tags: List<String>.from(entry.tags),
      addedAt: entry.addedAt,
      updatedAt: entry.recordMetadata.updatedAt ?? stat?.modified.toUtc(),
      posterPath: entry.posterPath,
      entitySubtype: entry.entitySubtype,
    );
  }

  static Future<VaultRecordSummary> fromJournalEntry({
    required String vaultPath,
    required JournalEntry entry,
  }) async {
    final stat = await _tryStat(entry.storagePath);
    return VaultRecordSummary(
      id: entry.recordId,
      recordKind: RecordKind.freeformJournal,
      entityType: 'journal',
      title: entry.title,
      relativePath: RecordSummaryIndexService._relativePath(
        vaultPath,
        entry.storagePath,
      ),
      addedAt: entry.addedAt,
      updatedAt: entry.recordMetadata.updatedAt ?? stat?.modified.toUtc(),
    );
  }

  static Future<VaultRecordSummary> fromTimelineEntry({
    required String vaultPath,
    required TimelineEntry entry,
  }) async {
    final stat = await _tryStat(entry.storagePath);
    return VaultRecordSummary(
      id: entry.recordId,
      recordKind: RecordKind.timelineEntry,
      entityType: 'timeline',
      title: entry.title,
      relativePath: RecordSummaryIndexService._relativePath(
        vaultPath,
        entry.storagePath,
      ),
      addedAt: entry.addedAt,
      updatedAt: entry.recordMetadata.updatedAt ?? stat?.modified.toUtc(),
    );
  }

  static Future<VaultRecordSummary?> fromMarkdownFile({
    required String vaultPath,
    required File file,
  }) async {
    try {
      final content = await file.readAsString();
      final split = _splitFrontmatter(content);
      if (split == null) return null;

      final parsed = loadYaml(split.frontmatter);
      if (parsed is! YamlMap) return null;

      final relativePath = RecordSummaryIndexService._relativePath(
        vaultPath,
        file.path,
      );
      final stat = await _tryStat(file.path);
      final recordKind = _recordKindFromYaml(parsed);
      final id = _recordIdFromYaml(parsed, recordKind, relativePath);
      if (id.isEmpty) return null;

      return VaultRecordSummary(
        id: id,
        recordKind: recordKind,
        entityType: _entityTypeFromYaml(parsed, recordKind),
        title:
            _string(parsed['title']) ?? p.basenameWithoutExtension(file.path),
        relativePath: relativePath,
        category: _string(parsed['category'] ?? parsed['subtype']),
        creator: _string(parsed['creator']),
        releaseYear: _int(parsed['release_year'] ?? parsed['releaseYear']),
        rating: _double(parsed['rating']),
        workStatus: _string(parsed['work_status']),
        myStatus: _string(parsed['my_status'] ?? parsed['status']),
        tags: _tags(parsed['tags']),
        // createdAt-style source keys are system timestamps and must use the UTC instant parser.
        // TODO(UA-113): addedAt semantics are not finalized. added_at/addedAt remain on the legacy parser until the field meaning is split or confirmed.
        addedAt: (parsed['created_at'] ?? parsed['createdAt']) != null
            ? _parseVaultInstantAsUtc(parsed['created_at'] ?? parsed['createdAt'])
            : _legacyAddedAtDate(parsed['added_at'] ?? parsed['addedAt']),
        updatedAt:
            _parseVaultInstantAsUtc(parsed['updated_at'] ?? parsed['updatedAt']) ??
            stat?.modified.toUtc(),
        posterPath: _string(parsed['poster'] ?? parsed['poster_path']),
        entitySubtype: _string(parsed['entity_subtype'] ?? parsed['entitySubtype']),
      );
    } catch (_) {
      return null;
    }
  }

  factory VaultRecordSummary.fromJson(Map<String, dynamic> json) {
    final kindName = json['recordKind']?.toString() ?? '';
    final kind = RecordKind.values.firstWhere(
      (candidate) => candidate.name == kindName,
      orElse: () => RecordKind.workJournal,
    );
    return VaultRecordSummary(
      id: json['id']?.toString() ?? '',
      recordKind: kind,
      entityType: json['entityType']?.toString() ?? 'work',
      title: json['title']?.toString() ?? '',
      relativePath: json['path']?.toString() ?? '',
      category: _jsonString(json['category']),
      creator: _jsonString(json['creator']),
      releaseYear: _int(json['releaseYear']),
      rating: _double(json['rating']),
      workStatus: _jsonString(json['workStatus']),
      myStatus: _jsonString(json['myStatus']),
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      addedAt: _legacyAddedAtDate(json['addedAt']),
      updatedAt: _parseVaultInstantAsUtc(json['updatedAt']),
      posterPath: _jsonString(json['posterPath']),
      entitySubtype: _jsonString(json['entitySubtype']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recordKind': recordKind.name,
    'entityType': entityType,
    'title': title,
    'path': relativePath,
    if (category != null && category!.isNotEmpty) 'category': category,
    if (creator != null && creator!.isNotEmpty) 'creator': creator,
    if (releaseYear != null) 'releaseYear': releaseYear,
    if (rating != null) 'rating': rating,
    if (workStatus != null && workStatus!.isNotEmpty) 'workStatus': workStatus,
    if (myStatus != null && myStatus!.isNotEmpty) 'myStatus': myStatus,
    if (tags.isNotEmpty) 'tags': tags,
    if (addedAt != null) 'addedAt': addedAt!.toUtc().toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    if (posterPath != null && posterPath!.isNotEmpty) 'posterPath': posterPath,
    if (entitySubtype != null && entitySubtype!.isNotEmpty)
      'entitySubtype': entitySubtype,
  };
}
