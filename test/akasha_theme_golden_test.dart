import 'dart:io';

import 'package:akasha/dev/theme/akasha_theme_harness.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'bundled themes match the standard viewport visual baseline',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(960, 640));

      for (final fixture in const [
        (
          preset: AkashaThemePreset.classicDark,
          golden: 'goldens/theme_classic_dark_standard.png',
        ),
        (
          preset: AkashaThemePreset.midnightBlue,
          golden: 'goldens/theme_midnight_blue_standard.png',
        ),
      ]) {
        await tester.pumpWidget(
          AkashaThemeHarness(preset: fixture.preset, reduceMotion: true),
        );
        await tester.pump();

        await expectLater(
          find.byKey(AkashaThemeHarness.surfaceKey),
          matchesGoldenFile(fixture.golden),
        );
      }
    },
    skip: !Platform.isWindows,
  );
}
