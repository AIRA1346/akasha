import 'package:akasha/widgets/poster_image.dart';
import 'package:akasha/widgets/universe_orbit_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('decorative loops stop when reduced motion is requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Column(
            children: [
              ShimmerLoadingPlaceholder(width: 120, height: 80),
              UniverseOrbitWidget(
                workCount: 2,
                personCount: 1,
                placeCount: 1,
                eventCount: 1,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
