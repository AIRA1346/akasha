import 'package:flutter/material.dart';

import 'markdown_edit_actions.dart';

/// 본문 찾기·바꾸기 (순수 함수).
class MarkdownFindReplace {
  MarkdownFindReplace._();

  static int? findNext({
    required String text,
    required String query,
    required int fromOffset,
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) return null;
    final start = fromOffset.clamp(0, text.length);
    final haystack = caseSensitive ? text : text.toLowerCase();
    final needle = caseSensitive ? query : query.toLowerCase();
    final index = haystack.indexOf(needle, start);
    return index >= 0 ? index : null;
  }

  static int? findPrevious({
    required String text,
    required String query,
    required int fromOffset,
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) return null;
    final end = fromOffset.clamp(0, text.length);
    final haystack = caseSensitive ? text : text.toLowerCase();
    final needle = caseSensitive ? query : query.toLowerCase();
    final index = end <= 0 ? -1 : haystack.lastIndexOf(needle, end - 1);
    return index >= 0 ? index : null;
  }

  static int countMatches({
    required String text,
    required String query,
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) return 0;
    final haystack = caseSensitive ? text : text.toLowerCase();
    final needle = caseSensitive ? query : query.toLowerCase();
    var count = 0;
    var start = 0;
    while (true) {
      final index = haystack.indexOf(needle, start);
      if (index < 0) break;
      count++;
      start = index + needle.length;
    }
    return count;
  }

  static TextEditPatch replaceAt({
    required String text,
    required int matchStart,
    required String query,
    required String replacement,
  }) {
    final end = matchStart + query.length;
    final newText =
        text.replaceRange(matchStart, end.clamp(0, text.length), replacement);
    final cursor = matchStart + replacement.length;
    return TextEditPatch(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  static TextEditPatch replaceAll({
    required String text,
    required String query,
    required String replacement,
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) {
      return TextEditPatch(
        text: text,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    var last = 0;
    var offset = 0;
    while (offset <= text.length) {
      final match = caseSensitive
          ? text.indexOf(query, offset)
          : text.toLowerCase().indexOf(query.toLowerCase(), offset);
      if (match < 0) break;
      buffer.write(text.substring(last, match));
      buffer.write(replacement);
      last = match + query.length;
      offset = last;
    }
    buffer.write(text.substring(last));
    return TextEditPatch(
      text: buffer.toString(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }
}
