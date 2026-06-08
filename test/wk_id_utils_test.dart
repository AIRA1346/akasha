import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/work_id_codec.dart';

import '../tool/wk_id_utils.dart';

void main() {
  group('wk_id_utils', () {
    test('formatWkId pads to 9 digits', () {
      expect(formatWkId(1), 'wk_000000001');
      expect(formatWkId(402), 'wk_000000402');
      expect(formatWkId(999999999), 'wk_999999999');
    });

    test('isWkId rejects legacy 8-digit', () {
      expect(isWkId('wk_00000001'), isFalse);
      expect(isWkIdLegacy8('wk_00000001'), isTrue);
    });

    test('canonicalizeWkId upgrades 8 to 9 digits', () {
      expect(canonicalizeWkId('wk_00000402'), 'wk_000000402');
    });
  });

  group('wk ID format (codec)', () {
    test('WorkIdCodec recognizes wk_ format', () {
      expect(WorkIdCodec.isWkFormat('wk_000000001'), isTrue);
      expect(WorkIdCodec.isWkFormat('wk_000000402'), isTrue);
      expect(WorkIdCodec.isWkFormat('wk_00000001'), isFalse);
      expect(WorkIdCodec.isWkFormat('wk_123'), isFalse);
      expect(WorkIdCodec.isMasterFormat('wk_000000001'), isTrue);
    });

    test('WorkIdCodec.parse handles wk_', () {
      final parsed = WorkIdCodec.parse('wk_000000042');
      expect(parsed, isNotNull);
      expect(parsed!.raw, 'wk_000000042');
    });
  });
}
