/// Sanctum `# 👥 출연` 슬롯 한 줄 — `[[entityId|Title]] role:역할`
class SanctumCastEntry {
  const SanctumCastEntry({
    required this.entityId,
    required this.title,
    this.role,
  });

  final String entityId;
  final String title;
  final String? role;

  String get wikiToken => '[[$entityId|$title]]';

  String toMarkdownLine() {
    final roleText = role?.trim();
    if (roleText != null && roleText.isNotEmpty) {
      return '- $wikiToken role:$roleText';
    }
    return '- $wikiToken';
  }

  @override
  bool operator ==(Object other) =>
      other is SanctumCastEntry &&
      other.entityId == entityId &&
      other.title == title &&
      other.role == role;

  @override
  int get hashCode => Object.hash(entityId, title, role);
}

/// 출연 슬롯 본문 파싱·직렬화.
abstract final class SanctumCastFormat {
  static final _wikiRe = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
  static final _roleRe = RegExp(r'^(?:·|role:)\s*(.+)$', caseSensitive: false);

  static SanctumCastEntry? parseLine(String raw) {
    final line = raw.trim();
    if (line.isEmpty || !line.startsWith('-')) return null;

    final wikiMatch = _wikiRe.firstMatch(line);
    if (wikiMatch == null) return null;

    final entityId = wikiMatch.group(1)!.trim();
    if (entityId.isEmpty) return null;

    final label = wikiMatch.group(2)?.trim();
    final title = label != null && label.isNotEmpty ? label : entityId;

    String? role;
    final after = line.substring(wikiMatch.end).trim();
    final roleMatch = _roleRe.firstMatch(after);
    if (roleMatch != null) {
      final parsed = roleMatch.group(1)!.trim();
      if (parsed.isNotEmpty) role = parsed;
    }

    return SanctumCastEntry(
      entityId: entityId,
      title: title,
      role: role,
    );
  }

  static List<SanctumCastEntry> parseBlock(String content) {
    final entries = <SanctumCastEntry>[];
    for (final line in content.split('\n')) {
      final entry = parseLine(line);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  static String formatBlock(List<SanctumCastEntry> entries) {
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln(entry.toMarkdownLine());
    }
    return buffer.toString().trimRight();
  }
}
