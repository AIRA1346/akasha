import '../core/archiving/entity_anchor.dart';
import 'enums.dart';
import 'registry_work.dart';
import 'work_titles.dart';
import 'akasha_item.dart';
import '../utils/work_title_resolver.dart';
import '../widgets/editable_tag_chips.dart';
import '../utils/entity_tag_semantics.dart';

/// Tier 1.5 — user local catalog Fact ([user-local-catalog-policy.md]).
class UserCatalogEntity {
  static const String entityTypeWork = 'work';
  static const String entityTypePerson = 'person';
  static const String entityTypeEvent = 'event';
  static const String entityTypeConcept = 'concept';
  static const String entityTypePlace = 'place';
  static const String entityTypeOrganization = 'organization';
  static const String entityTypeCustom = 'custom';
  static const String catalogSourceUser = 'user';

  final String entityId;
  final String entityType;
  final MediaCategory subtype;
  final String title;
  final WorkTitles titles;
  final String creator;
  final int? releaseYear;
  final AppDomain domain;
  final List<String> aliases;
  final List<String> tags;
  final DateTime addedAt;

  const UserCatalogEntity({
    required this.entityId,
    this.entityType = entityTypeWork,
    required this.subtype,
    required this.title,
    this.titles = const WorkTitles(),
    this.creator = '',
    this.releaseYear,
    this.domain = AppDomain.subculture,
    this.aliases = const [],
    this.tags = const [],
    required this.addedAt,
  });

  bool get isWorkEntity => entityType == entityTypeWork;

  EntityAnchorType get anchorType {
    for (final type in EntityAnchorType.values) {
      if (type.name == entityType) return type;
    }
    return EntityAnchorType.custom;
  }

  factory UserCatalogEntity.fromAkashaItem(AkashaItem item) {
    return UserCatalogEntity(
      entityId: item.workId,
      subtype: item.category,
      title: item.title,
      titles: inferTitlesFromLegacyTitle(item.title),
      creator: item.creator,
      releaseYear: item.releaseYear,
      domain: item.domain,
      tags: List<String>.from(item.tags),
      addedAt: item.addedAt,
    );
  }

  factory UserCatalogEntity.userLocal({
    required String entityId,
    required EntityAnchorType type,
    required String title,
    MediaCategory? subtype,
    List<String> aliases = const [],
    List<String> tags = const [],
    DateTime? addedAt,
  }) {
    return UserCatalogEntity(
      entityId: entityId,
      entityType: type.name,
      subtype: subtype ?? MediaCategory.manga,
      title: title,
      aliases: aliases,
      tags: tags,
      addedAt: addedAt ?? DateTime.now().toUtc(),
    );
  }

  UserCatalogEntity copyWith({
    String? entityId,
    String? entityType,
    MediaCategory? subtype,
    String? title,
    WorkTitles? titles,
    String? creator,
    int? releaseYear,
    AppDomain? domain,
    List<String>? aliases,
    List<String>? tags,
    DateTime? addedAt,
  }) {
    return UserCatalogEntity(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      subtype: subtype ?? this.subtype,
      title: title ?? this.title,
      titles: titles ?? this.titles,
      creator: creator ?? this.creator,
      releaseYear: releaseYear ?? this.releaseYear,
      domain: domain ?? this.domain,
      aliases: aliases ?? this.aliases,
      tags: tags ?? this.tags,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  factory UserCatalogEntity.fromJson(Map<String, dynamic> json) {
    final subtypeStr = json['subtype']?.toString() ??
        json['category']?.toString() ??
        'manga';
    final subtype = MediaCategory.values.firstWhere(
      (e) => e.name == subtypeStr,
      orElse: () => MediaCategory.manga,
    );
    final domainStr = json['domain']?.toString() ?? 'subculture';
    final domain = AppDomain.values.firstWhere(
      (e) => e.name == domainStr,
      orElse: () => AppDomain.subculture,
    );

    return UserCatalogEntity(
      entityId: json['entityId']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? entityTypeWork,
      subtype: subtype,
      title: json['title']?.toString() ?? '',
      titles: WorkTitles.fromJson(json['titles']),
      creator: json['creator']?.toString() ?? '',
      releaseYear: int.tryParse(json['releaseYear']?.toString() ?? ''),
      domain: domain,
      aliases: (json['aliases'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      tags: parseTagList(
        (json['tags'] as List?)?.map((e) => e.toString()) ?? const [],
      ),
      addedAt: DateTime.tryParse(json['addedAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'entityId': entityId,
        'entityType': entityType,
        if (isWorkEntity) 'subtype': subtype.name,
        if (!isWorkEntity && subtype != MediaCategory.manga)
          'subtype': subtype.name,
        'title': title,
        'titles': titles.toJson(),
        'creator': creator,
        if (releaseYear != null) 'releaseYear': releaseYear,
        'domain': domain.name,
        'aliases': aliases,
        'tags': tags,
        'addedAt': addedAt.toUtc().toIso8601String(),
        'source': catalogSourceUser,
      };

  RegistryWork toRegistryWork() {
    return RegistryWork(
      workId: entityId,
      title: title,
      titles: titles.isEmpty && title.isNotEmpty
          ? inferTitlesFromLegacyTitle(title)
          : titles,
      aliases: aliases,
      category: subtype,
      domain: domain,
      creator: creator,
      releaseYear: releaseYear,
      tags: tags,
      extensions: {
        'userLocalCatalog': true,
        'entityType': entityType,
      },
    );
  }

  bool matchesQuery(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return false;
    final q = normalizedQuery.toLowerCase();
    if (title.toLowerCase().contains(q)) return true;
    if (creator.toLowerCase().contains(q)) return true;
    for (final alias in aliases) {
      if (alias.toLowerCase().contains(q)) return true;
    }
    for (final tag in tags) {
      if (tag.toLowerCase().contains(q)) return true;
    }
    for (final token in toRegistryWork().searchTokens) {
      if (token.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  /// Collection filter — exact tag match (AND). Search uses [matchesQuery] substring.
  bool matchesTagsAll(List<String> requiredTags) =>
      EntityTagSemantics.matchesTagsAll(tags, requiredTags);
}
