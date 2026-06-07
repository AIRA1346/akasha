import 'category_descriptor.dart';
import 'enums.dart';

enum FormatSlotState { tracked, catalogOnly, hidden }

/// 프랜차이즈 카드에 표시할 매체 슬롯
class FormatSlot {
  final String workId;
  final MediaCategory category;
  final String shortLabel;
  final int? releaseYear;
  final FormatSlotState state;
  final bool dimmedByFilter;

  const FormatSlot({
    required this.workId,
    required this.category,
    required this.shortLabel,
    this.releaseYear,
    required this.state,
    this.dimmedByFilter = false,
  });

  FormatSlot copyWith({String? shortLabel, FormatSlotState? state}) {
    return FormatSlot(
      workId: workId,
      category: category,
      shortLabel: shortLabel ?? this.shortLabel,
      releaseYear: releaseYear,
      state: state ?? this.state,
      dimmedByFilter: dimmedByFilter,
    );
  }
}

String shortCategoryLabel(MediaCategory category) =>
    CategoryRegistry.shortLabel(category);

int categorySortOrder(MediaCategory category) =>
    CategoryRegistry.chipSortOrder(category);
