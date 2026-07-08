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

/// Builds the InteractiveViewer matrix for [viewport] (translate then scale).
Matrix4 canvasMatrixFromViewport(CanvasViewport viewport) {
  return _canvasTransformMatrix(
    x: viewport.x,
    y: viewport.y,
    zoom: viewport.zoom,
  );
}

/// Returns an updated [CanvasViewport] when [matrix] differs from [current].
CanvasViewport? canvasViewportDeltaFromMatrix(Matrix4 matrix, CanvasViewport current) {
  final zoom = _matrixUniformScale(matrix);
  final x = matrix.storage[12];
  final y = matrix.storage[13];

  const epsilon = 1e-4;
  if ((current.x - x).abs() > epsilon ||
      (current.y - y).abs() > epsilon ||
      (current.zoom - zoom).abs() > epsilon) {
    return CanvasViewport(x: x, y: y, zoom: zoom);
  }
  return null;
}
