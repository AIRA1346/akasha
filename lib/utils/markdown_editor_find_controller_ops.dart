import 'package:flutter/material.dart';

import 'markdown_edit_actions.dart';
import 'markdown_find_replace.dart';

/// 찾기/바꾸기 UI가 사용하는 컨트롤러 조작.
abstract final class MarkdownEditorFindControllerOps {
  static int? findMatchOffset({
    required TextEditingController controller,
    required String query,
    required bool forward,
  }) {
    if (query.isEmpty) return null;
    final text = controller.text;
    final from = controller.selection.isValid
        ? (forward ? controller.selection.end : controller.selection.start)
        : 0;

    int? match;
    if (forward) {
      match = MarkdownFindReplace.findNext(
        text: text,
        query: query,
        fromOffset: from,
      );
      match ??= MarkdownFindReplace.findNext(
        text: text,
        query: query,
        fromOffset: 0,
      );
    } else {
      match = MarkdownFindReplace.findPrevious(
        text: text,
        query: query,
        fromOffset: from,
      );
      match ??= MarkdownFindReplace.findPrevious(
        text: text,
        query: query,
        fromOffset: text.length,
      );
    }
    return match;
  }

  static void selectMatch({
    required TextEditingController controller,
    required int matchStart,
    required String query,
  }) {
    controller.selection = TextSelection(
      baseOffset: matchStart,
      extentOffset: matchStart + query.length,
    );
  }

  static TextEditPatch? replaceCurrentMatch({
    required TextEditingController controller,
    required String query,
    required String replacement,
  }) {
    if (query.isEmpty) return null;
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid || sel.start == sel.end) return null;
    final selected = text.substring(sel.start, sel.end);
    if (selected.toLowerCase() != query.toLowerCase()) return null;
    return MarkdownFindReplace.replaceAt(
      text: text,
      matchStart: sel.start,
      query: query,
      replacement: replacement,
    );
  }
}
