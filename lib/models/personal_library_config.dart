import 'enums.dart';

/// 나만의 서재 — 사용자 큐레이션 뷰 설정 (아카이브 + 필터)
class PersonalLibraryConfig {
  /// 대시보드 `master_index`와 대응하는 기본 서재 (삭제·이름 변경 불가)
  static const masterArchiveId = 'master_archive';

  /// v1 프리셋 — 로드 시 제거·`master_archive`로 흡수
  static const legacyPresetIds = <String>{
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

  bool get isMasterArchive => id == masterArchiveId;

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
    String? id,
    String? name,
    AppDomain? domain,
    Set<MediaCategory>? categories,
    Set<String>? workStatuses,
    Set<String>? myStatuses,
    List<String>? inclusionRules,
  }) {
    return PersonalLibraryConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      categories: categories ?? Set.from(this.categories),
      workStatuses: workStatuses ?? Set.from(this.workStatuses),
      myStatuses: myStatuses ?? Set.from(this.myStatuses),
      inclusionRules: inclusionRules ?? List.from(this.inclusionRules),
    );
  }

  static PersonalLibraryConfig masterArchive() => PersonalLibraryConfig(
        id: masterArchiveId,
        name: masterArchiveId,
      );

  static List<PersonalLibraryConfig> defaultLibraries() => [masterArchive()];

  /// 저장된 목록에서 레거시 프리셋 제거 + `master_archive` 보장
  static List<PersonalLibraryConfig> normalizeLibraries(
    List<PersonalLibraryConfig> input,
  ) {
    PersonalLibraryConfig? existingMaster;
    PersonalLibraryConfig? legacyAll;
    final custom = <PersonalLibraryConfig>[];

    for (final lib in input) {
      if (lib.id == masterArchiveId) {
        existingMaster = lib;
      } else if (lib.id == 'archive_all') {
        legacyAll = lib;
      } else if (legacyPresetIds.contains(lib.id)) {
        continue;
      } else {
        custom.add(lib);
      }
    }

    final master = existingMaster ??
        (legacyAll != null
            ? legacyAll.copyWith(
                id: masterArchiveId,
                name: masterArchiveId,
              )
            : masterArchive());

    custom.sort((a, b) => a.name.compareTo(b.name));
    return [master, ...custom];
  }

  static String? migrateActiveId(String? activeId, List<PersonalLibraryConfig> libs) {
    if (activeId != null && libs.any((l) => l.id == activeId)) {
      return activeId;
    }
    if (activeId != null && legacyPresetIds.contains(activeId)) {
      return masterArchiveId;
    }
    return libs.isEmpty ? null : libs.first.id;
  }
}
