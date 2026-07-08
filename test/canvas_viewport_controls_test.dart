import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/canvas_record.dart';
import 'package:akasha/screens/home/views/canvas_viewport_controls.dart';

void main() {
  group('applyCanvasWheelZoom', () {
    test('zooms in toward the pointer focal point', () {
      final controller = TransformationController(
        canvasMatrixFromViewport(CanvasViewport(x: 0, y: 0, zoom: 1.0)),
      );
      const focal = Offset(200, 150);
      final sceneBefore = controller.toScene(focal);

      final changed = applyCanvasWheelZoom(
        controller: controller,
        localViewportPoint: focal,
        scrollDeltaY: -120,
      );

      expect(changed, isTrue);
      final sceneAfter = controller.toScene(focal);
      expect(sceneAfter.dx, closeTo(sceneBefore.dx, 1e-3));
      expect(sceneAfter.dy, closeTo(sceneBefore.dy, 1e-3));
    });
  });
}
