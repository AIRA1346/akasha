import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/work_id_codec.dart';

void main() {
  group('wk ID format', () {
    test('WorkIdCodec recognizes wk_ format', () {
      expect(WorkIdCodec.isWkFormat('wk_00000001'), isTrue);
      expect(WorkIdCodec.isWkFormat('wk_00000410'), isTrue);
      expect(WorkIdCodec.isWkFormat('wk_123'), isFalse);
      expect(WorkIdCodec.isMasterFormat('wk_00000001'), isTrue);
    });

    test('WorkIdCodec.parse handles wk_', () {
      final parsed = WorkIdCodec.parse('wk_00000042');
      expect(parsed, isNotNull);
      expect(parsed!.raw, 'wk_00000042');
    });
  });
}
