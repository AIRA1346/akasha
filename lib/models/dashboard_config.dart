import '../models/enums.dart';

/// 사용자가 직접 구성하는 맞춤형 대시보드 설정 모델
class DashboardConfig {
  final String id;
  String name;
  Set<MediaCategory> categories;
  Set<String> myStatuses;
  Set<String> workStatuses;

  DashboardConfig({
    required this.id,
    required this.name,
    Set<MediaCategory>? categories,
    Set<String>? myStatuses,
    Set<String>? workStatuses,
  })  : categories = categories ?? {},
        myStatuses = myStatuses ?? {},
        workStatuses = workStatuses ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categories': categories.map((e) => e.name).toList(),
      'myStatuses': myStatuses.toList(),
      'workStatuses': workStatuses.toList(),
    };
  }

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    final Set<MediaCategory> parsedCategories = {};

    if (json['categories'] != null) {
      final List<dynamic> catList = json['categories'] as List<dynamic>;
      for (final catName in catList) {
        try {
          final cat = MediaCategory.values.firstWhere((e) => e.name == catName);
          parsedCategories.add(cat);
        } catch (_) {}
      }
    } else if (json['category'] != null) {
      try {
        final cat = MediaCategory.values.firstWhere(
          (e) => e.name == json['category'],
        );
        parsedCategories.add(cat);
      } catch (_) {}
    }

    return DashboardConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      categories: parsedCategories,
      myStatuses: Set<String>.from(json['myStatuses'] ?? []),
      workStatuses: Set<String>.from(json['workStatuses'] ?? []),
    );
  }

  DashboardConfig copyWith({
    String? name,
    Set<MediaCategory>? categories,
    Set<String>? myStatuses,
    Set<String>? workStatuses,
  }) {
    return DashboardConfig(
      id: id,
      name: name ?? this.name,
      categories: categories ?? Set.from(this.categories),
      myStatuses: myStatuses ?? Set.from(this.myStatuses),
      workStatuses: workStatuses ?? Set.from(this.workStatuses),
    );
  }
}
