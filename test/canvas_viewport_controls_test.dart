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
      expect(
        canvasViewportDeltaFromMatrix(
          controller.value,
          CanvasViewport(x: 0, y: 0, zoom: 1.0),
        )!.zoom,
        greaterThan(1.0),
      );
    });

    test('clamps zoom to configured limits', () {
      final controller = TransformationController(
        canvasMatrixFromViewport(
          CanvasViewport(
            x: 0,
            y: 0,
            zoom: CanvasEditorViewportConfig.maxScale,
          ),
        ),
      );

      applyCanvasWheelZoom(
        controller: controller,
        localViewportPoint: const Offset(100, 100),
        scrollDeltaY: -500,
      );

      final zoom = canvasViewportDeltaFromMatrix(
        controller.value,
        CanvasViewport(x: 0, y: 0, zoom: 0),
      )!.zoom;
      expect(zoom, CanvasEditorViewportConfig.maxScale);
    });
  });
}
