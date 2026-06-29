part of 'markdown_body_editor.dart';

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
                        color: isSelected ? Colors.tealAccent : AkashaColors.textSecondary,
                      ),
                      title: Text(
                        cmd.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.tealAccent : AkashaColors.textPrimary,
                        ),
                      ),
                      subtitle: cmd.description.isNotEmpty
                          ? Text(
                              cmd.description,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.tealAccent.withValues(alpha: 0.7)
                                    : AkashaColors.textMuted,
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
