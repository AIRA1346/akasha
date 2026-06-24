import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ctrl+S 저장 단축키 래퍼.
class WorkbenchSaveShortcuts extends StatelessWidget {
  const WorkbenchSaveShortcuts({
    super.key,
    required this.onSave,
    required this.child,
  });

  final VoidCallback onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
      },
      child: Actions(
        actions: {
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              onSave();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}
