import 'enums.dart';

/// 매체 카테고리 메타데이터 단일 등록소 — 라벨·정렬·타입 판별
class CategoryDescriptor {
  final MediaCategory category;
  final String shortLabel;
  final int chipSortOrder;
  final bool isContentType;

  const CategoryDescriptor({
    required this.category,
    required this.shortLabel,
    required this.chipSortOrder,
    required this.isContentType,
  });
}

class CategoryRegistry {
  CategoryRegistry._();

  static const Map<MediaCategory, CategoryDescriptor> _byCategory = {
    MediaCategory.manga: CategoryDescriptor(
      category: MediaCategory.manga,
      shortLabel: '만화',
      chipSortOrder: 0,
      isContentType: true,
    ),
    MediaCategory.webtoon: CategoryDescriptor(
      category: MediaCategory.webtoon,
      shortLabel: '웹툰',
      chipSortOrder: 1,
      isContentType: true,
    ),
    MediaCategory.animation: CategoryDescriptor(
      category: MediaCategory.animation,
      shortLabel: '애니',
      chipSortOrder: 2,
      isContentType: true,
    ),
    MediaCategory.book: CategoryDescriptor(
      category: MediaCategory.book,
      shortLabel: '라노벨',
      chipSortOrder: 3,
      isContentType: true,
    ),
    MediaCategory.game: CategoryDescriptor(
      category: MediaCategory.game,
      shortLabel: '게임',
      chipSortOrder: 4,
      isContentType: false,
    ),
    MediaCategory.movie: CategoryDescriptor(
      category: MediaCategory.movie,
      shortLabel: '영화',
      chipSortOrder: 5,
      isContentType: true,
    ),
    MediaCategory.drama: CategoryDescriptor(
      category: MediaCategory.drama,
      shortLabel: '드라마',
      chipSortOrder: 6,
      isContentType: true,
    ),
  };

  static CategoryDescriptor descriptorFor(MediaCategory category) {
    return _byCategory[category] ??
        CategoryDescriptor(
          category: category,
          shortLabel: category.label,
          chipSortOrder: 99,
          isContentType: category != MediaCategory.game,
        );
  }

  static String shortLabel(MediaCategory category) =>
      descriptorFor(category).shortLabel;

  static int chipSortOrder(MediaCategory category) =>
      descriptorFor(category).chipSortOrder;

  static bool isContentType(MediaCategory category) =>
      descriptorFor(category).isContentType;

  static List<CategoryDescriptor> get all => _byCategory.values.toList();
}
