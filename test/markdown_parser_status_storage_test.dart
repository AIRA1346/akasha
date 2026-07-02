import 'package:akasha/models/enums.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarkdownParser status storage', () {
    test('serializes content statuses as locale-independent enum names', () {
      final item = createItem(
        workId: 'wk_u_status_content',
        title: 'Status Content',
        category: MediaCategory.manga,
        workStatus: ContentWorkStatus.completed.label,
        myStatus: ContentMyStatus.finished.label,
      );

      final serialized = MarkdownParser.serialize(item);

      expect(serialized, contains('work_status: "completed"'));
      expect(serialized, contains('status: "finished"'));
      expect(serialized, contains('my_status: "finished"'));
      expect(serialized, isNot(contains('work_status: "Completed"')));
      expect(serialized, isNot(contains('my_status: "Finished"')));
    });

    test('serializes game statuses as locale-independent enum names', () {
      final item = createItem(
        workId: 'wk_u_status_game',
        title: 'Status Game',
        category: MediaCategory.game,
        workStatus: GameWorkStatus.earlyAccess.label,
        myStatus: GameMyStatus.playing.label,
      );

      final serialized = MarkdownParser.serialize(item);

      expect(serialized, contains('work_status: "earlyAccess"'));
      expect(serialized, contains('status: "playing"'));
      expect(serialized, contains('my_status: "playing"'));
      expect(serialized, isNot(contains('work_status: "Early Access"')));
      expect(serialized, isNot(contains('my_status: "Playing"')));
    });

    test('deserializes legacy Korean content status labels', () {
      const markdown = '''
---
work_id: "wk_u_legacy_content_status"
title: "Legacy Content Status"
category: manga
domain: subculture
poster: ""
rating: 4.0
work_status: "\uC644\uACB0"
status: "\uC804\uBD80 \uBD04"
my_status: "\uC804\uBD80 \uBD04"
is_hall_of_fame: false
tags: []
added_at: "2026-01-01T00:00:00.000"
---
''';

      final item = MarkdownParser.deserialize(markdown, 'fallback');

      expect(item.workStatusLabel, ContentWorkStatus.completed.label);
      expect(item.myStatusLabel, ContentMyStatus.finished.label);
    });
  });
}
