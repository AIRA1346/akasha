import 'package:flutter/services.dart';

/// Undo/redo 스택에 저장하는 편집기 스냅샷.
class MarkdownEditorSnapshot {
  const MarkdownEditorSnapshot({required this.text, required this.selection});

  final String text;
  final TextSelection selection;
}
