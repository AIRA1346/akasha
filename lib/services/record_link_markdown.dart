import '../core/archiving/record_link.dart';
import 'record_link_parser.dart';

/// `[[wiki]]` → markdown link 변환 — Wave 5 preview tap.
abstract final class RecordLinkMarkdown {
  static const String wikiScheme = 'akasha-wiki';

  static String preprocessForDisplay(String markdown) {
    return markdown.replaceAllMapped(
      RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]'),
      (match) {
        final primary = match.group(1)!.trim();
        if (primary.isEmpty) return match.group(0)!;

        final label = match.group(2)?.trim();
        final display =
            label != null && label.isNotEmpty ? label : primary;
        final href = Uri(
          scheme: wikiScheme,
          queryParameters: {
            'id': primary,
            if (label != null && label.isNotEmpty) 'label': label,
          },
        ).toString();
        return '[$display]($href)';
      },
    );
  }

  static ParsedRecordLink? linkFromTapHref(String? href) {
    final uri = Uri.tryParse(href ?? '');
    if (uri == null || uri.scheme != wikiScheme) return null;

    final primary = uri.queryParameters['id']?.trim() ?? '';
    if (primary.isEmpty) return null;

    final label = uri.queryParameters['label'];
    final wiki = label != null && label.isNotEmpty
        ? '[[$primary|$label]]'
        : '[[$primary]]';

    final links = RecordLinkParser.parseFromMarkdown(wiki);
    return links.isEmpty ? null : links.first;
  }
}
