import 'enums.dart';

/// 나만의 서재 — 사용자 큐레이션 뷰 설정 (아카이브 + 필터 프리셋)
class PersonalLibraryConfig {
  static const presetIds = <String>{
    'archive_manga',
    'archive_anime',
    'archive_game',
    'archive_book',
    'archive_movie',
    'archive_drama',
    'archive_all',
  };

  final String id;
  String name;
  AppDomain? domain;
  Set<MediaCategory> categories;
  Set<String> workStatuses;
  Set<String> myStatuses;
  List<String> inclusionRules;

  PersonalLibraryConfig({
    required this.id,
    required this.name,
    this.domain,
    Set<MediaCategory>? categories,
    Set<String>? workStatuses,
    Set<String>? myStatuses,
    List<String>? inclusionRules,
  })  : categories = categories ?? {},
        workStatuses = workStatuses ?? {},
        myStatuses = myStatuses ?? {},
        inclusionRules = inclusionRules ?? const ['archived'];

  bool get isPreset => presetIds.contains(id);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'domain': domain?.name,
        'categories': categories.map((e) => e.name).toList(),
        'workStatuses': workStatuses.toList(),
        'myStatuses': myStatuses.toList(),
        'inclusionRules': inclusionRules,
      };

  factory PersonalLibraryConfig.fromJson(Map<String, dynamic> json) {
    AppDomain? parsedDomain;
    if (json['domain'] != null) {
      try {
        parsedDomain = AppDomain.values.firstWhere(
          (e) => e.name == json['domain'],
        );
      } catch (_) {
        parsedDomain = null;
      }
    }

    final parsedCategories = <MediaCategory>{};
    if (json['categories'] != null) {
      for (final catName in json['categories'] as List<dynamic>) {
        try {
          parsedCategories.add(
            MediaCategory.values.firstWhere((e) => e.name == catName),
          );
        } catch (_) {}
      }
    }

    return PersonalLibraryConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      domain: parsedDomain,
      categories: parsedCategories,
      workStatuses: Set<String>.from(json['workStatuses'] ?? []),
      myStatuses: Set<String>.from(json['myStatuses'] ?? []),
      inclusionRules: List<String>.from(
        json['inclusionRules'] ?? const ['archived'],
      ),
    );
  }

  PersonalLibraryConfig copyWith({
    String? name,
    AppDomain? domain,
    Set<MediaCategory>? categories,
    Set<String>? workStatuses,
    Set<String>? myStatuses,
    List<String>? inclusionRules,
  }) {
    return PersonalLibraryConfig(
      id: id,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      categories: categories ?? Set.from(this.categories),
      workStatuses: workStatuses ?? Set.from(this.workStatuses),
      myStatuses: myStatuses ?? Set.from(this.myStatuses),
      inclusionRules: inclusionRules ?? List.from(this.inclusionRules),
    );
  }

  static List<PersonalLibraryConfig> defaultLibraries() => [
        PersonalLibraryConfig(
          id: 'archive_manga',
          name: '내 만화 아카이브',
          categories: {MediaCategory.manga},
        ),
        PersonalLibraryConfig(
          id: 'archive_anime',
          name: '내 애니 아카이브',
          categories: {MediaCategory.animation},
        ),
        PersonalLibraryConfig(
          id: 'archive_game',
          name: '내 게임 아카이브',
          categories: {MediaCategory.game},
        ),
        PersonalLibraryConfig(
          id: 'archive_book',
          name: '내 책·라노벨 아카이브',
          categories: {MediaCategory.book},
        ),
        PersonalLibraryConfig(
          id: 'archive_movie',
          name: '내 영화 아카이브',
          categories: {MediaCategory.movie},
        ),
        PersonalLibraryConfig(
          id: 'archive_drama',
          name: '내 드라마 아카이브',
          categories: {MediaCategory.drama},
        ),
        PersonalLibraryConfig(
          id: 'archive_all',
          name: '내 전체 아카이브',
        ),
      ];
}
