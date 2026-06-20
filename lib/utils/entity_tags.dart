import '../widgets/editable_tag_chips.dart';

/// Entity semantic tags — parse/normalize (Work `MarkdownParser` convention).
abstract final class EntityTags {
  static List<String> parseYaml(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return parseTagList(raw.map((e) => e.toString()));
    }
    if (raw is String) {
      return parseTagList([raw]);
    }
    return const [];
  }

  static String serializeYamlLine(List<String> tags) {
    if (tags.isEmpty) return 'tags: []';
    final escaped = tags.map((t) => '"${t.replaceAll('"', '\\"')}"');
    return 'tags: [${escaped.join(', ')}]';
  }
}
