import 'package:flutter/material.dart';

import '../models/entity_link_selection.dart';
import '../services/markdown_body_merger.dart';

/// 마크다운 본문 편집 — 선택 영역 wrap·삽입 (순수 함수).
class MarkdownEditActions {
  MarkdownEditActions._();

  static const int maxUndoSteps = 80;

  /// 본문에 해당 슬롯 헤딩이 이미 있는지.
  static bool bodyHasSlot(String text, MarkdownSlotKind kind) {
    for (final line in text.split('\n')) {
      if (MarkdownBodyMerger.slotKindForHeadingLine(line) == kind) {
        return true;
      }
    }
    return false;
  }

  static String headingForSlot(MarkdownSlotKind kind) {
    switch (kind) {
      case MarkdownSlotKind.cast:
        return MarkdownBodyMerger.castHeading;
      case MarkdownSlotKind.gallery:
        return MarkdownBodyMerger.galleryHeading;
      case MarkdownSlotKind.synopsis:
        return MarkdownBodyMerger.synopsisHeading;
      case MarkdownSlotKind.quotes:
        return MarkdownBodyMerger.quotesHeading;
      case MarkdownSlotKind.memo:
        return MarkdownBodyMerger.memoHeading;
    }
  }

  static String defaultContentForSlot(MarkdownSlotKind kind) {
    switch (kind) {
      case MarkdownSlotKind.cast:
        return '';
      case MarkdownSlotKind.gallery:
        return '';
      case MarkdownSlotKind.synopsis:
        return '';
      case MarkdownSlotKind.quotes:
        return '> ';
      case MarkdownSlotKind.memo:
        return '';
    }
  }

  /// 슬롯 섹션 블록 삽입. 이미 있으면 null.
  static TextEditPatch? insertSlotSection({
    required String text,
    required TextSelection selection,
    required MarkdownSlotKind kind,
  }) {
    if (bodyHasSlot(text, kind)) return null;

    final heading = headingForSlot(kind);
    final body = defaultContentForSlot(kind);
    final block = body.isEmpty ? '$heading\n' : '$heading\n$body\n';
    return _insertBlock(text, selection, block);
  }

  /// 자유 `# 제목` 섹션 삽입.
  static TextEditPatch insertCustomSection({
    required String text,
    required TextSelection selection,
    required String title,
  }) {
    final trimmed = title.trim();
    final heading = trimmed.startsWith('#') ? trimmed : '# $trimmed';
    return _insertBlock(text, selection, '$heading\n\n');
  }

