import 'package:flutter/services.dart';

import '../services/markdown_body_merger.dart';
import 'markdown_edit_actions.dart';
import 'markdown_slash_commands.dart';

/// `/` 슬래시 명령 → 텍스트 패치 변환.
abstract final class MarkdownSlashCommandPatch {
  static TextEditPatch? forCommand({
    required MarkdownSlashCommand command,
    required String strippedText,
    required TextSelection selectionAtCommand,
  }) {
    switch (command.id) {
      case 'cast':
        return MarkdownEditActions.insertSlotSection(
          text: strippedText,
          selection: selectionAtCommand,
          kind: MarkdownSlotKind.cast,
        );
      case 'gallery':
        return MarkdownEditActions.insertSlotSection(
          text: strippedText,
          selection: selectionAtCommand,
          kind: MarkdownSlotKind.gallery,
        );
      case 'synopsis':
        return MarkdownEditActions.insertSlotSection(
          text: strippedText,
          selection: selectionAtCommand,
          kind: MarkdownSlotKind.synopsis,
        );
      case 'quotes':
        return MarkdownEditActions.insertSlotSection(
          text: strippedText,
          selection: selectionAtCommand,
          kind: MarkdownSlotKind.quotes,
        );
      case 'memo':
        return MarkdownEditActions.insertSlotSection(
          text: strippedText,
          selection: selectionAtCommand,
          kind: MarkdownSlotKind.memo,
        );
      case 'quote_line':
        return MarkdownEditActions.prefixLines(
          text: strippedText,
          selection: selectionAtCommand,
          prefix: '> ',
        );
      case 'link':
        return MarkdownEditActions.insertLink(
          text: strippedText,
          selection: selectionAtCommand,
        );
      case 'image':
        return MarkdownEditActions.insertImage(
          text: strippedText,
          selection: selectionAtCommand,
          imagePath: 'path/to/image.png',
        );
      case 'code_block':
        return MarkdownEditActions.insertCodeBlock(
          text: strippedText,
          selection: selectionAtCommand,
        );
      case 'hr':
        return MarkdownEditActions.insertHorizontalRule(
          text: strippedText,
          selection: selectionAtCommand,
        );
      case 'h1':
        return MarkdownEditActions.insertHeading(
          text: strippedText,
          selection: selectionAtCommand,
          level: 1,
        );
      case 'h2':
        return MarkdownEditActions.insertHeading(
          text: strippedText,
          selection: selectionAtCommand,
          level: 2,
        );
      case 'h3':
        return MarkdownEditActions.insertHeading(
          text: strippedText,
          selection: selectionAtCommand,
          level: 3,
        );
      case 'bullet':
        return MarkdownEditActions.prefixLines(
          text: strippedText,
          selection: selectionAtCommand,
          prefix: '- ',
        );
      case 'numbered':
        return MarkdownEditActions.prefixLines(
          text: strippedText,
          selection: selectionAtCommand,
          prefix: '1. ',
        );
      default:
        return null;
    }
  }

  static String slotLabel(MarkdownSlotKind kind) {
    switch (kind) {
      case MarkdownSlotKind.cast:
        return '출연';
      case MarkdownSlotKind.gallery:
        return '갤러리';
      case MarkdownSlotKind.synopsis:
        return '시놉시스';
      case MarkdownSlotKind.quotes:
        return '명장면 & 명대사';
      case MarkdownSlotKind.memo:
        return '메모';
    }
  }
}
