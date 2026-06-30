import 'dart:io';

import 'package:akasha/services/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Agent vault slice fixtures', () {
    test('create fixture parses minimal agent record', () async {
      final content =
          await File('test/fixtures/vault_agent_slice_create.md').readAsString();
      final item = MarkdownParser.deserialize(content, 'slice.md');

      expect(item.workId, 'wk_u_agnt0001');
      expect(item.title, 'Agent Slice 테스트 애니');
      expect(item.rating, 0);
      expect(item.tags, isEmpty);
      expect(item.review, contains('A1 create'));
    });

    test('full fixture parses rating status tags and appended memo', () async {
      final content =
          await File('test/fixtures/vault_agent_slice_full.md').readAsString();
      final item = MarkdownParser.deserialize(content, 'slice.md');

      expect(item.rating, 4.5);
      expect(item.myStatusLabel, '전부 봄');
      expect(item.tags, containsAll(['재미있음', '감동']));
      expect(item.review, contains('2화부터 몰입'));
      expect(item.review, contains('마지막 장면'));
    });
  });
}
