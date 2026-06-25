part of 'markdown_body_editor.dart';

class _MarkdownEditorShortcutBindings extends StatelessWidget {
  const _MarkdownEditorShortcutBindings({
    required this.child,
    required this.controller,
    required this.onWrap,
    required this.onApplyPatch,
    required this.onToggleFindBar,
    required this.onSmartPaste,
  });

  final Widget child;
  final TextEditingController controller;
  final void Function(String left, String right, {String placeholder}) onWrap;
  final void Function(TextEditPatch patch) onApplyPatch;
  final VoidCallback onToggleFindBar;
  final VoidCallback onSmartPaste;

  @override
  Widget build(BuildContext context) {
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
              onWrap('**', '**', placeholder: '굵게');
              return null;
            },
          ),
          _ItalicIntent: CallbackAction<_ItalicIntent>(
            onInvoke: (_) {
              onWrap('*', '*', placeholder: '기울임');
              return null;
            },
          ),
          _FindIntent: CallbackAction<_FindIntent>(
            onInvoke: (_) {
              onToggleFindBar();
              return null;
            },
          ),
          _LinkIntent: CallbackAction<_LinkIntent>(
            onInvoke: (_) {
              onApplyPatch(MarkdownEditActions.insertLink(
                text: controller.text,
                selection: controller.selection,
              ));
              return null;
            },
          ),
          _H1Intent: CallbackAction<_H1Intent>(
            onInvoke: (_) {
              onApplyPatch(MarkdownEditActions.insertHeading(
                text: controller.text,
                selection: controller.selection,
                level: 1,
              ));
              return null;
            },
          ),
          _H2Intent: CallbackAction<_H2Intent>(
            onInvoke: (_) {
              onApplyPatch(MarkdownEditActions.insertHeading(
                text: controller.text,
                selection: controller.selection,
                level: 2,
              ));
              return null;
            },
          ),
          _H3Intent: CallbackAction<_H3Intent>(
            onInvoke: (_) {
              onApplyPatch(MarkdownEditActions.insertHeading(
                text: controller.text,
                selection: controller.selection,
                level: 3,
              ));
              return null;
            },
          ),
          _SmartPasteIntent: CallbackAction<_SmartPasteIntent>(
            onInvoke: (_) {
              onSmartPaste();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
