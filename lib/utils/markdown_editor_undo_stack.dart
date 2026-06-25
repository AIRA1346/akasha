import 'package:flutter/material.dart';

import 'markdown_edit_actions.dart';
import 'markdown_editor_snapshot.dart';

/// 마크다운 편집기 undo/redo 스택.
class MarkdownEditorUndoStack {
  final List<MarkdownEditorSnapshot> _undoStack = [];
  final List<MarkdownEditorSnapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void push(TextEditingController controller) {
    _undoStack.add(MarkdownEditorSnapshot(
      text: controller.text,
      selection: controller.selection,
    ));
    if (_undoStack.length > MarkdownEditActions.maxUndoSteps) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  bool undo(TextEditingController controller) {
    if (_undoStack.isEmpty) return false;
    _redoStack.add(MarkdownEditorSnapshot(
      text: controller.text,
      selection: controller.selection,
    ));
    final prev = _undoStack.removeLast();
    controller.value = TextEditingValue(
      text: prev.text,
      selection: prev.selection,
    );
    return true;
  }

  bool redo(TextEditingController controller) {
    if (_redoStack.isEmpty) return false;
    _undoStack.add(MarkdownEditorSnapshot(
      text: controller.text,
      selection: controller.selection,
    ));
    final next = _redoStack.removeLast();
    controller.value = TextEditingValue(
      text: next.text,
      selection: next.selection,
    );
    return true;
  }
}
