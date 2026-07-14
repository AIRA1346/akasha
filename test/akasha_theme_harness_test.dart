import 'package:akasha/dev/theme/akasha_theme_harness.dart';
import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all presets render at three desktop widths and 125% text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [
      Size(1024, 720),
      Size(1366, 768),
      Size(1600, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      Size? expectedCardSize;
      for (final preset in AkashaThemeRegistry.presets) {
        await tester.pumpWidget(
          AkashaThemeHarness(
            preset: preset,
            textScale: 1.25,
            reduceMotion: size.width == 1024,
          ),
        );
        await tester.pump();
        expect(find.text(preset.id), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '${preset.id} $size');

        final cardSize = tester.getSize(find.byType(Card));
        expectedCardSize ??= cardSize;
        expect(cardSize, expectedCardSize, reason: '${preset.id} $size');
      }
    }
  });
}
