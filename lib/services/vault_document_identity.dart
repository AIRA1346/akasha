import 'dart:io';

import 'package:yaml/yaml.dart';

/// Reads the physical `record_id` identity declared by one Markdown Document.
///
/// Entity/work anchors are intentionally not substituted here. A path, title,
/// `entity_id`, or `work_id` may help discover a Document, but only the v3
/// `record_id` can name it as a provenance-bearing Record input.
abstract final class VaultDocumentIdentity {
  static Future<String?> readRecordId(File file) async {
    try {
      return recordIdFromMarkdown(await file.readAsString());
    } on FileSystemException {
      return null;
    }
  }

  static String? recordIdFromMarkdown(String markdown) {
    final frontmatter = _frontmatter(markdown);
    if (frontmatter == null) return null;
    try {
      final parsed = loadYaml(frontmatter);
      if (parsed is! YamlMap) return null;
      final value = parsed['record_id']?.toString().trim() ?? '';
      return value.isEmpty ? null : value;
    } on Object {
      return null;
    }
  }

  static String? _frontmatter(String markdown) {
    final lines = markdown.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return null;
    for (var index = 1; index < lines.length; index += 1) {
      if (lines[index].trim() == '---') {
        return lines.sublist(1, index).join('\n');
      }
    }
    return null;
  }
}
