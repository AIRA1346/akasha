import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_vault.dart';
import '../models/entity_link_selection.dart';
import '../services/markdown_body_merger.dart';
import '../utils/markdown_edit_actions.dart';
import '../utils/markdown_editor_find_controller_ops.dart';
import '../utils/markdown_editor_insert_ops.dart';
import '../utils/markdown_editor_undo_stack.dart';
import '../utils/markdown_find_replace.dart';
import '../utils/markdown_section_index.dart';
import '../utils/markdown_slash_command_patch.dart';
import '../utils/markdown_slash_commands.dart';
import '../theme/akasha_colors.dart';


part 'markdown_editor_parts.dart';
part 'markdown_editor_shortcuts_part.dart';

/// 편집 대상 — 본문만 또는 YAML 포함 전체 md.
enum MarkdownEditorMode { body, fullFile }

/// Sanctum 마크다운 편집기 — 툴바 + 목차 + 상태바 + undo(툴바 액션).
class MarkdownBodyEditor extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool isDirty;
  final bool isSaving;
  final String? mdFilePath;
  final DateTime? lastSavedAt;
  final MarkdownEditorMode mode;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )? onRequestEntityLink;

  const MarkdownBodyEditor({
    super.key,
    required this.controller,
    required this.onChanged,
    this.isDirty = false,
    this.isSaving = false,
    this.mdFilePath,
    this.lastSavedAt,
    this.mode = MarkdownEditorMode.body,
    this.onRequestEntityLink,
  });

  @override
  State<MarkdownBodyEditor> createState() => _MarkdownBodyEditorState();
}

class _MarkdownBodyEditorState extends State<MarkdownBodyEditor> {
  final FocusNode _focusNode = FocusNode();
  final FocusNode _findFocusNode = FocusNode();
  final TextEditingController _findCtrl = TextEditingController();
  final TextEditingController _replaceCtrl = TextEditingController();
  final MarkdownEditorUndoStack _undoStack = MarkdownEditorUndoStack();

