import 'package:flutter/material.dart';

/// Secondary Home-shell surfaces that do not participate in global navigation.
enum HomeUtilitySurface { commerce }

/// Keeps the primary Home surface mounted while a utility surface is visible.
///
/// The utility child is installed lazily on first use, then retained so its
/// tab and scroll state survive closing and reopening it during this app run.
class HomeUtilitySurfaceStack extends StatefulWidget {
  const HomeUtilitySurfaceStack({
    super.key,
    required this.utilityActive,
    required this.primary,
    required this.utility,
  });

  static const primaryKey = ValueKey<String>('home-primary-surface');
  static const utilityKey = ValueKey<String>('home-utility-surface');

  final bool utilityActive;
  final Widget primary;
  final Widget utility;

  @override
  State<HomeUtilitySurfaceStack> createState() =>
      _HomeUtilitySurfaceStackState();
}

class _HomeUtilitySurfaceStackState extends State<HomeUtilitySurfaceStack> {
  late bool _hasInstalledUtility = widget.utilityActive;

  @override
  void didUpdateWidget(HomeUtilitySurfaceStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.utilityActive) _hasInstalledUtility = true;
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      sizing: StackFit.expand,
      index: widget.utilityActive ? 1 : 0,
      children: [
        _PreservedHomeSurface(
          key: HomeUtilitySurfaceStack.primaryKey,
          active: !widget.utilityActive,
          child: widget.primary,
        ),
        if (_hasInstalledUtility)
          _PreservedHomeSurface(
            key: HomeUtilitySurfaceStack.utilityKey,
            active: widget.utilityActive,
            child: widget.utility,
          ),
      ],
    );
  }
}

class _PreservedHomeSurface extends StatelessWidget {
  const _PreservedHomeSurface({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: active,
      child: ExcludeSemantics(
        excluding: !active,
        child: ExcludeFocus(excluding: !active, child: child),
      ),
    );
  }
}
