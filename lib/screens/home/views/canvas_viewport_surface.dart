import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/archiving/canvas_record.dart';
import 'canvas_viewport_controls.dart';

/// Pan/zoom surface for the canvas editor.
///
/// Replaces [InteractiveViewer] so pan inertia updates matrix translation
/// directly (InteractiveViewer applies inertia via [TransformationController.toScene]
/// on translation values, which breaks when zoom != 1 or zoom changes mid-inertia).
class CanvasViewportSurface extends StatefulWidget {
  const CanvasViewportSurface({
    super.key,
    required this.transformationController,
    required this.child,
    this.onInteractionEnd,
    this.minScale = CanvasEditorViewportConfig.minScale,
    this.maxScale = CanvasEditorViewportConfig.maxScale,
    this.viewportKey,
  });

  final TransformationController transformationController;
  final Widget child;
  final VoidCallback? onInteractionEnd;
  final double minScale;
  final double maxScale;

  /// Render box for converting global pointer positions to viewport coordinates.
  final GlobalKey? viewportKey;

  @override
  State<CanvasViewportSurface> createState() => _CanvasViewportSurfaceState();
}

class _CanvasViewportSurfaceState extends State<CanvasViewportSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _inertiaController;
  Animation<Offset>? _inertiaAnimation;
  Offset? _referenceFocalPointScene;

  @override
  void initState() {
    super.initState();
    _inertiaController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _stopInertia();
    _inertiaController.dispose();
    super.dispose();
  }

  void _stopInertia() {
    _inertiaController
      ..stop()
      ..reset();
    _inertiaAnimation?.removeListener(_handleInertiaTick);
    _inertiaAnimation = null;
  }

  void _handleInertiaTick() {
    final animation = _inertiaAnimation;
    if (animation == null || !_inertiaController.isAnimating) {
      _stopInertia();
      return;
    }

    final zoom = canvasMatrixUniformScale(widget.transformationController.value);
    widget.transformationController.value = canvasMatrixFromViewport(
      CanvasViewport(x: animation.value.dx, y: animation.value.dy, zoom: zoom),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _stopInertia();
    _referenceFocalPointScene = widget.transformationController.toScene(details.localFocalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final reference = _referenceFocalPointScene;
    if (reference == null) return;
    if (details.scale != 1.0) return;

    final focalPointScene = widget.transformationController.toScene(details.localFocalPoint);
    canvasApplySceneTranslation(
      widget.transformationController,
      focalPointScene - reference,
    );
    _referenceFocalPointScene = widget.transformationController.toScene(details.localFocalPoint);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _referenceFocalPointScene = null;
    widget.onInteractionEnd?.call();

    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.distance < kMinFlingVelocity) return;

    final translation = widget.transformationController.value.getTranslation();
    final start = Offset(translation.x, translation.y);
    final frictionX = FrictionSimulation(
      canvasPanInertiaFriction,
      start.dx,
      velocity.dx,
    );
    final frictionY = FrictionSimulation(
      canvasPanInertiaFriction,
      start.dy,
      velocity.dy,
    );
    final end = Offset(frictionX.finalX, frictionY.finalX);
    final durationMs = (_panInertiaDurationMs(velocity.distance) * 1000).round();

    _inertiaAnimation?.removeListener(_handleInertiaTick);
    _inertiaAnimation = Tween<Offset>(begin: start, end: end).animate(
      CurvedAnimation(parent: _inertiaController, curve: Curves.decelerate),
    )..addListener(_handleInertiaTick);
    _inertiaController.duration = Duration(milliseconds: math.max(1, durationMs));
    _inertiaController.forward(from: 0);
  }

  double _panInertiaDurationMs(double velocity) {
    const effectivelyMotionless = 10.0;
    if (velocity <= effectivelyMotionless) return 0;
    return math.log(effectivelyMotionless / velocity) / math.log(canvasPanInertiaFriction / 100);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) return;

    if (event.kind == PointerDeviceKind.trackpad) {
      _handleTrackpadScroll(event);
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent resolved) {
      if (resolved is! PointerScrollEvent || resolved.scrollDelta.dy == 0) return;
      _stopInertia();
      if (applyCanvasWheelZoom(
        controller: widget.transformationController,
        localViewportPoint: resolved.localPosition,
        scrollDeltaY: resolved.scrollDelta.dy,
      )) {
        widget.onInteractionEnd?.call();
      }
    });
  }

  void _handleTrackpadScroll(PointerScrollEvent event) {
    _stopInertia();

    final localDelta = PointerEvent.transformDeltaViaPositions(
      untransformedEndPosition: event.position + event.scrollDelta,
      untransformedDelta: event.scrollDelta,
      transform: event.transform,
    );
    final local = event.localPosition;
    final focalPointScene = widget.transformationController.toScene(local);
    final newFocalPointScene = widget.transformationController.toScene(local - localDelta);
    canvasApplySceneTranslation(
      widget.transformationController,
      newFocalPointScene - focalPointScene,
    );
    widget.onInteractionEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      key: widget.viewportKey,
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: AnimatedBuilder(
          animation: widget.transformationController,
          builder: (context, child) {
            return Transform(
              transform: widget.transformationController.value,
              alignment: Alignment.topLeft,
              child: child,
            );
          },
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
