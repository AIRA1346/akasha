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
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: AkashaTypography.editorMono,
      cursorColor: AkashaColors.editorAccent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AkashaTypography.editorMono.copyWith(
          color: AkashaColors.textCaption,
        ),
        filled: true,
        fillColor: AkashaColors.editorFieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AkashaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AkashaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AkashaColors.editorAccent.withValues(alpha: 0.45),
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
