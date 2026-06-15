import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/widgets/editable_tag_chips.dart';

void main() {
  test('parseTagList splits comma and dedupes', () {
    expect(
      parseTagList(['판타지, 액션', '액션', ' SF ']),
      ['판타지', '액션', 'SF'],
    );
  });
}
