part of 'markdown_body_editor.dart';

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
    final palette = context.akashaPalette;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: AkashaTypography.editorMono,
      cursorColor: palette.accent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AkashaTypography.editorMono.copyWith(
          color: AkashaColors.textCaption,
        ),
        filled: true,
        fillColor: palette.workbenchEditor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.borderSubtle(0.22)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.borderSubtle(0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.45)),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
