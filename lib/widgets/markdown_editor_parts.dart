part of 'markdown_body_editor.dart';

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
    required this.selectedIndex,
    required this.onSelect,
  });

  final MarkdownSlashMatch match;
  final int selectedIndex;
  final ValueChanged<MarkdownSlashCommand> onSelect;

  IconData _getIconForCommand(String id) {
    switch (id) {
      case 'synopsis':
        return Icons.article_outlined;
      case 'quotes':
        return Icons.movie_filter_outlined;
      case 'memo':
        return Icons.edit_note_outlined;
      case 'quote_line':
        return Icons.format_quote_outlined;
      case 'link':
        return Icons.link_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'code_block':
        return Icons.code_outlined;
      case 'hr':
        return Icons.horizontal_rule_outlined;
      case 'h1':
        return Icons.looks_one_outlined;
      case 'h2':
        return Icons.looks_two_outlined;
      case 'h3':
        return Icons.looks_3_outlined;
      case 'bullet':
        return Icons.format_list_bulleted_outlined;
      case 'numbered':
        return Icons.format_list_numbered_outlined;
      default:
        return Icons.terminal_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = match.candidates.take(8).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xE5181824), // 90% opacity deep navy/black
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final cmd = candidates[index];
                final isSelected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Material(
                    color: isSelected
                        ? const Color(0xFF2E2E42) // Highlighted background
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: isSelected
                            ? BorderSide(
                                color: Colors.tealAccent.withValues(alpha: 0.35),
                                width: 1.0,
                              )
                            : BorderSide.none,
                      ),
                      leading: Icon(
                        _getIconForCommand(cmd.id),
                        size: 18,
                        color: isSelected ? Colors.tealAccent : Colors.grey[400],
                      ),
                      title: Text(
                        cmd.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.tealAccent : Colors.grey[200],
                        ),
                      ),
                      subtitle: cmd.description.isNotEmpty
                          ? Text(
                              cmd.description,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.tealAccent.withValues(alpha: 0.7)
                                    : Colors.grey[500],
                              ),
                            )
                          : null,
                      onTap: () => onSelect(cmd),
                    ),
                  ),
                );
              },
            ),
          ),
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
    required this.onEntityLink,
    required this.entityLinkEnabled,
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
  final VoidCallback onEntityLink;
  final bool entityLinkEnabled;
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
              Icons.hub_outlined,
              'Entity 연결',
              onEntityLink,
              enabled: entityLinkEnabled,
            ),
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
