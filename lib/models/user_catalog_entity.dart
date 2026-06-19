import 'enums.dart';
import 'registry_work.dart';
import 'work_titles.dart';
import 'akasha_item.dart';
import '../utils/work_title_resolver.dart';

/// Tier 1.5 — user local catalog Fact ([user-local-catalog-policy.md]).
class UserCatalogEntity {
  static const String entityTypeWork = 'work';
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
    required this.addedAt,
  });

  factory UserCatalogEntity.fromAkashaItem(AkashaItem item) {
    return UserCatalogEntity(
      entityId: item.workId,
      subtype: item.category,
      title: item.title,
      titles: inferTitlesFromLegacyTitle(item.title),
      creator: item.creator,
      releaseYear: item.releaseYear,
      domain: item.domain,
      addedAt: item.addedAt,
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
      addedAt: DateTime.tryParse(json['addedAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'entityId': entityId,
        'entityType': entityType,
        'subtype': subtype.name,
        'title': title,
        'titles': titles.toJson(),
        'creator': creator,
        if (releaseYear != null) 'releaseYear': releaseYear,
        'domain': domain.name,
        'aliases': aliases,
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
      extensions: const {'userLocalCatalog': true},
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
    for (final token in toRegistryWork().searchTokens) {
      if (token.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}
