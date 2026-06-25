import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/entity_link_selection.dart';
import '../services/markdown_body_merger.dart';
import '../services/sanctum_image_import.dart';
import 'markdown_edit_actions.dart';
import 'markdown_slash_command_patch.dart';
import 'markdown_smart_paste.dart';

enum MarkdownEditorInsertResult {
  applied,
  emptyClipboard,
  vaultRequired,
  entityLinkUnavailable,
}

/// 스마트 붙여넣기·이미지·Entity 링크·슬롯 삽입 패치 생성.
abstract final class MarkdownEditorInsertOps {
  static Future<(TextEditPatch?, MarkdownEditorInsertResult)> smartPastePatch({
    required String text,
    required TextSelection selection,
  }) async {
    final imported = await SanctumImageImport.importFromClipboard();
    if (imported.isNotEmpty) {
      var nextText = text;
      var nextSelection = selection;
      for (final path in imported) {
        final patch = MarkdownEditActions.insertImage(
          text: nextText,
          selection: nextSelection,
          imagePath: path,
        );
        nextText = patch.text;
        nextSelection = patch.selection;
      }
      return (
        TextEditPatch(text: nextText, selection: nextSelection),
        MarkdownEditorInsertResult.applied,
      );
    }

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text;
    if (raw == null || raw.trim().isEmpty) {
      return (null, MarkdownEditorInsertResult.emptyClipboard);
    }
    return (
      MarkdownEditActions.insertText(
        text: text,
        selection: selection,
        insert: MarkdownSmartPaste.normalizeForBody(raw),
      ),
      MarkdownEditorInsertResult.applied,
    );
  }

  static TextEditPatch? slotPatch({
    required String text,
    required TextSelection selection,
    required MarkdownSlotKind kind,
  }) {
    return MarkdownEditActions.insertSlotSection(
      text: text,
      selection: selection,
      kind: kind,
    );
  }

  static String slotExistsMessage(MarkdownSlotKind kind) {
    return '${MarkdownSlashCommandPatch.slotLabel(kind)} 섹션이 이미 있습니다.';
  }

  static Future<(TextEditPatch?, MarkdownEditorInsertResult)> entityLinkPatch({
    required BuildContext context,
    required String text,
    required TextSelection selection,
    required Future<EntityLinkSelection?> Function(
      BuildContext context,
      String selectedText,
    )? onRequestEntityLink,
  }) async {
    if (onRequestEntityLink == null) {
      return (null, MarkdownEditorInsertResult.entityLinkUnavailable);
    }

    var selectedText = '';
    if (selection.isValid && !selection.isCollapsed) {
      selectedText = text.substring(selection.start, selection.end);
    }

    final picked = await onRequestEntityLink(context, selectedText);
    if (picked == null) {
      return (null, MarkdownEditorInsertResult.applied);
    }

    return (
      MarkdownEditActions.insertWikiLink(
        text: text,
        selection: selection,
        entityId: picked.entityId,
        title: picked.title,
      ),
      MarkdownEditorInsertResult.applied,
    );
  }

  static Future<(TextEditPatch?, MarkdownEditorInsertResult)> imagePatch({
    required String text,
    required TextSelection selection,
  }) async {
    if (!SanctumImageImport.canImport) {
      return (null, MarkdownEditorInsertResult.vaultRequired);
    }

    final normalized = await SanctumImageImport.pickAndImport();
    if (normalized == null) {
      return (null, MarkdownEditorInsertResult.applied);
    }

    return (
      MarkdownEditActions.insertImage(
        text: text,
        selection: selection,
        imagePath: normalized,
      ),
      MarkdownEditorInsertResult.applied,
    );
  }

  static Future<TextEditPatch?> customSectionPatch(
    BuildContext context, {
    required String text,
    required TextSelection selection,
  }) async {
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('섹션 추가'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '예: 🎵 OST 메모',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
    if (title == null || title.trim().isEmpty) return null;
    return MarkdownEditActions.insertCustomSection(
      text: text,
      selection: selection,
      title: title,
    );
  }
}
