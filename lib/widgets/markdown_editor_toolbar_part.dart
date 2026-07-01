part of 'markdown_body_editor.dart';

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
    required this.onInsertCast,
    required this.onInsertGallery,
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
  final VoidCallback onInsertCast;
  final VoidCallback onInsertGallery;
  final VoidCallback onInsertSynopsis;
  final VoidCallback onInsertQuotes;
  final VoidCallback onInsertMemo;
  final VoidCallback onInsertCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return Material(
      color: AkashaColors.sidebarFooter,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 0,
          runSpacing: 0,
          children: [
            _btn(
              Icons.undo,
              l10n?.actionUndo ?? '되돌리기',
              onUndo,
              enabled: canUndo,
            ),
            _btn(
              Icons.redo,
              l10n?.actionRedo ?? '다시실행',
              onRedo,
              enabled: canRedo,
            ),
            _sep(),
            _btn(Icons.format_bold, l10n?.tooltipBold ?? '굵게 (Ctrl+B)', onBold),
            _btn(
              Icons.format_italic,
              l10n?.tooltipItalic ?? '기울임 (Ctrl+I)',
              onItalic,
            ),
            _btn(
              Icons.format_strikethrough,
              l10n?.tooltipStrikethrough ?? '취소선',
              onStrike,
            ),
            _btn(Icons.code, l10n?.tooltipInlineCode ?? '인라인 코드', onCode),
            _sep(),
            _btn(Icons.title, l10n?.tooltipH1 ?? '제목 1', onH1),
            _btn(Icons.format_size, l10n?.tooltipH2 ?? '제목 2', onH2),
            _btn(Icons.text_fields, l10n?.tooltipH3 ?? '제목 3', onH3),
            _sep(),
            _btn(
              Icons.format_quote,
              l10n?.tooltipBlockquote ?? '인용 (> )',
              onQuote,
            ),
            _btn(
              Icons.format_list_bulleted,
              l10n?.tooltipBulletedList ?? '글머리',
              onBullet,
            ),
            _btn(
              Icons.format_list_numbered,
              l10n?.tooltipNumberedList ?? '번호 목록',
              onNumbered,
            ),
            _btn(Icons.link, l10n?.tooltipLink ?? '링크', onLink),
            _btn(
              Icons.hub_outlined,
              l10n?.tooltipLinkEntity ?? 'Entity 연결',
              onEntityLink,
              enabled: entityLinkEnabled,
            ),
            _btn(
              Icons.image_outlined,
              vaultLinked
                  ? (l10n?.tooltipInsertImage ?? '이미지 삽입')
                  : (l10n?.tooltipImageVaultRequired ?? '이미지 (볼트 필요)'),
              onImage,
              enabled: vaultLinked,
            ),
            _btn(Icons.search, l10n?.tooltipFind ?? '찾기 (Ctrl+F)', onFind),
            _btn(
              Icons.content_paste_go,
              l10n?.tooltipSmartPaste ?? '스마트 붙여넣기 (Ctrl+Shift+V)',
              onSmartPaste,
            ),
            _sep(),
            PopupMenuButton<MarkdownSectionEntry>(
              tooltip: l10n?.tooltipTableOfContents ?? '섹션 목차',
              enabled: sections.isNotEmpty,
              icon: Icon(
                Icons.list_alt,
                size: 18,
                color: sections.isEmpty
                    ? AkashaColors.textCaption
                    : AkashaColors.textSecondary,
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
              tooltip: l10n?.tooltipInsertSection ?? '섹션 삽입',
              icon: Icon(
                Icons.add_circle_outline,
                size: 18,
                color: AkashaColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              onSelected: (v) {
                switch (v) {
                  case 'cast':
                    onInsertCast();
                  case 'gallery':
                    onInsertGallery();
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
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'cast',
                  child: Text(l10n?.sectionCast ?? '👥 출연'),
                ),
                PopupMenuItem(
                  value: 'gallery',
                  child: Text(l10n?.sectionGallery ?? '🖼 갤러리'),
                ),
                PopupMenuItem(
                  value: 'synopsis',
                  child: Text(l10n?.sectionSynopsis ?? '📋 시놉시스'),
                ),
                PopupMenuItem(
                  value: 'quotes',
                  child: Text(l10n?.sectionQuotes ?? '🎬 명장면 & 명대사'),
                ),
                PopupMenuItem(
                  value: 'memo',
                  child: Text(l10n?.sectionMemo ?? '📝 메모'),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'custom',
                  child: Text(l10n?.actionAddCustomSection ?? '＋ 커스텀 섹션…'),
                ),
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
    color: AkashaColors.border,
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
      color: AkashaColors.textSecondary,
      disabledColor: AkashaColors.textCaption,
    );
  }
}
