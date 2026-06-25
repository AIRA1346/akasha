/// Sanctum `# 🖼 갤러리` 슬롯 — `- ![](posters/…)` 목록
class SanctumGalleryEntry {
  const SanctumGalleryEntry({
    required this.imagePath,
    this.caption,
  });

  final String imagePath;
  final String? caption;

  String toMarkdownLine() {
    final alt = caption?.trim();
    if (alt != null && alt.isNotEmpty) {
      return '- ![$alt]($imagePath)';
    }
    return '- ![]($imagePath)';
  }

  @override
  bool operator ==(Object other) =>
      other is SanctumGalleryEntry &&
      other.imagePath == imagePath &&
      other.caption == caption;

  @override
  int get hashCode => Object.hash(imagePath, caption);
}

/// 갤러리 슬롯 본문 파싱·직렬화.
abstract final class SanctumGalleryFormat {
  static final _imageRe = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');

  static SanctumGalleryEntry? parseLine(String raw) {
    var line = raw.trim();
    if (line.isEmpty) return null;
    if (line.startsWith('-')) line = line.substring(1).trim();
    final match = _imageRe.firstMatch(line);
    if (match == null) return null;
    if (line != match.group(0)) return null;

    final caption = match.group(1)?.trim();
    final path = match.group(2)!.trim().replaceAll('\\', '/');
    if (path.isEmpty) return null;

    return SanctumGalleryEntry(
      imagePath: path,
      caption: caption != null && caption.isNotEmpty ? caption : null,
    );
  }

  static List<SanctumGalleryEntry> parseBlock(String content) {
    final entries = <SanctumGalleryEntry>[];
    for (final line in content.split('\n')) {
      final entry = parseLine(line);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  static String formatBlock(List<SanctumGalleryEntry> entries) {
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln(entry.toMarkdownLine());
    }
    return buffer.toString().trimRight();
  }

  /// 단일 줄 본문에 이미지 마크다운이 있으면 파싱.
  static SanctumGalleryEntry? parseInlineImageLine(String line) {
    var content = line.trim();
    if (content.isEmpty) return null;
    if (content.startsWith('-')) content = content.substring(1).trim();
    final match = _imageRe.firstMatch(content);
    if (match == null) return null;
    if (content != match.group(0)) return null;

    final caption = match.group(1)?.trim();
    final path = match.group(2)!.trim().replaceAll('\\', '/');
    if (path.isEmpty) return null;

    return SanctumGalleryEntry(
      imagePath: path,
      caption: caption != null && caption.isNotEmpty ? caption : null,
    );
  }
}
