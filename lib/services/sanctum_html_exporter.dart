import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/akasha_item.dart';
import '../models/sanctum_cast_entry.dart';
import '../models/sanctum_gallery_entry.dart';
import 'markdown_body_merger.dart';

/// Sanctum 기록 → 독립 HTML (md와 같은 폴더, 상대 이미지 경로).
abstract final class SanctumHtmlExporter {
  static final _wikiRe = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
  static final _boldRe = RegExp(r'\*\*([^*]+)\*\*');

  static Future<String?> exportAdjacentToRecord({
    required AkashaItem item,
    required String bodyMarkdown,
    String? titleOverride,
  }) async {
    if (kIsWeb) return null;
    final mdPath = item.filePath;
    if (mdPath == null || mdPath.trim().isEmpty) return null;

    final dir = p.dirname(mdPath);
    final base = p.basenameWithoutExtension(mdPath);
    final htmlPath = p.join(dir, '$base.html');

    final override = titleOverride?.trim();
    final displayTitle =
        override != null && override.isNotEmpty ? override : item.title;

    final html = buildHtml(
      title: displayTitle,
      item: item,
      bodyMarkdown: bodyMarkdown,
    );

    await File(htmlPath).writeAsString(html, flush: true);
    return htmlPath;
  }

  static String buildHtml({
    required String title,
    required AkashaItem item,
    required String bodyMarkdown,
  }) {
    final slots = MarkdownBodyMerger.parseSlots(bodyMarkdown);
    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="ko">')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8">')
      ..writeln('<meta name="viewport" content="width=device-width, initial-scale=1">')
      ..writeln('<title>${_escape(title)}</title>')
      ..writeln('<style>')
      ..writeln(_css)
      ..writeln('</style>')
      ..writeln('</head>')
      ..writeln('<body>')
      ..writeln('<article class="archive">')
      ..writeln('<header class="hero">');

    if (item.posterPath != null && item.posterPath!.trim().isNotEmpty) {
      final poster = _escape(item.posterPath!.trim().replaceAll('\\', '/'));
      buffer.writeln(
        '<img class="poster" src="$poster" alt="${_escape(title)}">',
      );
    }

    buffer
      ..writeln('<h1>${_escape(title)}</h1>')
      ..writeln(_metaLine(item))
      ..writeln('</header>');

    if (slots.cast.isNotEmpty) {
      buffer.writeln('<section><h2>출연</h2><ul class="cast">');
      for (final entry in slots.cast) {
        buffer.writeln(_castLine(entry));
      }
      buffer.writeln('</ul></section>');
    }

    if (slots.gallery.isNotEmpty) {
      buffer.writeln('<section><h2>갤러리</h2><div class="gallery">');
      for (final entry in slots.gallery) {
        buffer.writeln(_galleryTile(entry));
      }
      buffer.writeln('</div></section>');
    }

    if (slots.synopsis.trim().isNotEmpty) {
      buffer.writeln(
        '<section><h2>시놉시스</h2>${_prose(slots.synopsis)}</section>',
      );
    }

    if (slots.quotes.isNotEmpty) {
      buffer.writeln('<section><h2>명장면 &amp; 명대사</h2>');
      for (final quote in slots.quotes) {
        buffer.writeln('<blockquote>${_inline(quote)}</blockquote>');
      }
      buffer.writeln('</section>');
    }

    if (slots.memo.trim().isNotEmpty) {
      buffer.writeln(
        '<section><h2>메모</h2>${_prose(slots.memo)}</section>',
      );
    }

    buffer
      ..writeln('<footer class="footer">Exported from AKASHA Sanctum</footer>')
      ..writeln('</article>')
      ..writeln('</body>')
      ..writeln('</html>');

    return buffer.toString();
  }

  static String _metaLine(AkashaItem item) {
    final parts = <String>[];
    if (item.creator.trim().isNotEmpty) {
      parts.add(_escape(item.creator.trim()));
    }
    if (item.releaseYear != null) {
      parts.add('${item.releaseYear}');
    }
    if (item.rating > 0) {
      parts.add('★ ${item.rating.toStringAsFixed(1)}');
    }
    if (parts.isEmpty) return '';
    return '<p class="meta">${parts.join(' · ')}</p>';
  }

  static String _castLine(SanctumCastEntry entry) {
    final label = _escape(entry.title);
    final role = entry.role?.trim();
    if (role != null && role.isNotEmpty) {
      return '<li><span class="wiki">$label</span> <span class="role">· ${_escape(role)}</span></li>';
    }
    return '<li><span class="wiki">$label</span></li>';
  }

  static String _galleryTile(SanctumGalleryEntry entry) {
    final src = _escape(entry.imagePath.replaceAll('\\', '/'));
    final alt = entry.caption?.trim();
    final altAttr = alt != null && alt.isNotEmpty ? _escape(alt) : '';
    final caption = alt != null && alt.isNotEmpty
        ? '<figcaption>${_escape(alt)}</figcaption>'
        : '';
    return '<figure><img src="$src" alt="$altAttr">$caption</figure>';
  }

  static String _prose(String text) {
    final paragraphs = text.split(RegExp(r'\n{2,}'));
    final buffer = StringBuffer();
    for (final block in paragraphs) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;
      final inner = trimmed
          .split('\n')
          .map(_inline)
          .join('<br>\n');
      buffer.writeln('<p>$inner</p>');
    }
    return buffer.toString();
  }

  static String _inline(String text) {
    var out = _escape(text);
    out = out.replaceAllMapped(_wikiRe, (match) {
      final label = match.group(2)?.trim();
      final display = (label != null && label.isNotEmpty)
          ? label
          : match.group(1)!.trim();
      return '<span class="wiki">${_escape(display)}</span>';
    });
    out = out.replaceAllMapped(
      _boldRe,
      (match) => '<strong>${match.group(1)}</strong>',
    );
    return out;
  }

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static const _css = '''
body { margin: 0; font-family: "Pretendard", "Noto Sans KR", system-ui, sans-serif;
  background: #f6f4ef; color: #1a1a1a; line-height: 1.65; }
.archive { max-width: 720px; margin: 0 auto; padding: 2rem 1.25rem 3rem; }
.hero { text-align: center; margin-bottom: 2rem; }
.poster { max-width: 220px; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,.12); margin-bottom: 1rem; }
h1 { font-size: 1.75rem; margin: 0 0 .35rem; }
.meta { color: #666; font-size: .95rem; margin: 0; }
section { margin-bottom: 2rem; }
h2 { font-size: 1.1rem; border-bottom: 2px solid #2dd4bf; padding-bottom: .35rem; margin: 0 0 1rem; }
.cast { list-style: none; padding: 0; margin: 0; }
.cast li { padding: .35rem 0; }
.role { color: #666; font-size: .9rem; }
.wiki { color: #0d9488; font-weight: 600; }
.gallery { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: .75rem; }
.gallery img { width: 100%; border-radius: 8px; display: block; }
.gallery figcaption { font-size: .75rem; color: #555; margin-top: .25rem; text-align: center; }
blockquote { margin: 0 0 1rem; padding: .75rem 1rem; border-left: 4px solid #2dd4bf;
  background: #fff; border-radius: 0 8px 8px 0; font-style: italic; }
p { margin: 0 0 1rem; white-space: pre-wrap; }
.footer { margin-top: 3rem; font-size: .75rem; color: #999; text-align: center; }
''';
}
