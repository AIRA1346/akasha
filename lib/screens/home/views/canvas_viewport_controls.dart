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
    const targetZoom = 1.0;
    return Matrix4.translationValues(targetX, targetY, 0.0)
      ..multiply(Matrix4.diagonal3Values(targetZoom, targetZoom, 1.0));
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
    const targetZoom = 1.0;

    return Matrix4.translationValues(targetX, targetY, 0.0)
      ..multiply(Matrix4.diagonal3Values(targetZoom, targetZoom, 1.0));
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

  return Matrix4.translationValues(targetX, targetY, 0.0)
    ..multiply(Matrix4.diagonal3Values(targetZoom, targetZoom, 1.0));
}

/// Returns an updated [CanvasViewport] when [matrix] differs from [current].
CanvasViewport? canvasViewportDeltaFromMatrix(Matrix4 matrix, CanvasViewport current) {
  final zoom = matrix.getMaxScaleOnAxis();
  final translation = matrix.getTranslation();
  final x = translation.x;
  final y = translation.y;

  if (current.x != x || current.y != y || current.zoom != zoom) {
    return CanvasViewport(x: x, y: y, zoom: zoom);
  }
  return null;
}
