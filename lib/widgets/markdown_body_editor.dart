import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/entity_link_selection.dart';
import '../services/file_service.dart';
import '../services/markdown_body_merger.dart';
import '../services/sanctum_image_import.dart';
import '../utils/markdown_edit_actions.dart';
import '../utils/markdown_find_replace.dart';
import '../utils/markdown_section_index.dart';
import '../utils/markdown_slash_commands.dart';
import '../utils/markdown_smart_paste.dart';


part 'markdown_editor_parts.dart';
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
  final List<_EditorSnapshot> _undoStack = [];
  final List<_EditorSnapshot> _redoStack = [];

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

  void _pushUndo() {
    _undoStack.add(_EditorSnapshot(
      text: widget.controller.text,
      selection: widget.controller.selection,
    ));
    if (_undoStack.length > MarkdownEditActions.maxUndoSteps) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _applyPatch(TextEditPatch patch) {
    _pushUndo();
    widget.controller.value = TextEditingValue(
      text: patch.text,
      selection: patch.selection,
    );
    widget.onChanged();
    setState(() {});
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_EditorSnapshot(
      text: widget.controller.text,
      selection: widget.controller.selection,
    ));
    final prev = _undoStack.removeLast();
    widget.controller.value = TextEditingValue(
      text: prev.text,
      selection: prev.selection,
    );
    widget.onChanged();
    setState(() {});
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_EditorSnapshot(
      text: widget.controller.text,
      selection: widget.controller.selection,
    ));
    final next = _redoStack.removeLast();
    widget.controller.value = TextEditingValue(
      text: next.text,
      selection: next.selection,
    );
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

    TextEditPatch? patch;
    switch (command.id) {
      case 'cast':
        patch = MarkdownEditActions.insertSlotSection(
          text: stripped,
          selection: sel,
          kind: MarkdownSlotKind.cast,
        );
      case 'gallery':
        patch = MarkdownEditActions.insertSlotSection(
          text: stripped,
          selection: sel,
          kind: MarkdownSlotKind.gallery,
        );
      case 'synopsis':
        patch = MarkdownEditActions.insertSlotSection(
          text: stripped,
          selection: sel,
          kind: MarkdownSlotKind.synopsis,
        );
      case 'quotes':
        patch = MarkdownEditActions.insertSlotSection(
          text: stripped,
          selection: sel,
          kind: MarkdownSlotKind.quotes,
        );
      case 'memo':
        patch = MarkdownEditActions.insertSlotSection(
          text: stripped,
          selection: sel,
          kind: MarkdownSlotKind.memo,
        );
      case 'quote_line':
        patch = MarkdownEditActions.prefixLines(
          text: stripped,
          selection: sel,
          prefix: '> ',
        );
      case 'link':
        patch = MarkdownEditActions.insertLink(text: stripped, selection: sel);
      case 'image':
        patch = MarkdownEditActions.insertImage(
          text: stripped,
          selection: sel,
          imagePath: 'path/to/image.png',
        );
      case 'code_block':
        patch = MarkdownEditActions.insertCodeBlock(
          text: stripped,
          selection: sel,
        );
      case 'hr':
        patch = MarkdownEditActions.insertHorizontalRule(
          text: stripped,
          selection: sel,
        );
      case 'h1':
        patch = MarkdownEditActions.insertHeading(
          text: stripped,
          selection: sel,
          level: 1,
        );
      case 'h2':
        patch = MarkdownEditActions.insertHeading(
          text: stripped,
          selection: sel,
          level: 2,
        );
      case 'h3':
        patch = MarkdownEditActions.insertHeading(
          text: stripped,
          selection: sel,
          level: 3,
        );
      case 'bullet':
        patch = MarkdownEditActions.prefixLines(
          text: stripped,
          selection: sel,
          prefix: '- ',
        );
      case 'numbered':
        patch = MarkdownEditActions.prefixLines(
          text: stripped,
          selection: sel,
          prefix: '1. ',
        );
    }

    if (patch == null) {
      _showSnack('이미 존재하는 섹션입니다.');
      return;
    }

    _slashMatch = null;
    _applyPatch(patch);
  }

  void _insertSlot(MarkdownSlotKind kind) {
    final patch = MarkdownEditActions.insertSlotSection(
      text: widget.controller.text,
      selection: widget.controller.selection,
      kind: kind,
    );
    if (patch == null) {
      _showSnack('${_slotLabel(kind)} 섹션이 이미 있습니다.');
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

  void _selectMatch(int matchStart, String query) {
    widget.controller.selection = TextSelection(
      baseOffset: matchStart,
      extentOffset: matchStart + query.length,
    );
    _focusNode.requestFocus();
    setState(() {});
  }

  void _findNext({bool forward = true}) {
    final query = _findCtrl.text;
    if (query.isEmpty) return;
    final text = widget.controller.text;
    final from = widget.controller.selection.isValid
        ? (forward
            ? widget.controller.selection.end
            : widget.controller.selection.start)
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

    if (match != null) {
      _selectMatch(match, query);
    } else {
      _showSnack('찾을 수 없습니다.');
    }
  }

  void _replaceCurrent() {
    final query = _findCtrl.text;
    if (query.isEmpty) return;
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    if (!sel.isValid || sel.start == sel.end) {
      _findNext();
      return;
    }
    final selected = text.substring(sel.start, sel.end);
    if (selected.toLowerCase() != query.toLowerCase()) {
      _findNext();
      return;
    }
    _applyPatch(MarkdownFindReplace.replaceAt(
      text: text,
      matchStart: sel.start,
      query: query,
      replacement: _replaceCtrl.text,
    ));
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
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text;

    final importedImage = await SanctumImageImport.importClipboardTextPath(raw);
    if (importedImage != null) {
      _applyPatch(MarkdownEditActions.insertImage(
        text: widget.controller.text,
        selection: widget.controller.selection,
        imagePath: importedImage,
      ));
      return;
    }

    if (raw == null || raw.trim().isEmpty) {
      _showSnack('클립보드에 붙여넣을 내용이 없습니다.');
      return;
    }
    final normalized = MarkdownSmartPaste.normalizeForBody(raw);
    _applyPatch(MarkdownEditActions.insertText(
      text: widget.controller.text,
      selection: widget.controller.selection,
      insert: normalized,
    ));
  }

  Future<void> _insertEntityLink() async {
    final onRequest = widget.onRequestEntityLink;
    if (onRequest == null) {
      _showSnack('Entity 연결을 사용할 수 없습니다.');
      return;
    }

    final text = widget.controller.text;
    final sel = widget.controller.selection;
    var selectedText = '';
    if (sel.isValid && !sel.isCollapsed) {
      selectedText = text.substring(sel.start, sel.end);
    }

    final picked = await onRequest(context, selectedText);
    if (!mounted || picked == null) return;

    _applyPatch(MarkdownEditActions.insertWikiLink(
      text: text,
      selection: sel,
      entityId: picked.entityId,
      title: picked.title,
    ));
  }

  Future<void> _insertImage() async {
    if (!SanctumImageImport.canImport) {
      _showSnack('이미지 삽입은 Sanctum 볼트 연결 후 사용할 수 있습니다.');
      return;
    }

    final normalized = await SanctumImageImport.pickAndImport();
    if (!mounted || normalized == null) return;

    _applyPatch(MarkdownEditActions.insertImage(
      text: widget.controller.text,
      selection: widget.controller.selection,
      imagePath: normalized,
    ));
  }

  Future<void> _insertCustomSection() async {
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
    if (title == null || title.trim().isEmpty) return;
    _applyPatch(MarkdownEditActions.insertCustomSection(
      text: widget.controller.text,
      selection: widget.controller.selection,
      title: title,
    ));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _slotLabel(MarkdownSlotKind kind) {
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

  List<MarkdownSectionEntry> get _sections =>
      MarkdownSectionIndex.parseHeadings(widget.controller.text);

  @override
  Widget build(BuildContext context) {
    final sections = _sections;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyB, control: true): _BoldIntent(),
        SingleActivator(LogicalKeyboardKey.keyI, control: true): _ItalicIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true): _FindIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, control: true): _LinkIntent(),
        SingleActivator(LogicalKeyboardKey.digit1, control: true): _H1Intent(),
        SingleActivator(LogicalKeyboardKey.digit2, control: true): _H2Intent(),
        SingleActivator(LogicalKeyboardKey.digit3, control: true): _H3Intent(),
        SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true):
            _SmartPasteIntent(),
      },
      child: Actions(
        actions: {
          _BoldIntent: CallbackAction<_BoldIntent>(
            onInvoke: (_) {
              _wrap('**', '**', placeholder: '굵게');
              return null;
            },
          ),
          _ItalicIntent: CallbackAction<_ItalicIntent>(
            onInvoke: (_) {
              _wrap('*', '*', placeholder: '기울임');
              return null;
            },
          ),
          _FindIntent: CallbackAction<_FindIntent>(
            onInvoke: (_) {
              _toggleFindBar();
              return null;
            },
          ),
          _LinkIntent: CallbackAction<_LinkIntent>(
            onInvoke: (_) {
              _applyPatch(MarkdownEditActions.insertLink(
                text: widget.controller.text,
                selection: widget.controller.selection,
              ));
              return null;
            },
          ),
          _H1Intent: CallbackAction<_H1Intent>(
            onInvoke: (_) {
              _applyPatch(MarkdownEditActions.insertHeading(
                text: widget.controller.text,
                selection: widget.controller.selection,
                level: 1,
              ));
              return null;
            },
          ),
          _H2Intent: CallbackAction<_H2Intent>(
            onInvoke: (_) {
              _applyPatch(MarkdownEditActions.insertHeading(
                text: widget.controller.text,
                selection: widget.controller.selection,
                level: 2,
              ));
              return null;
            },
          ),
          _H3Intent: CallbackAction<_H3Intent>(
            onInvoke: (_) {
              _applyPatch(MarkdownEditActions.insertHeading(
                text: widget.controller.text,
                selection: widget.controller.selection,
                level: 3,
              ));
              return null;
            },
          ),
          _SmartPasteIntent: CallbackAction<_SmartPasteIntent>(
            onInvoke: (_) {
              _smartPaste();
              return null;
            },
          ),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MarkdownEditorToolbar(
              canUndo: _undoStack.isNotEmpty,
              canRedo: _redoStack.isNotEmpty,
              sections: sections,
              vaultLinked: AkashaFileService().vaultPath != null,
              onUndo: _undo,
              onRedo: _redo,
              onBold: () => _wrap('**', '**', placeholder: '굵게'),
              onItalic: () => _wrap('*', '*', placeholder: '기울임'),
              onStrike: () => _wrap('~~', '~~', placeholder: '취소선'),
              onCode: () => _wrap('`', '`', placeholder: 'code'),
              onH1: () => _applyPatch(MarkdownEditActions.insertHeading(
                text: widget.controller.text,
                selection: widget.controller.selection,
                level: 1,
              )),
              onH2: () => _applyPatch(MarkdownEditActions.insertHeading(
                text: widget.controller.text,
                selection: widget.controller.selection,
                level: 2,
              )),
              onH3: () => _applyPatch(MarkdownEditActions.insertHeading(
                text: widget.controller.text,
                selection: widget.controller.selection,
                level: 3,
              )),
              onQuote: () => _applyPatch(MarkdownEditActions.prefixLines(
                text: widget.controller.text,
                selection: widget.controller.selection,
                prefix: '> ',
              )),
              onBullet: () => _applyPatch(MarkdownEditActions.prefixLines(
                text: widget.controller.text,
                selection: widget.controller.selection,
                prefix: '- ',
              )),
              onNumbered: () => _applyPatch(MarkdownEditActions.prefixLines(
                text: widget.controller.text,
                selection: widget.controller.selection,
                prefix: '1. ',
              )),
              onLink: () => _applyPatch(MarkdownEditActions.insertLink(
                text: widget.controller.text,
                selection: widget.controller.selection,
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
                  text: widget.controller.text,
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
                        _slashSelectedIndex = (_slashSelectedIndex + 1) % candidates.length;
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
                  controller: widget.controller,
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
      ),
    );
  }
}

