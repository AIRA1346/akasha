import '../config/catalog_locale.dart';
import '../models/enums.dart';
import '../models/external_ids.dart';
import '../utils/work_title_resolver.dart';
import 'work_titles.dart';

/// 글로벌 작품 사전 엔트리 (Tier 1 — akasha-db v4).
///
/// 사용자 볼트 [AkashaItem.title]과 별개. UI 카탈로그 표시는
/// [displayTitle] 또는 [resolveCatalogDisplayTitle]로 로케일별 resolve.
class RegistryWork {
  final String workId;
  /// 레거시 단일 제목 — 하위 호환·정렬 키 (v3: `titles`와 동기화 권장)
  final String title;
  final WorkTitles titles;
  final List<String> aliases;
  final ExternalIds externalIds;
  final MediaCategory category;
  final AppDomain domain;
  final String creator;
  final int? releaseYear;
  final String description;
  final List<String> tags;
  final String? posterPath;
  final Map<String, dynamic> extensions;

  const RegistryWork({
    required this.workId,
    required this.title,
    this.titles = const WorkTitles(),
    this.aliases = const [],
    this.externalIds = const ExternalIds(),
    required this.category,
    required this.domain,
    this.creator = '',
    this.releaseYear,
    this.description = '',
    this.tags = const [],
    this.posterPath,
    this.extensions = const {},
  });

  /// UI·카드용 로케일 제목 (사용자 볼트 `AkashaItem.title`과 별개)
  String displayTitle([CatalogLocale? locale]) {
    return resolveWorkDisplayTitle(
      legacyTitle: title,
      titles: titles,
      locale: locale ?? CatalogLocaleScope.current,
    );
  }

  List<String> get searchTokens => buildWorkSearchTokens(
        legacyTitle: title,
        titles: titles,
        aliases: aliases,
        creator: creator,
        tags: tags,
      );

  factory RegistryWork.fromJson(Map<String, dynamic> json) {
    final workId = json['workId']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';

    final categoryStr = json['category']?.toString() ?? 'manga';
    final category = MediaCategory.values.firstWhere(
      (e) => e.name == categoryStr,
      orElse: () => MediaCategory.manga,
    );

    final domainStr = json['domain']?.toString() ?? 'subculture';
    final domain = AppDomain.values.firstWhere(
      (e) => e.name == domainStr,
      orElse: () => AppDomain.subculture,
    );

    final extensions = <String, dynamic>{};
    final rawExtensions = json['extensions'];
    if (rawExtensions is Map) {
      rawExtensions.forEach((key, value) {
        if (key != null) extensions[key.toString()] = value;
      });
    }

    var titles = WorkTitles.fromJson(json['titles']);
    if (titles.isEmpty && title.isNotEmpty) {
      titles = inferTitlesFromLegacyTitle(title);
    }

    final aliases = (json['aliases'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final explicitIds = ExternalIds.fromJson(json['externalIds']);
    final externalIds = ExternalIds.mergeFromExtensions(
      extensions,
      explicit: explicitIds,
    );

    return RegistryWork(
      workId: workId,
      title: title,
      titles: titles,
      aliases: aliases,
      externalIds: externalIds,
      category: category,
      domain: domain,
      creator: json['creator']?.toString() ?? '',
      releaseYear: int.tryParse(json['releaseYear']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      posterPath: json['posterPath']?.toString(),
      extensions: extensions,
    );
  }
}
