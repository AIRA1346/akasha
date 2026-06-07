import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/category_descriptor.dart';
import 'package:akasha/models/enums.dart';

void main() {
  test('CategoryRegistry provides labels and content type flags', () {
    expect(CategoryRegistry.shortLabel(MediaCategory.manga), '만화');
    expect(CategoryRegistry.shortLabel(MediaCategory.game), '게임');
    expect(CategoryRegistry.isContentType(MediaCategory.game), isFalse);
    expect(CategoryRegistry.isContentType(MediaCategory.animation), isTrue);
    expect(
      CategoryRegistry.chipSortOrder(MediaCategory.book),
      lessThan(CategoryRegistry.chipSortOrder(MediaCategory.game)),
    );
    expect(MediaCategory.book.isContentType, isTrue);
  });
}
