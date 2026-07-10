import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/services/lossless_frontmatter_patcher.dart';

void main() {
  const ownedKeys = {'title', 'rating', 'tags'};

  test(
    'patches owned fields while preserving unknown scalar, list, and map',
    () {
      const existing = '''---
# human-owned note
title: "before"
x_scalar: "keep me"
x_list:
  - "one"
  - "two"
x_map:
  nested: true
  count: 7
# preserve this comment
---
old body
''';
      const proposed = '''---
title: "after"
rating: 4.5
tags: ["important"]
---
new body
''';

      final patched = LosslessFrontmatterPatcher.patch(
        existingContent: existing,
        proposedContent: proposed,
        ownedKeys: ownedKeys,
      );

      expect(patched, contains('# human-owned note'));
      expect(patched, contains('title: "after"'));
      expect(patched, contains('rating: 4.5'));
      expect(patched, contains('tags: ["important"]'));
      expect(patched, contains('x_scalar: "keep me"'));
      expect(patched, contains('x_list:\n  - "one"\n  - "two"'));
      expect(patched, contains('x_map:\n  nested: true\n  count: 7'));
      expect(patched, contains('# preserve this comment'));
      expect(patched, endsWith('new body\n'));
    },
  );

  test('refuses malformed existing YAML instead of reconstructing it', () {
    const malformed = '''---
title: [unterminated
x_unknown: "must stay in original"
---
body
''';
    const proposed = '''---
title: "after"
---
new body
''';

    expect(
      () => LosslessFrontmatterPatcher.patch(
        existingContent: malformed,
        proposedContent: proposed,
        ownedKeys: ownedKeys,
      ),
      throwsA(isA<LosslessFrontmatterPatchException>()),
    );
  });
}
