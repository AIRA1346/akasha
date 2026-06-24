import 'enums.dart';

/// 나만의 서재 표시·큐레이션 모드
enum PersonalLibraryMode {
  /// 볼트 전체 + 필터 (master_archive · 레거시 커스텀)
  filter,

  /// explicit 멤버십 + 필터 + scoped fusion
  curated,
}

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
  PersonalLibraryMode mode;
  List<String> memberOrder;
  AppDomain? domain;
  Set<MediaCategory> categories;
  Set<String> workStatuses;
  Set<String> myStatuses;
  List<String> inclusionRules;

  PersonalLibraryConfig({
    required this.id,
    required this.name,
    PersonalLibraryMode? mode,
    List<String>? memberOrder,
    this.domain,
    Set<MediaCategory>? categories,
    Set<String>? workStatuses,
    Set<String>? myStatuses,
    List<String>? inclusionRules,
  })  : mode = mode ??
            (id == masterArchiveId
                ? PersonalLibraryMode.filter
                : PersonalLibraryMode.filter),
        memberOrder = normalizeMemberOrder(memberOrder ?? const []),
        categories = categories ?? {},
        workStatuses = workStatuses ?? {},
        myStatuses = myStatuses ?? {},
        inclusionRules = inclusionRules ?? const ['archived'];

  bool get isMasterArchive => id == masterArchiveId;

  bool get isCurated => mode == PersonalLibraryMode.curated;

  bool get isFilterMode => mode == PersonalLibraryMode.filter;

  /// 파생 — 저장하지 않음 (API·테스트 편의)
  Set<String> get memberWorkIds => memberOrder.toSet();

  static List<String> normalizeMemberOrder(List<String> order) {
    final seen = <String>{};
    final result = <String>[];
    for (final id in order) {
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      result.add(id);
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.name,
        'memberOrder': memberOrder,
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

    PersonalLibraryMode parsedMode = PersonalLibraryMode.filter;
    if (json['mode'] == PersonalLibraryMode.curated.name) {
      parsedMode = PersonalLibraryMode.curated;
    }

    var order = List<String>.from(json['memberOrder'] ?? const []);
    if (order.isEmpty && json['memberWorkIds'] != null) {
      order = List<String>.from(json['memberWorkIds'] as List);
    }

    final rules = List<String>.from(json['inclusionRules'] ?? const ['archived']);
    final normalizedRules = rules
        .map((r) => r == 'vault_md' ? 'archived' : r)
        .toList();

    return PersonalLibraryConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: parsedMode,
      memberOrder: order,
      domain: parsedDomain,
      categories: parsedCategories,
      workStatuses: Set<String>.from(json['workStatuses'] ?? []),
      myStatuses: Set<String>.from(json['myStatuses'] ?? []),
      inclusionRules: normalizedRules,
    );
  }

  PersonalLibraryConfig copyWith({
    String? id,
    String? name,
    PersonalLibraryMode? mode,
    List<String>? memberOrder,
    AppDomain? domain,
    Set<MediaCategory>? categories,
    Set<String>? workStatuses,
    Set<String>? myStatuses,
    List<String>? inclusionRules,
  }) {
    return PersonalLibraryConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      memberOrder: memberOrder ?? List.from(this.memberOrder),
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
        mode: PersonalLibraryMode.filter,
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
                mode: PersonalLibraryMode.filter,
              )
            : masterArchive());

    master.mode = PersonalLibraryMode.filter;
    master.domain = null;

    for (final lib in custom) {
      lib.domain = null;
    }

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
