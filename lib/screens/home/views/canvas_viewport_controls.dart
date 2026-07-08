import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/archiving/canvas_record.dart';

/// Canvas editor workspace geometry and scale limits.
abstract final class CanvasEditorViewportConfig {
  static const double workspaceSize = 50000.0;
  static const double workspaceOrigin = 25000.0;
  static const double boundaryMargin = 5000.0;
  static const double minScale = 0.1;
  static const double maxScale = 2.5;
}

double canvasDefaultNodeWidth(CanvasNode node) =>
    node.width ?? (node.kind == 'text' ? 250.0 : 260.0);

double canvasDefaultNodeHeight(CanvasNode node) =>
    node.height ?? (node.kind == 'text' ? 100.0 : 90.0);

Matrix4 _canvasTransformMatrix({required double x, required double y, required double zoom}) {
  final matrix = Matrix4.identity();
  matrix.setEntry(0, 0, zoom);
  matrix.setEntry(1, 1, zoom);
  matrix.setEntry(0, 3, x);
  matrix.setEntry(1, 3, y);
  return matrix;
}

/// Computes a fit-to-content [Matrix4] for [nodes] within [viewportSize].
/// Does not mutate layout state.
Matrix4 computeCanvasFitToContentMatrix({
  required List<CanvasNode> nodes,
  required Size viewportSize,
  double padding = 80.0,
}) {
  if (nodes.isEmpty) {
    final targetX = -(CanvasEditorViewportConfig.workspaceOrigin - viewportSize.width / 2);
    final targetY = -(CanvasEditorViewportConfig.workspaceOrigin - viewportSize.height / 2);
    return _canvasTransformMatrix(x: targetX, y: targetY, zoom: 1.0);
  }

  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = -double.infinity;
  double maxY = -double.infinity;

  for (final node in nodes) {
    final w = canvasDefaultNodeWidth(node);
    final h = canvasDefaultNodeHeight(node);

    if (node.x < minX) minX = node.x;
    if (node.y < minY) minY = node.y;
    if (node.x + w > maxX) maxX = node.x + w;
    if (node.y + h > maxY) maxY = node.y + h;
  }

  final origin = CanvasEditorViewportConfig.workspaceOrigin;
  final absMinX = origin + minX;
  final absMinY = origin + minY;
  final absMaxX = origin + maxX;
  final absMaxY = origin + maxY;

  if (nodes.length == 1) {
    final nodeW = canvasDefaultNodeWidth(nodes.first);
    final nodeH = canvasDefaultNodeHeight(nodes.first);

    final targetCenterAbsX = absMinX + nodeW / 2;
    final targetCenterAbsY = absMinY + nodeH / 2;

    final targetX = -(targetCenterAbsX - viewportSize.width / 2);
    final targetY = -(targetCenterAbsY - viewportSize.height / 2);
    return _canvasTransformMatrix(x: targetX, y: targetY, zoom: 1.0);
  }

  final contentWidth = absMaxX - absMinX;
  final contentHeight = absMaxY - absMinY;

  final availWidth = math.max(100.0, viewportSize.width - padding * 2);
  final availHeight = math.max(100.0, viewportSize.height - padding * 2);

  var targetZoom = math.min(availWidth / contentWidth, availHeight / contentHeight);
  targetZoom = targetZoom.clamp(
    CanvasEditorViewportConfig.minScale,
    CanvasEditorViewportConfig.maxScale,
  );

  final contentCenterAbsX = absMinX + contentWidth / 2;
  final contentCenterAbsY = absMinY + contentHeight / 2;

  final targetX = viewportSize.width / 2 - contentCenterAbsX * targetZoom;
  final targetY = viewportSize.height / 2 - contentCenterAbsY * targetZoom;

  return _canvasTransformMatrix(x: targetX, y: targetY, zoom: targetZoom);
}

double _matrixUniformScale(Matrix4 matrix) {
  return math.sqrt(matrix.storage[0] * matrix.storage[0] + matrix.storage[1] * matrix.storage[1]);
}

const double canvasWheelScaleFactor = 200.0;

/// Matches Flutter [InteractiveViewer] default pan inertia friction.
const double canvasPanInertiaFriction = 0.0000135;

/// Uniform scale from a canvas viewport matrix (no rotation).
double canvasMatrixUniformScale(Matrix4 matrix) {
  return _matrixUniformScale(matrix);
}

/// Applies a scene-space translation to [controller]'s matrix.
void canvasApplySceneTranslation(TransformationController controller, Offset sceneDelta) {
  if (sceneDelta == Offset.zero) return;
  final matrix = Matrix4.copy(controller.value)
    ..translateByDouble(sceneDelta.dx, sceneDelta.dy, 0, 1);
  controller.value = matrix;
}

/// Applies mouse-wheel zoom at [localViewportPoint] (viewport coordinates).
///
/// Returns true when the controller matrix changed.
bool applyCanvasWheelZoom({
  required TransformationController controller,
  required Offset localViewportPoint,
  required double scrollDeltaY,
  double scaleFactor = canvasWheelScaleFactor,
  double minScale = CanvasEditorViewportConfig.minScale,
  double maxScale = CanvasEditorViewportConfig.maxScale,
}) {
  if (scrollDeltaY == 0) return false;

  final scaleChange = math.exp(-scrollDeltaY / scaleFactor);
  final currentScale = _matrixUniformScale(controller.value);
  final totalScale = (currentScale * scaleChange).clamp(minScale, maxScale);
  final clampedScale = totalScale / currentScale;
  if ((clampedScale - 1.0).abs() < 1e-10) return false;

  final focalPointScene = controller.toScene(localViewportPoint);

  final scaled = Matrix4.copy(controller.value)
    ..scaleByDouble(clampedScale, clampedScale, clampedScale, 1);
  controller.value = scaled;

  final focalPointSceneScaled = controller.toScene(localViewportPoint);
  final translation = focalPointSceneScaled - focalPointScene;

  controller.value = Matrix4.copy(scaled)
    ..translateByDouble(translation.dx, translation.dy, 0, 1);
  return true;
}

/// Builds the InteractiveViewer matrix for [viewport] (screen = zoom * scene + translation).
Matrix4 canvasMatrixFromViewport(CanvasViewport viewport) {
  return _canvasTransformMatrix(
    x: viewport.x,
    y: viewport.y,
    zoom: viewport.zoom,
  );
}

/// Returns an updated [CanvasViewport] when [matrix] differs from [current].
///
/// Axis-aligned pan/zoom only (no rotation). Matches [InteractiveViewer] with
/// [Alignment.topLeft].
CanvasViewport? canvasViewportDeltaFromMatrix(Matrix4 matrix, CanvasViewport current) {
  final zoom = _matrixUniformScale(matrix);
  final translation = matrix.getTranslation();
  final x = translation.x;
  final y = translation.y;

  const epsilon = 1e-4;
  if ((current.x - x).abs() > epsilon ||
      (current.y - y).abs() > epsilon ||
      (current.zoom - zoom).abs() > epsilon) {
    return CanvasViewport(x: x, y: y, zoom: zoom);
  }
  return null;
}
