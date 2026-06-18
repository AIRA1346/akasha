/// 클립보드 마크다운 정리 — 본문 편집기 스마트 붙여넣기.
class MarkdownSmartPaste {
  MarkdownSmartPaste._();

  /// 붙여넣기용 텍스트 정리 (본문 편집기용).
  static String normalizeForBody(String raw) {
    var text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }

    final bodyOnly = _stripYamlFrontmatter(text);
    if (bodyOnly != null) {
      text = bodyOnly;
    }

    return _trimTrailingLines(text);
  }

  static String? _stripYamlFrontmatter(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return null;

    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        return _trimTrailingLines(lines.sublist(i + 1).join('\n'));
      }
    }
    return null;
  }

  static String _trimTrailingLines(String text) {
    final lines = text.split('\n');
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    return lines.join('\n');
  }
}
