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
      style: TextStyle(
        fontSize: 13,
        height: 1.45,
        fontFamily: 'Consolas',
        color: AkashaColors.textPrimary,
      ),
      cursorColor: Colors.tealAccent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AkashaColors.textCaption, height: 1.45),
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
