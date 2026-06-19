import '../core/archiving/record_link.dart';
import '../models/entity_id_codec.dart';
import '../models/work_id_codec.dart';

/// `[[entity_id|label]]` · `[[entity_id]]` · `[[Title]]` — Wave 5.
abstract final class RecordLinkParser {
  static final RegExp _wikiPattern = RegExp(
    r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]',
  );

  static List<ParsedRecordLink> parseFromMarkdown(String markdown) {
    final scannable = _stripFencedCodeBlocks(markdown);
    final links = <ParsedRecordLink>[];

    for (final match in _wikiPattern.allMatches(scannable)) {
      final parsed = _parseMatch(match);
      if (parsed != null) links.add(parsed);
    }

    return links;
  }

  static List<ParsedRecordLink> parseFromRecordContent(String content) {
    return parseFromMarkdown(extractBody(content));
  }

  static String extractBody(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return content;

    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        return lines.sublist(i + 1).join('\n');
      }
    }
    return content;
  }

  static ParsedRecordLink? _parseMatch(RegExpMatch match) {
    final primary = match.group(1)?.trim() ?? '';
    if (primary.isEmpty) return null;

    final pipeLabel = match.group(2)?.trim();
    final displayLabel =
        pipeLabel != null && pipeLabel.isNotEmpty ? pipeLabel : null;

    if (_looksLikeEntityId(primary)) {
      return ParsedRecordLink(
        kind: RecordLinkKind.explicitId,
        raw: primary,
        targetEntityId: primary,
        displayLabel: displayLabel,
        startOffset: match.start,
      );
    }

    return ParsedRecordLink(
      kind: RecordLinkKind.titleOnly,
      raw: primary,
      targetTitle: primary,
      displayLabel: displayLabel,
      startOffset: match.start,
    );
  }

  static bool _looksLikeEntityId(String text) {
    final id = text.trim();
    if (id.isEmpty) return false;
    if (EntityIdCodec.isMasterFormat(id)) return true;
    if (WorkIdCodec.isLegacyMasterId(id)) return true;
    return false;
  }

  static String _stripFencedCodeBlocks(String markdown) {
    final buffer = StringBuffer();
    var inFence = false;

    for (final line in markdown.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        buffer.writeln();
        continue;
      }
      if (!inFence) buffer.writeln(line);
    }

    return buffer.toString();
  }
}
