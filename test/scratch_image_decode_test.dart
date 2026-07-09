import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Print first 15 bytes of cached poster files', () async {
    final paths = [
      r'C:\Users\rkdwl\OneDrive\문서\posters\shigatsu_2011_934735596.jpg',
      r'C:\Users\rkdwl\OneDrive\문서\posters\conan_manga_1827421.jpg',
    ];
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final prefix = bytes.take(15).toList();
        debugPrint('$path: Hex prefix = $prefix');
        // Check if it looks like HTML
        final text = String.fromCharCodes(bytes.take(100));
        debugPrint('Text snippet: $text');
      } else {
        debugPrint('$path does not exist!');
      }
    }
  });
}
