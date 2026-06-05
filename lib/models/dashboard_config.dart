import '../models/enums.dart';

/// 사용자가 직접 구성하는 맞춤형 대시보드 설정 모델
class DashboardConfig {
  final String id;
  String name;
  AppDomain? domain;
  Set<MediaCategory> categories; // 변경: MediaCategory? category -> Set<MediaCategory> categories
  Set<String> myStatuses;
  Set<String> workStatuses;

  DashboardConfig({
    required this.id,
    required this.name,
    this.domain,
    Set<MediaCategory>? categories,
    Set<String>? myStatuses,
    Set<String>? workStatuses,
  })  : categories = categories ?? {},
        myStatuses = myStatuses ?? {},
        workStatuses = workStatuses ?? {};

  /// SharedPreferences 저장 및 직렬화를 위한 JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'domain': domain?.name,
      'categories': categories.map((e) => e.name).toList(), // 다중 카테고리 직렬화
      'myStatuses': myStatuses.toList(),
      'workStatuses': workStatuses.toList(),
    };
  }

  /// JSON 역직렬화 팩토리
  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    AppDomain? parsedDomain;
    if (json['domain'] != null) {
      try {
        parsedDomain = AppDomain.values.firstWhere((e) => e.name == json['domain']);
      } catch (_) {
        parsedDomain = null;
      }
    }

    final Set<MediaCategory> parsedCategories = {};
    
    // ── 하위 호환성 (Migration) 처리 ──
    // 1. 새로운 다중 categories 속성이 존재하는 경우
    if (json['categories'] != null) {
      final List<dynamic> catList = json['categories'] as List<dynamic>;
      for (final catName in catList) {
        try {
          final cat = MediaCategory.values.firstWhere((e) => e.name == catName);
          parsedCategories.add(cat);
        } catch (_) {}
      }
    } 
    // 2. 구버전 단일 category 속성만 존재하는 경우 (하위 호환 마이그레이션)
    else if (json['category'] != null) {
      try {
        final cat = MediaCategory.values.firstWhere((e) => e.name == json['category']);
        parsedCategories.add(cat);
      } catch (_) {}
    }

    return DashboardConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      domain: parsedDomain,
      categories: parsedCategories,
      myStatuses: Set<String>.from(json['myStatuses'] ?? []),
      workStatuses: Set<String>.from(json['workStatuses'] ?? []),
    );
  }

  /// 설정 복제 지원
  DashboardConfig copyWith({
    String? name,
    AppDomain? domain,
    Set<MediaCategory>? categories,
    Set<String>? myStatuses,
    Set<String>? workStatuses,
  }) {
    return DashboardConfig(
      id: id,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      categories: categories ?? Set.from(this.categories),
      myStatuses: myStatuses ?? Set.from(this.myStatuses),
      workStatuses: workStatuses ?? Set.from(this.workStatuses),
    );
  }
}
