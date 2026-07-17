import 'package:flutter/material.dart';

import '../../theme/akasha_palette.dart';
import 'shell_layout_spec.dart';

/// Slot-based, theme-independent frame for the responsive Home shell.
///
/// The center and preview slots always stay under the same Stack hierarchy.
/// Breakpoint changes update only their geometry, preserving local widget state.
class ShellLayoutFrame extends StatefulWidget {
  const ShellLayoutFrame({
    super.key,
    required this.layoutSpec,
    required this.sidebarOpen,
    required this.onDismissSidebar,
    required this.sidebar,
    required this.center,
    this.preview,
    this.previewVisible = true,
  });

  static const sidebarFrameKey = ValueKey<String>('home-shell-sidebar-frame');
  static const centerKey = ValueKey<String>('home-shell-center');
  static const previewKey = ValueKey<String>('home-shell-preview');

  final ShellLayoutSpec layoutSpec;
  final bool sidebarOpen;
  final VoidCallback onDismissSidebar;
  final Widget sidebar;
  final Widget center;
  final Widget? preview;
  final bool previewVisible;

  @override
  State<ShellLayoutFrame> createState() => _ShellLayoutFrameState();
}

class _ShellLayoutFrameState extends State<ShellLayoutFrame> {
  late final FocusScopeNode _drawerFocusScope = FocusScopeNode(
    debugLabel: 'HomeShell.drawer',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  FocusNode? _focusBeforeDrawer;
  int _focusTransitionGeneration = 0;

  bool get _isDrawerOpen => _drawerIsOpen(widget);

  @override
  void initState() {
    super.initState();
    if (_isDrawerOpen) {
      _captureFocusAndEnterDrawer();
    }
  }

  @override
  void didUpdateWidget(ShellLayoutFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasDrawerOpen = _drawerIsOpen(oldWidget);
    if (!wasDrawerOpen && _isDrawerOpen) {
      _captureFocusAndEnterDrawer();
    } else if (wasDrawerOpen && !_isDrawerOpen) {
      _restoreFocusAfterDrawer();
    }
  }

  @override
  void dispose() {
    _focusTransitionGeneration++;
    _drawerFocusScope.dispose();
    super.dispose();
  }

  bool _drawerIsOpen(ShellLayoutFrame frame) {
    return frame.sidebarOpen &&
        frame.layoutSpec.sidebarPresentation == ShellSidebarPresentation.drawer;
  }

  void _captureFocusAndEnterDrawer() {
    _focusBeforeDrawer ??= FocusManager.instance.primaryFocus;
    final generation = ++_focusTransitionGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _focusTransitionGeneration) return;
      if (!_isDrawerOpen || _drawerFocusScope.context == null) return;
      _drawerFocusScope.requestFocus();
      _drawerFocusScope.nextFocus();
    });
  }

  void _restoreFocusAfterDrawer() {
    final focusToRestore = _focusBeforeDrawer;
    final generation = ++_focusTransitionGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _focusTransitionGeneration) return;
      if (_isDrawerOpen) return;
      _focusBeforeDrawer = null;
      if (focusToRestore?.context == null) return;
      if (focusToRestore!.canRequestFocus) {
        focusToRestore.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sidebarTraversalEdgeBehavior = _isDrawerOpen
        ? TraversalEdgeBehavior.closedLoop
        : TraversalEdgeBehavior.parentScope;
    _drawerFocusScope.traversalEdgeBehavior = sidebarTraversalEdgeBehavior;
    _drawerFocusScope.directionalTraversalEdgeBehavior =
        sidebarTraversalEdgeBehavior;
    final hasPreview = widget.preview != null;
    final showsPreview = hasPreview && widget.previewVisible;
    final isSheet =
        widget.layoutSpec.previewPresentation == ShellPreviewPresentation.sheet;
    final centerLeft =
        widget.sidebarOpen &&
            widget.layoutSpec.sidebarPresentation ==
                ShellSidebarPresentation.persistent
        ? widget.layoutSpec.sidebarWidth
        : 0.0;
    final centerRight =
        showsPreview &&
            widget.layoutSpec.previewPresentation ==
                ShellPreviewPresentation.inline
        ? widget.layoutSpec.previewWidth
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          key: const ValueKey<String>('home-shell-center-position'),
          top: 0,
          right: centerRight,
          bottom: 0,
          left: centerLeft,
          child: ExcludeFocus(
            excluding: _isDrawerOpen,
            child: _buildCenterFrame(),
          ),
        ),
        if (hasPreview)
          Positioned.fill(
            key: const ValueKey<String>('home-shell-preview-position'),
            child: Offstage(
              offstage: !showsPreview,
              child: TickerMode(
                enabled: showsPreview,
                child: ExcludeSemantics(
                  excluding: !showsPreview,
                  child: ExcludeFocus(
                    excluding: _isDrawerOpen || !showsPreview,
                    child: Align(
                      alignment: isSheet
                          ? Alignment.bottomCenter
                          : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: isSheet ? 1 : null,
                        heightFactor: isSheet ? 0.72 : 1,
                        child: SizedBox(
                          width: isSheet
                              ? double.infinity
                              : widget.layoutSpec.previewWidth,
                          child: _buildPreviewSurface(widget.preview!),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_isDrawerOpen)
          ModalBarrier(
            color: context.akashaPalette.scrim,
            dismissible: true,
            onDismiss: widget.onDismissSidebar,
          ),
        if (widget.sidebarOpen)
          Positioned(
            key: const ValueKey<String>('home-shell-sidebar-position'),
            top: 0,
            bottom: 0,
            left: 0,
            width: widget.layoutSpec.sidebarWidth,
            child: FocusScope.withExternalFocusNode(
              focusScopeNode: _drawerFocusScope,
              child: _buildSidebarFrame(),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarFrame() {
    return SizedBox(
      key: ShellLayoutFrame.sidebarFrameKey,
      width: widget.layoutSpec.sidebarWidth,
      child: widget.sidebar,
    );
  }

  Widget _buildCenterFrame() {
    return KeyedSubtree(key: ShellLayoutFrame.centerKey, child: widget.center);
  }

  Widget _buildPreviewSurface(Widget child) {
    return Builder(
      builder: (context) => DecoratedBox(
        key: ShellLayoutFrame.previewKey,
        decoration: BoxDecoration(
          color: context.akashaPalette.previewRail,
          border: Border(
            left: BorderSide(color: context.akashaPalette.borderSubtle(0.52)),
          ),
        ),
        child: child,
      ),
    );
  }
}