  int _lineNumber = 1;
  String _sectionLabel = '본문';
  bool _showFindBar = false;
  MarkdownSlashMatch? _slashMatch;
  int _slashSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    _updateCursorMeta();
  }

  @override
  void didUpdateWidget(MarkdownBodyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
      _updateCursorMeta();
      _updateSlashMatch();
    }
  }

  void _onControllerUpdate() {
    _updateCursorMeta();
    final hadSlash = _slashMatch != null;
    _updateSlashMatch();
    if (hadSlash || _slashMatch != null) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _findCtrl.dispose();
    _replaceCtrl.dispose();
    _findFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateCursorMeta() {
    final text = widget.controller.text;
    final offset = widget.controller.selection.isValid
        ? widget.controller.selection.start
        : text.length;
    final line = MarkdownSectionIndex.lineNumberAtOffset(text, offset);
    final section =
        MarkdownSectionIndex.sectionLabelAtOffset(text, offset);
    if (line != _lineNumber || section != _sectionLabel) {
      setState(() {
        _lineNumber = line;
        _sectionLabel = section;
      });
    }
  }

  void _applyPatch(TextEditPatch patch, {bool recordUndo = true}) {
    if (recordUndo) {
      _undoStack.push(widget.controller);
    }
    widget.controller.value = TextEditingValue(
      text: patch.text,
      selection: patch.selection,
    );
    widget.onChanged();
    setState(() {});
  }

  void _undo() {
    if (!_undoStack.undo(widget.controller)) return;
    widget.onChanged();
    setState(() {});
  }

  void _redo() {
    if (!_undoStack.redo(widget.controller)) return;
    widget.onChanged();
    setState(() {});
  }

  void _wrap(String left, String right, {String placeholder = ''}) {
    _applyPatch(MarkdownEditActions.wrapSelection(
      text: widget.controller.text,
      selection: widget.controller.selection,
      left: left,
      right: right,
      placeholder: placeholder,
    ));
  }

  void _onEditorChanged(String _) {
    widget.onChanged();
    _updateSlashMatch();
    setState(() {});
  }

  void _updateSlashMatch() {
    final text = widget.controller.text;
    final offset = widget.controller.selection.isValid
        ? widget.controller.selection.start
        : text.length;
    final match = MarkdownSlashCommands.matchAtOffset(text, offset);
    if (match?.commandStart != _slashMatch?.commandStart ||
        match?.query != _slashMatch?.query) {
      _slashMatch = match;
      _slashSelectedIndex = 0;
    }
  }

  void _applySlashCommand(MarkdownSlashCommand command) {
    final match = _slashMatch;
    if (match == null) return;

    final stripped = widget.controller.text.replaceRange(
      match.commandStart,
      match.lineEnd,
      '',
    );
    final at = match.commandStart;
    final sel = TextSelection.collapsed(offset: at);

    final patch = MarkdownSlashCommandPatch.forCommand(
      command: command,
      strippedText: stripped,
      selectionAtCommand: sel,
    );

    if (patch == null) {
      _showSnack('이미 존재하는 섹션입니다.');
      return;
    }

    _slashMatch = null;
    _applyPatch(patch);
  }

  void _insertSlot(MarkdownSlotKind kind) {
    final patch = MarkdownEditorInsertOps.slotPatch(
      text: widget.controller.text,
      selection: widget.controller.selection,
      kind: kind,
    );
    if (patch == null) {
      _showSnack(MarkdownEditorInsertOps.slotExistsMessage(kind));
      return;
    }
    _applyPatch(patch);
  }

  void _jumpToSection(MarkdownSectionEntry entry) {
    widget.controller.selection = TextSelection.collapsed(
      offset: entry.charOffset,
    );
    _focusNode.requestFocus();
    _updateCursorMeta();
  }

  void _toggleFindBar() {
    setState(() => _showFindBar = !_showFindBar);
    if (_showFindBar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _findFocusNode.requestFocus();
      });
    }
  }

  void _findNext({bool forward = true}) {
    final query = _findCtrl.text;
    final match = MarkdownEditorFindControllerOps.findMatchOffset(
      controller: widget.controller,
      query: query,
      forward: forward,
    );

    if (match != null) {
      MarkdownEditorFindControllerOps.selectMatch(
        controller: widget.controller,
        matchStart: match,
        query: query,
      );
      _focusNode.requestFocus();
      setState(() {});
    } else if (query.isNotEmpty) {
      _showSnack('찾을 수 없습니다.');
    }
  }

  void _replaceCurrent() {
    final query = _findCtrl.text;
    if (query.isEmpty) return;
    final patch = MarkdownEditorFindControllerOps.replaceCurrentMatch(
      controller: widget.controller,
      query: query,
      replacement: _replaceCtrl.text,
    );
    if (patch == null) {
      _findNext();
      return;
    }
    _applyPatch(patch);
    _findNext();
  }

  void _replaceAll() {
    final query = _findCtrl.text;
    if (query.isEmpty) return;
    _applyPatch(MarkdownFindReplace.replaceAll(
      text: widget.controller.text,
      query: query,
      replacement: _replaceCtrl.text,
    ));
  }

  Future<void> _smartPaste() async {
    final (patch, result) = await MarkdownEditorInsertOps.smartPastePatch(
      text: widget.controller.text,
      selection: widget.controller.selection,
    );
    if (!mounted) return;
    switch (result) {
      case MarkdownEditorInsertResult.emptyClipboard:
        _showSnack('클립보드에 붙여넣을 내용이 없습니다.');
      case MarkdownEditorInsertResult.applied:
        if (patch != null) _applyPatch(patch);
      default:
        break;
    }
  }

  Future<void> _insertEntityLink() async {
    final (patch, result) = await MarkdownEditorInsertOps.entityLinkPatch(
      context: context,
      text: widget.controller.text,
      selection: widget.controller.selection,
      onRequestEntityLink: widget.onRequestEntityLink,
    );
    if (!mounted) return;
    if (result == MarkdownEditorInsertResult.entityLinkUnavailable) {
      _showSnack('Entity 연결을 사용할 수 없습니다.');
      return;
    }
    if (patch != null) _applyPatch(patch);
  }

  Future<void> _insertImage() async {
    final (patch, result) = await MarkdownEditorInsertOps.imagePatch(
      text: widget.controller.text,
      selection: widget.controller.selection,
    );
    if (!mounted) return;
    if (result == MarkdownEditorInsertResult.vaultRequired) {
      _showSnack('이미지 삽입은 Sanctum 볼트 연결 후 사용할 수 있습니다.');
      return;
    }
    if (patch != null) _applyPatch(patch);
  }

  Future<void> _insertCustomSection() async {
    final patch = await MarkdownEditorInsertOps.customSectionPatch(
      context,
      text: widget.controller.text,
      selection: widget.controller.selection,
    );
    if (!mounted || patch == null) return;
    _applyPatch(patch);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  List<MarkdownSectionEntry> get _sections =>
      MarkdownSectionIndex.parseHeadings(widget.controller.text);

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final controller = widget.controller;

    return _MarkdownEditorShortcutBindings(
      controller: controller,
      onWrap: _wrap,
      onApplyPatch: _applyPatch,
      onToggleFindBar: _toggleFindBar,
      onSmartPaste: _smartPaste,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MarkdownEditorToolbar(
            canUndo: _undoStack.canUndo,
            canRedo: _undoStack.canRedo,
            sections: sections,
            vaultLinked: AppVault.port.vaultPath != null,
            onUndo: _undo,
            onRedo: _redo,
            onBold: () => _wrap('**', '**', placeholder: '굵게'),
            onItalic: () => _wrap('*', '*', placeholder: '기울임'),
            onStrike: () => _wrap('~~', '~~', placeholder: '취소선'),
            onCode: () => _wrap('`', '`', placeholder: 'code'),
            onH1: () => _applyPatch(MarkdownEditActions.insertHeading(
              text: controller.text,
              selection: controller.selection,
              level: 1,
            )),
            onH2: () => _applyPatch(MarkdownEditActions.insertHeading(
              text: controller.text,
              selection: controller.selection,
              level: 2,
            )),
            onH3: () => _applyPatch(MarkdownEditActions.insertHeading(
              text: controller.text,
              selection: controller.selection,
              level: 3,
            )),
            onQuote: () => _applyPatch(MarkdownEditActions.prefixLines(
              text: controller.text,
              selection: controller.selection,
              prefix: '> ',
            )),
            onBullet: () => _applyPatch(MarkdownEditActions.prefixLines(
              text: controller.text,
              selection: controller.selection,
              prefix: '- ',
            )),
            onNumbered: () => _applyPatch(MarkdownEditActions.prefixLines(
              text: controller.text,
              selection: controller.selection,
              prefix: '1. ',
            )),
            onLink: () => _applyPatch(MarkdownEditActions.insertLink(
              text: controller.text,
              selection: controller.selection,
            )),
            onEntityLink: _insertEntityLink,
            entityLinkEnabled: widget.onRequestEntityLink != null,
            onImage: _insertImage,
            onFind: _toggleFindBar,
            onSmartPaste: _smartPaste,
            onJumpToSection: _jumpToSection,
            onInsertCast: () => _insertSlot(MarkdownSlotKind.cast),
            onInsertGallery: () => _insertSlot(MarkdownSlotKind.gallery),
            onInsertSynopsis: () => _insertSlot(MarkdownSlotKind.synopsis),
            onInsertQuotes: () => _insertSlot(MarkdownSlotKind.quotes),
            onInsertMemo: () => _insertSlot(MarkdownSlotKind.memo),
            onInsertCustom: _insertCustomSection,
          ),
          if (_slashMatch != null) ...[
            const SizedBox(height: 4),
            _MarkdownSlashMenu(
              match: _slashMatch!,
              selectedIndex: _slashSelectedIndex,
              onSelect: _applySlashCommand,
            ),
          ],
          if (_showFindBar) ...[
            const SizedBox(height: 4),
            _MarkdownFindBar(
              findController: _findCtrl,
              replaceController: _replaceCtrl,
              findFocusNode: _findFocusNode,
              matchCount: MarkdownFindReplace.countMatches(
                text: controller.text,
                query: _findCtrl.text,
              ),
              onFindNext: () => _findNext(),
              onFindPrevious: () => _findNext(forward: false),
              onReplace: _replaceCurrent,
              onReplaceAll: _replaceAll,
              onClose: () => setState(() => _showFindBar = false),
              onChanged: () => setState(() {}),
            ),
          ],
          const SizedBox(height: 6),
          Expanded(
            child: Focus(
              onKeyEvent: (FocusNode node, KeyEvent event) {
                if (_slashMatch != null && event is KeyDownEvent) {
                  final candidates = _slashMatch!.candidates.take(8).toList();
                  if (candidates.isEmpty) return KeyEventResult.ignored;

                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    setState(() {
                      _slashSelectedIndex =
                          (_slashSelectedIndex + 1) % candidates.length;
                    });
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    setState(() {
                      _slashSelectedIndex =
                          (_slashSelectedIndex - 1 + candidates.length) %
                              candidates.length;
                    });
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _applySlashCommand(candidates[_slashSelectedIndex]);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    setState(() {
                      _slashMatch = null;
                    });
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: _MarkdownTextField(
                controller: controller,
                focusNode: _focusNode,
                onChanged: _onEditorChanged,
                hintText: widget.mode == MarkdownEditorMode.fullFile
                    ? '---\nwork_id: ...\n---\n\n# 본문'
                    : '# 📋 시놉시스\n...\n\n# 🎬 명장면 & 명대사\n> ...\n\n# 📝 메모\n...',
              ),
            ),
          ),
          const SizedBox(height: 4),
          _MarkdownEditorStatusBar(
            lineNumber: _lineNumber,
            sectionLabel: _sectionLabel,
            isDirty: widget.isDirty,
            isSaving: widget.isSaving,
            lastSavedAt: widget.lastSavedAt,
            hint: widget.mode == MarkdownEditorMode.fullFile
                ? '전체 md · / 로 명령'
                : '본문 · / 로 명령',
          ),
        ],
      ),
    );
  }
}
