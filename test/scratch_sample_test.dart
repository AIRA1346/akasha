import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/sample_data.dart';

void main() {
  test('Verify buildSampleData poster paths', () {
    final items = buildSampleData();
    for (final item in items) {
      debugPrint('${item.title}: posterPath = ${item.posterPath}');
    }
  });
}