  static TextEditPatch wrapSelection({
    required String text,
    required TextSelection selection,
    required String left,
    required String right,
    String placeholder = '',
  }) {
    final sel = _clampedSelection(text, selection);
    if (!sel.isValid) {
      return _insertBlock(text, sel, '$left$placeholder$right');
    }
    if (sel.isCollapsed) {
      final insert = '$left$placeholder$right';
      final newText = text.replaceRange(sel.start, sel.end, insert);
      final cursor = sel.start + left.length;
      final innerEnd = cursor + placeholder.length;
      return TextEditPatch(
        text: newText,
        selection: TextSelection(baseOffset: cursor, extentOffset: innerEnd),
      );
    }

    final selected = text.substring(sel.start, sel.end);
    final wrapped = '$left$selected$right';
    final newText = text.replaceRange(sel.start, sel.end, wrapped);
    return TextEditPatch(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + wrapped.length),
    );
  }

  static TextEditPatch prefixLines({
    required String text,
    required TextSelection selection,
    required String prefix,
  }) {
    final sel = _clampedSelection(text, selection);
    final lineRange = _lineRangeForSelection(text, sel);
    final block = text.substring(lineRange.start, lineRange.end);
    final lines = block.split('\n');
    final prefixed = lines.map((l) => l.isEmpty ? prefix.trimRight() : '$prefix$l').join('\n');
    final newText = text.replaceRange(lineRange.start, lineRange.end, prefixed);
    final delta = prefixed.length - block.length;
    return TextEditPatch(
      text: newText,
      selection: TextSelection(
        baseOffset: sel.start + delta,
        extentOffset: sel.end + delta,
      ),
    );
  }

  static TextEditPatch insertHeading({
    required String text,
    required TextSelection selection,
    required int level,
  }) {
    final hashes = '#' * level.clamp(1, 3);
    return prefixLines(text: text, selection: selection, prefix: '$hashes ');
  }

  static TextEditPatch insertLink({
    required String text,
    required TextSelection selection,
    String urlPlaceholder = 'https://',
  }) {
    final sel = _clampedSelection(text, selection);
    if (!sel.isValid || sel.isCollapsed) {
      return wrapSelection(
        text: text,
        selection: sel,
        left: '[',
        right: ']($urlPlaceholder)',
        placeholder: '링크 텍스트',
      );
    }
    final label = text.substring(sel.start, sel.end);
    final insert = '[$label]($urlPlaceholder)';
    final newText = text.replaceRange(sel.start, sel.end, insert);
    final urlStart = sel.start + label.length + 3;
    final urlEnd = urlStart + urlPlaceholder.length;
    return TextEditPatch(
      text: newText,
      selection: TextSelection(baseOffset: urlStart, extentOffset: urlEnd),
    );
  }

  /// Entity wiki link — canonical `[[entityId|Title]]` (R2-B).
  static TextEditPatch insertWikiLink({
    required String text,
    required TextSelection selection,
    required String entityId,
    required String title,
  }) {
    final token = EntityLinkSelection(
      entityId: entityId,
      title: title,
      entityType: '',
    ).canonicalWikiToken;

    final sel = _clampedSelection(text, selection);
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, token);
    return TextEditPatch(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  static TextEditPatch insertText({
    required String text,
    required TextSelection selection,
    required String insert,
  }) {
    final sel = _clampedSelection(text, selection);
    if (sel.isValid && !sel.isCollapsed) {
      final newText = text.replaceRange(sel.start, sel.end, insert);
      return TextEditPatch(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + insert.length),
      );
    }
    return _insertBlock(text, sel, insert);
  }

  static TextEditPatch insertCodeBlock({
    required String text,
    required TextSelection selection,
    String placeholder = 'code',
  }) {
    return _insertBlock(text, selection, '```\n$placeholder\n```\n');
  }

  static TextEditPatch insertHorizontalRule({
    required String text,
    required TextSelection selection,
  }) {
    return _insertBlock(text, selection, '---\n');
  }

  static TextEditPatch insertImage({
    required String text,
    required TextSelection selection,
    required String imagePath,
    String alt = 'image',
  }) {
    final sel = _clampedSelection(text, selection);
    final markdown = '![$alt]($imagePath)';
    if (!sel.isValid || sel.isCollapsed) {
      return _insertBlock(text, sel, '$markdown\n');
    }
    final newText = text.replaceRange(sel.start, sel.end, markdown);
    return TextEditPatch(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + markdown.length),
    );
  }

  static TextEditPatch _insertBlock(
    String text,
    TextSelection selection,
    String block,
  ) {
    final sel = _clampedSelection(text, selection);
    final insertAt = sel.isValid ? sel.start : text.length;
    final needsGapBefore = insertAt > 0 && text[insertAt - 1] != '\n';
    final needsGapAfter = insertAt < text.length && text[insertAt] != '\n';
    final prefix = (insertAt == 0 ? '' : (needsGapBefore ? '\n\n' : ''));
    final suffix = needsGapAfter ? '\n' : '';
    final insert = '$prefix$block$suffix';
    final newText = text.replaceRange(insertAt, insertAt, insert);
    final cursor = insertAt + insert.length;
    return TextEditPatch(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  static TextSelection _clampedSelection(String text, TextSelection selection) {
    if (!selection.isValid) {
      return TextSelection.collapsed(offset: text.length);
    }
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    return TextSelection(baseOffset: start, extentOffset: end);
  }

  static ({int start, int end}) _lineRangeForSelection(
    String text,
    TextSelection selection,
  ) {
    if (!selection.isValid || text.isEmpty) {
      return (start: 0, end: text.length);
    }
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    var lineStart = text.lastIndexOf('\n', start == 0 ? 0 : start - 1);
    lineStart = lineStart < 0 ? 0 : lineStart + 1;
    var lineEnd = text.indexOf('\n', end);
    lineEnd = lineEnd < 0 ? text.length : lineEnd;
    return (start: lineStart, end: lineEnd);
  }
}

class TextEditPatch {
  const TextEditPatch({
    required this.text,
    required this.selection,
  });

  final String text;
  final TextSelection selection;
}
