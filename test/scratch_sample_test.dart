import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/sample_data.dart';

void main() {
  test('Verify buildSampleData poster paths', () {
    final items = buildSampleData();
    for (final item in items) {
      print('${item.title}: posterPath = ${item.posterPath}');
    }
  });
}
