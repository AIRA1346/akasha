import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/file_service.dart';
import '../services/markdown_body_merger.dart';
import '../utils/markdown_edit_actions.dart';
import '../utils/markdown_find_replace.dart';
import '../utils/markdown_section_index.dart';
import '../utils/markdown_slash_commands.dart';
import '../utils/markdown_smart_paste.dart';

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

  const MarkdownBodyEditor({
    super.key,
    required this.controller,
    required this.onChanged,
    this.isDirty = false,
    this.isSaving = false,
    this.mdFilePath,
    this.lastSavedAt,
    this.mode = MarkdownEditorMode.body,
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
    if (raw == null || raw.trim().isEmpty) {
      _showSnack('클립보드에 텍스트가 없습니다.');
      return;
    }
    final normalized = MarkdownSmartPaste.normalizeForBody(raw);
    _applyPatch(MarkdownEditActions.insertText(
      text: widget.controller.text,
      selection: widget.controller.selection,
      insert: normalized,
    ));
  }

  Future<void> _insertImage() async {
    final service = AkashaFileService();
    if (service.vaultPath == null) {
      _showSnack('이미지 삽입은 Sanctum 볼트 연결 후 사용할 수 있습니다.');
      return;
    }

    final fileResult = await FilePicker.pickFiles(type: FileType.image);
    if (fileResult == null || fileResult.files.single.path == null) return;

    final relativePath = await service.importPosterImage(
      fileResult.files.single.path!,
    );
    if (!mounted || relativePath == null) return;

    final normalized = relativePath.replaceAll('\\', '/');
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
              onImage: _insertImage,
              onFind: _toggleFindBar,
              onSmartPaste: _smartPaste,
              onJumpToSection: _jumpToSection,
              onInsertSynopsis: () => _insertSlot(MarkdownSlotKind.synopsis),
              onInsertQuotes: () => _insertSlot(MarkdownSlotKind.quotes),
              onInsertMemo: () => _insertSlot(MarkdownSlotKind.memo),
              onInsertCustom: _insertCustomSection,
            ),
            if (_slashMatch != null) ...[
              const SizedBox(height: 4),
              _MarkdownSlashMenu(
                match: _slashMatch!,
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
              child: _MarkdownTextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: _onEditorChanged,
                hintText: widget.mode == MarkdownEditorMode.fullFile
                    ? '---\nwork_id: ...\n---\n\n# 본문'
                    : '# 📋 시놉시스\n...\n\n# 🎬 명장면 & 명대사\n> ...\n\n# 📝 메모\n...',
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

class _MarkdownEditorStatusBar extends StatelessWidget {
  const _MarkdownEditorStatusBar({
    required this.lineNumber,
    required this.sectionLabel,
    required this.isDirty,
    this.isSaving = false,
    this.lastSavedAt,
    this.hint,
  });

  final int lineNumber;
  final String sectionLabel;
  final bool isDirty;
  final bool isSaving;
  final DateTime? lastSavedAt;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Text(
            'Ln $lineNumber',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sectionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
          if (isSaving)
            Text(
              '저장 중…',
              style: TextStyle(fontSize: 10, color: Colors.tealAccent),
            )
          else if (!isDirty && lastSavedAt != null)
            Text(
              '저장됨 ${_formatTime(lastSavedAt!)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          if (hint != null && !isSaving) ...[
            const SizedBox(width: 8),
            Text(
              hint!,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
          if (isDirty && !isSaving)
            Text(
              '● 미저장',
              style: TextStyle(
                fontSize: 10,
                color: Colors.amber[700],
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _BoldIntent extends Intent {
  const _BoldIntent();
}

class _ItalicIntent extends Intent {
  const _ItalicIntent();
}

class _FindIntent extends Intent {
  const _FindIntent();
}

class _SmartPasteIntent extends Intent {
  const _SmartPasteIntent();
}

class _LinkIntent extends Intent {
  const _LinkIntent();
}

class _H1Intent extends Intent {
  const _H1Intent();
}

class _H2Intent extends Intent {
  const _H2Intent();
}

class _H3Intent extends Intent {
  const _H3Intent();
}

class _MarkdownSlashMenu extends StatelessWidget {
  const _MarkdownSlashMenu({
    required this.match,
    required this.onSelect,
  });

  final MarkdownSlashMatch match;
  final ValueChanged<MarkdownSlashCommand> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E2C),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            for (final cmd in match.candidates.take(8))
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(
                  cmd.label,
                  style: const TextStyle(fontSize: 12),
                ),
                subtitle: cmd.description.isNotEmpty
                    ? Text(
                        cmd.description,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      )
                    : null,
                onTap: () => onSelect(cmd),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarkdownTextField extends StatelessWidget {
  const _MarkdownTextField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(
        fontSize: 13,
        height: 1.45,
        fontFamily: 'Consolas',
        color: Colors.grey[200],
      ),
      cursorColor: Colors.tealAccent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[700], height: 1.45),
        filled: true,
        fillColor: const Color(0xFF0E0E16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2D2D44)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2D2D44)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.tealAccent.withValues(alpha: 0.45),
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}

class _MarkdownFindBar extends StatelessWidget {
  const _MarkdownFindBar({
    required this.findController,
    required this.replaceController,
    required this.findFocusNode,
    required this.matchCount,
    required this.onFindNext,
    required this.onFindPrevious,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onClose,
    required this.onChanged,
  });

  final TextEditingController findController;
  final TextEditingController replaceController;
  final FocusNode findFocusNode;
  final int matchCount;
  final VoidCallback onFindNext;
  final VoidCallback onFindPrevious;
  final VoidCallback onReplace;
  final VoidCallback onReplaceAll;
  final VoidCallback onClose;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A26),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: findController,
                focusNode: findFocusNode,
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onFindNext(),
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '찾기',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              findController.text.isEmpty ? '' : '$matchCount',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
            IconButton(
              onPressed: onFindPrevious,
              icon: const Icon(Icons.keyboard_arrow_up, size: 18),
              tooltip: '이전',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onFindNext,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              tooltip: '다음',
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: replaceController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '바꿀 텍스트',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(onPressed: onReplace, child: const Text('바꾸기')),
            TextButton(onPressed: onReplaceAll, child: const Text('전체')),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 16),
              tooltip: '닫기',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSnapshot {
  const _EditorSnapshot({required this.text, required this.selection});

  final String text;
  final TextSelection selection;
}

class _MarkdownEditorToolbar extends StatelessWidget {
  const _MarkdownEditorToolbar({
    required this.canUndo,
    required this.canRedo,
    required this.sections,
    required this.vaultLinked,
    required this.onUndo,
    required this.onRedo,
    required this.onBold,
    required this.onItalic,
    required this.onStrike,
    required this.onCode,
    required this.onH1,
    required this.onH2,
    required this.onH3,
    required this.onQuote,
    required this.onBullet,
    required this.onNumbered,
    required this.onLink,
    required this.onImage,
    required this.onFind,
    required this.onSmartPaste,
    required this.onJumpToSection,
    required this.onInsertSynopsis,
    required this.onInsertQuotes,
    required this.onInsertMemo,
    required this.onInsertCustom,
  });

  final bool canUndo;
  final bool canRedo;
  final List<MarkdownSectionEntry> sections;
  final bool vaultLinked;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrike;
  final VoidCallback onCode;
  final VoidCallback onH1;
  final VoidCallback onH2;
  final VoidCallback onH3;
  final VoidCallback onQuote;
  final VoidCallback onBullet;
  final VoidCallback onNumbered;
  final VoidCallback onLink;
  final VoidCallback onImage;
  final VoidCallback onFind;
  final VoidCallback onSmartPaste;
  final ValueChanged<MarkdownSectionEntry> onJumpToSection;
  final VoidCallback onInsertSynopsis;
  final VoidCallback onInsertQuotes;
  final VoidCallback onInsertMemo;
  final VoidCallback onInsertCustom;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161622),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 0,
          runSpacing: 0,
          children: [
            _btn(Icons.undo, '되돌리기', onUndo, enabled: canUndo),
            _btn(Icons.redo, '다시실행', onRedo, enabled: canRedo),
            _sep(),
            _btn(Icons.format_bold, '굵게 (Ctrl+B)', onBold),
            _btn(Icons.format_italic, '기울임 (Ctrl+I)', onItalic),
            _btn(Icons.format_strikethrough, '취소선', onStrike),
            _btn(Icons.code, '인라인 코드', onCode),
            _sep(),
            _btn(Icons.title, '제목 1', onH1),
            _btn(Icons.format_size, '제목 2', onH2),
            _btn(Icons.text_fields, '제목 3', onH3),
            _sep(),
            _btn(Icons.format_quote, '인용 (> )', onQuote),
            _btn(Icons.format_list_bulleted, '글머리', onBullet),
            _btn(Icons.format_list_numbered, '번호 목록', onNumbered),
            _btn(Icons.link, '링크', onLink),
            _btn(
              Icons.image_outlined,
              vaultLinked ? '이미지 삽입' : '이미지 (볼트 필요)',
              onImage,
              enabled: vaultLinked,
            ),
            _btn(Icons.search, '찾기 (Ctrl+F)', onFind),
            _btn(Icons.content_paste_go, '스마트 붙여넣기 (Ctrl+Shift+V)', onSmartPaste),
            _sep(),
            PopupMenuButton<MarkdownSectionEntry>(
              tooltip: '섹션 목차',
              enabled: sections.isNotEmpty,
              icon: Icon(
                Icons.list_alt,
                size: 18,
                color: sections.isEmpty ? Colors.grey[700] : Colors.grey[300],
              ),
              padding: EdgeInsets.zero,
              onSelected: onJumpToSection,
              itemBuilder: (_) => [
                for (final s in sections)
                  PopupMenuItem(
                    value: s,
                    child: Text(
                      s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: '섹션 삽입',
              icon: Icon(Icons.add_circle_outline,
                  size: 18, color: Colors.grey[300]),
              padding: EdgeInsets.zero,
              onSelected: (v) {
                switch (v) {
                  case 'synopsis':
                    onInsertSynopsis();
                  case 'quotes':
                    onInsertQuotes();
                  case 'memo':
                    onInsertMemo();
                  case 'custom':
                    onInsertCustom();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'synopsis', child: Text('📋 시놉시스')),
                PopupMenuItem(
                  value: 'quotes',
                  child: Text('🎬 명장면 & 명대사'),
                ),
                PopupMenuItem(value: 'memo', child: Text('📝 메모')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'custom', child: Text('＋ 커스텀 섹션…')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sep() => Container(
        width: 1,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: const Color(0xFF2D2D44),
      );

  Widget _btn(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: Colors.grey[300],
      disabledColor: Colors.grey[700],
    );
  }
}
