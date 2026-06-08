import 'package:flutter_test/flutter_test.dart';

import '../tool/registry_hash_utils.dart';
import '../tool/wk_id_utils.dart';

void main() {
  group('shardIndexForWorkId', () {
    test('is deterministic for wk_', () {
      const id = 'wk_000000363';
      expect(shardIndexForWorkId(id), shardIndexForWorkId(id));
    });

    test('shardHexForWorkId is 2-char lowercase hex', () {
      final hex = shardHexForWorkId('wk_000000001');
      expect(hex.length, 2);
      expect(v4ShardHexPattern.hasMatch(hex), isTrue);
    });

    test('formatWkId round-trips through hash bucket', () {
      final id = formatWkId(42);
      expect(shardHexForWorkId(id), isNotEmpty);
    });
  });

  group('v4 paths', () {
    test('v4ShardPath matches manifest convention', () {
      expect(v4ShardPath('manga', 'a3'), 'shards/manga/a3.json');
      expect(v4ShardId('manga', 'a3'), 'manga_a3');
    });
  });
}
