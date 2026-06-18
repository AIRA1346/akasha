import 'package:flutter/material.dart';

/// 마크다운 원문용 경량 syntax highlight (TextField 뒤 레이어).
class MarkdownSyntaxHighlighter {
  MarkdownSyntaxHighlighter._();

  static TextSpan buildSpan(String text, TextStyle baseStyle) {
    if (text.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    final spans = <TextSpan>[];
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(TextSpan(text: '\n', style: baseStyle));
      spans.addAll(_highlightLine(lines[i], baseStyle));
    }
    return TextSpan(children: spans);
  }

  static List<TextSpan> _highlightLine(String line, TextStyle baseStyle) {
    if (line.startsWith('---') && line.trim() == '---') {
      return [
        TextSpan(
          text: line,
          style: baseStyle.copyWith(color: const Color(0xFF6A6A8A)),
        ),
      ];
    }

    if (line.startsWith('#')) {
      final match = RegExp(r'^(#{1,6})\s*(.*)$').firstMatch(line);
      if (match != null) {
        return [
          TextSpan(
            text: match.group(1),
            style: baseStyle.copyWith(color: const Color(0xFF7FD4C4)),
          ),
          TextSpan(text: ' ', style: baseStyle),
          TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(
              color: const Color(0xFF9AE6D6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ];
      }
    }

    if (line.startsWith('>')) {
      return [
        TextSpan(
          text: line,
          style: baseStyle.copyWith(color: const Color(0xFFB8A8E8)),
        ),
      ];
    }

    if (line.trimLeft().startsWith('- ') ||
        RegExp(r'^\s*\d+\.\s').hasMatch(line)) {
      return [
        TextSpan(
          text: line,
          style: baseStyle.copyWith(color: const Color(0xFFCCCCDD)),
        ),
      ];
    }

    return _highlightInline(line, baseStyle);
  }

  static List<TextSpan> _highlightInline(String line, TextStyle baseStyle) {
    final pattern = RegExp(
      r'(\*\*[^*]+\*\*|\*[^*]+\*|~~[^~]+~~|`[^`]+`|\[[^\]]+\]\([^)]+\)|!\[[^\]]*\]\([^)]+\))',
    );
    final spans = <TextSpan>[];
    var start = 0;
    for (final match in pattern.allMatches(line)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: line.substring(start, match.start),
          style: baseStyle,
        ));
      }
      final token = match.group(0)!;
      Color? color;
      if (token.startsWith('**')) {
        color = const Color(0xFFE8E8F0);
      } else if (token.startsWith('*')) {
        color = const Color(0xFFD0D0E0);
      } else if (token.startsWith('~~')) {
        color = const Color(0xFF888899);
      } else if (token.startsWith('`')) {
        color = const Color(0xFFE6C07B);
      } else if (token.startsWith('![') || token.startsWith('[')) {
        color = const Color(0xFF7EB8FF);
      }
      spans.add(TextSpan(
        text: token,
        style: baseStyle.copyWith(
          color: color,
          fontWeight: token.startsWith('**') ? FontWeight.bold : null,
          fontStyle: token.startsWith('*') && !token.startsWith('**')
              ? FontStyle.italic
              : null,
        ),
      ));
      start = match.end;
    }
    if (start < line.length) {
      spans.add(TextSpan(text: line.substring(start), style: baseStyle));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: line, style: baseStyle));
    }
    return spans;
  }
}
