import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assets bundle contains every manifest shard', () {
    final manifest =
        jsonDecode(File('assets/registry/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final shards = (manifest['shards'] as List).whereType<Map>().toList();
    final expectedPaths = {
      for (final shard in shards) shard['path']?.toString(),
    }..remove(null);
    final actualPaths = <String>{};
    final root = Directory('assets/registry');
    for (final file in Directory(
      'assets/registry/shards',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      actualPaths.add(
        file.path
            .substring(root.path.length + 1)
            .replaceAll(Platform.pathSeparator, '/'),
      );
    }

    expect(manifest['bundleMode'], 'full');
    expect(expectedPaths.length, 1713);
    expect(actualPaths, expectedPaths);
  });
}
