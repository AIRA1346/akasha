import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../services/akasha_window_controller.dart';
import '../theme/akasha_palette.dart';
import '../utils/app_l10n.dart';

/// App-owned Windows frame. Geometry is intentionally independent of themes.
class AkashaWindowFrame extends StatelessWidget {
  const AkashaWindowFrame({
    super.key,
    required this.controller,
    required this.child,
  });

  static const double chromeHeight = 32;

  final AkashaWindowController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AkashaWindowScope(
      controller: controller,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f11): () {
            unawaited(controller.toggleFullScreen());
          },
        },
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!controller.isFullScreen)
                  AkashaWindowChrome(controller: controller),
                Expanded(child: child),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AkashaWindowChrome extends StatelessWidget {
  const AkashaWindowChrome({
    super.key,
    required this.controller,
    this.dragArea,
  });

  final AkashaWindowController controller;

  /// Test seam; production uses the plugin drag area.
  final Widget Function(Widget child)? dragArea;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final l10n = lookupAppL10n(context);
    final title = Row(
      children: [
        const SizedBox(width: 10),
        Image.asset(
          'assets/branding/akasha_mark.png',
          width: 16,
          height: 16,
          errorBuilder: (_, _, _) =>
              Icon(Icons.auto_awesome, size: 15, color: palette.accent),
        ),
        const SizedBox(width: 8),
        Text(
          'AKASHA',
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );

    final draggable = dragArea?.call(title) ?? DragToMoveArea(child: title);
    return Container(
      key: const ValueKey('akasha-window-chrome'),
      width: double.infinity,
      height: AkashaWindowFrame.chromeHeight,
      decoration: BoxDecoration(
        color: palette.sidebar.withValues(alpha: 0.97),
        border: Border(bottom: BorderSide(color: palette.borderSubtle(0.48))),
      ),
      child: Row(
        children: [
          Expanded(child: draggable),
          _WindowControlButton(
            key: const ValueKey('window-control-minimize'),
            tooltip: l10n?.windowMinimize ?? '최소화',
            icon: Icons.minimize_rounded,
            onPressed: () => unawaited(controller.minimize()),
          ),
          _WindowControlButton(
            key: const ValueKey('window-control-maximize'),
            tooltip: controller.isMaximized
                ? (l10n?.windowRestore ?? '이전 크기로 복원')
                : (l10n?.windowMaximize ?? '최대화'),
            icon: controller.isMaximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            onPressed: () => unawaited(controller.toggleMaximized()),
          ),
          _WindowControlButton(
            key: const ValueKey('window-control-close'),
            tooltip: l10n?.windowClose ?? '닫기',
            icon: Icons.close_rounded,
            isClose: true,
            onPressed: () => unawaited(controller.close()),
          ),
        ],
      ),
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  const _WindowControlButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _setInteraction({bool? hovered, bool? pressed}) {
    if (!mounted) return;
    final nextHovered = hovered ?? _hovered;
    final nextPressed = pressed ?? _pressed;
    if (nextHovered == _hovered && nextPressed == _pressed) return;
    setState(() {
      _hovered = nextHovered;
      _pressed = nextPressed;
    });
  }

  void _activate() {
    // A native window operation can interrupt Flutter's pointer-exit sequence.
    // Reset first so minimize/maximize/close never leaves a stale hover layer.
    _setInteraction(hovered: false, pressed: false);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final Color background;
    if (widget.isClose && _pressed) {
      background = const Color(0xFFB12418);
    } else if (widget.isClose && _hovered) {
      background = const Color(0xFFC42B1C);
    } else if (_pressed) {
      background = palette.textPrimary.withValues(alpha: 0.05);
    } else if (_hovered) {
      background = palette.textPrimary.withValues(alpha: 0.08);
    } else {
      background = Colors.transparent;
    }

    return Semantics(
      button: true,
      label: widget.tooltip,
      onTap: _activate,
      child: MouseRegion(
        cursor: SystemMouseCursors.basic,
        onEnter: (_) => _setInteraction(hovered: true),
        onExit: (_) => _setInteraction(hovered: false, pressed: false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setInteraction(pressed: true),
          onTapCancel: () => _setInteraction(pressed: false),
          onTapUp: (_) => _setInteraction(pressed: false),
          onTap: _activate,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: 46,
            height: 32,
            color: background,
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 15,
              color: widget.isClose && (_hovered || _pressed)
                  ? Colors.white
                  : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class AkashaWindowScope extends InheritedNotifier<AkashaWindowController> {
  const AkashaWindowScope({
    super.key,
    required AkashaWindowController controller,
    required super.child,
  }) : super(notifier: controller);

  static AkashaWindowController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AkashaWindowScope>()
        ?.notifier;
  }
}
