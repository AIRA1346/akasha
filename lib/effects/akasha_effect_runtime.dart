import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/akasha_effect_spec.dart';
import '../theme/akasha_theme_preset.dart';

enum AkashaEffectQuality { low, balanced, high }

/// Runtime limits shared by every effect implementation.
@immutable
class AkashaEffectRuntimePolicy {
  const AkashaEffectRuntimePolicy({
    required this.motionEnabled,
    required this.quality,
    required this.globalElementLimit,
    required this.intensityScale,
  });

  factory AkashaEffectRuntimePolicy.fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    final width = mediaQuery?.size.width ?? 1440;
    final highContrast = mediaQuery?.highContrast ?? false;
    final quality = width < 1200
        ? AkashaEffectQuality.low
        : AkashaEffectQuality.balanced;

    return AkashaEffectRuntimePolicy(
      motionEnabled: !reduceMotion,
      quality: quality,
      globalElementLimit: quality == AkashaEffectQuality.low ? 24 : 64,
      intensityScale: highContrast ? 0.72 : 1,
    );
  }

  final bool motionEnabled;
  final AkashaEffectQuality quality;
  final int globalElementLimit;
  final double intensityScale;

  int elementBudgetFor(AkashaEffectSpec spec) =>
      math.min(spec.maxActiveElements, globalElementLimit);

  double intensityFor(AkashaEffectSpec spec) =>
      (spec.intensity * intensityScale).clamp(0, 1);

  @override
  bool operator ==(Object other) {
    return other is AkashaEffectRuntimePolicy &&
        other.motionEnabled == motionEnabled &&
        other.quality == quality &&
        other.globalElementLimit == globalElementLimit &&
        other.intensityScale == intensityScale;
  }

  @override
  int get hashCode =>
      Object.hash(motionEnabled, quality, globalElementLimit, intensityScale);
}

/// Repaint-only effect implementation owned by the runtime registry.
abstract interface class AkashaEffectController implements Listenable {
  AkashaEffectSpec get spec;

  void handlePointerEvent(PointerEvent event);
  void paint(Canvas canvas, Size size);
  void dispose();
}

typedef AkashaEffectControllerFactory =
    AkashaEffectController Function({
      required TickerProvider vsync,
      required AkashaEffectSpec spec,
      required AkashaEffectRuntimePolicy policy,
    });

/// Explicit allowlist of executable effect implementations.
///
/// Theme packages may request only IDs registered here. Unknown IDs safely
/// render nothing, so visual metadata can never inject runtime code.
class AkashaEffectRegistry {
  AkashaEffectRegistry({
    Map<String, AkashaEffectControllerFactory> factories = const {},
  }) : _factories = Map.unmodifiable(factories);

  static final builtIn = AkashaEffectRegistry();

  final Map<String, AkashaEffectControllerFactory> _factories;

  AkashaEffectController? create({
    required TickerProvider vsync,
    required AkashaEffectSpec spec,
    required AkashaEffectRuntimePolicy policy,
  }) {
    if (spec.requiresMotion && !policy.motionEnabled) return null;
    return _factories[spec.id]?.call(vsync: vsync, spec: spec, policy: policy);
  }
}

/// Root compositor for background and pointer/touch effects.
///
/// Controllers drive [CustomPainter] through [Listenable] notifications. No
/// animation frame calls setState, so effects cannot rebuild the Home shell.
class AkashaEffectsHost extends StatefulWidget {
  const AkashaEffectsHost({super.key, required this.child, this.registry});

  final Widget child;
  final AkashaEffectRegistry? registry;

  @override
  State<AkashaEffectsHost> createState() => _AkashaEffectsHostState();
}

class _AkashaEffectsHostState extends State<AkashaEffectsHost>
    with TickerProviderStateMixin {
  List<AkashaEffectController> _controllers = const [];
  List<AkashaEffectSpec> _installedSpecs = const [];
  AkashaEffectRuntimePolicy? _installedPolicy;
  AkashaEffectRegistry? _installedRegistry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reconcileControllers();
  }

  @override
  void didUpdateWidget(covariant AkashaEffectsHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.registry != widget.registry) {
      _reconcileControllers(force: true);
    }
  }

  void _reconcileControllers({bool force = false}) {
    final specs = context.resolvedAkashaThemeVisuals.effects.extensions;
    final policy = AkashaEffectRuntimePolicy.fromContext(context);
    final registry = widget.registry ?? AkashaEffectRegistry.builtIn;
    if (!force &&
        listEquals(specs, _installedSpecs) &&
        policy == _installedPolicy &&
        identical(registry, _installedRegistry)) {
      return;
    }

    _disposeControllers();
    _installedSpecs = List.unmodifiable(specs);
    _installedPolicy = policy;
    _installedRegistry = registry;
    _controllers = [
      for (final spec in specs)
        ?registry.create(vsync: this, spec: spec, policy: policy),
    ];
  }

  void _disposeControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers = const [];
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controllers.isEmpty) return widget.child;

    final background = _controllers
        .where(
          (controller) => controller.spec.layer == AkashaEffectLayer.background,
        )
        .toList(growable: false);
    final interaction = _controllers
        .where(
          (controller) =>
              controller.spec.layer == AkashaEffectLayer.interaction,
        )
        .toList(growable: false);

    Widget content = widget.child;
    if (interaction.isNotEmpty) {
      content = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _dispatchPointer,
        onPointerMove: _dispatchPointer,
        onPointerUp: _dispatchPointer,
        onPointerCancel: _dispatchPointer,
        onPointerHover: _dispatchPointer,
        onPointerSignal: _dispatchPointer,
        child: content,
      );
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (background.isNotEmpty) _EffectPaintLayer(background),
        content,
        if (interaction.isNotEmpty) _EffectPaintLayer(interaction),
      ],
    );
  }

  void _dispatchPointer(PointerEvent event) {
    for (final controller in _controllers) {
      if (controller.spec.layer == AkashaEffectLayer.interaction) {
        controller.handlePointerEvent(event);
      }
    }
  }
}

class _EffectPaintLayer extends StatelessWidget {
  const _EffectPaintLayer(this.controllers);

  final List<AkashaEffectController> controllers;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _EffectPainter(controllers)),
          ),
        ),
      ),
    );
  }
}

class _EffectPainter extends CustomPainter {
  _EffectPainter(this.controllers)
    : super(repaint: Listenable.merge(controllers));

  final List<AkashaEffectController> controllers;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final controller in controllers) {
      canvas.save();
      controller.paint(canvas, size);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EffectPainter oldDelegate) =>
      !listEquals(controllers, oldDelegate.controllers);
}
