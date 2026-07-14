import 'dart:io';

import 'package:akasha/dev/theme/akasha_theme_harness.dart';
import 'package:akasha/screens/home/views/home_dashboard/home_dashboard_hero.dart';
import 'package:akasha/screens/home/views/home_dashboard/home_dashboard_summary.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const summary = HomeDashboardSummary(
    archiveRecordCount: 3246,
    entityCount: 128,
    collectionCount: 42,
    tagCount: 1156,
  );

  testWidgets(
    'official themes match the standard viewport visual baseline',
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
        (
          preset: AkashaThemePreset.sakura,
          golden: 'goldens/theme_sakura_standard.png',
        ),
        (
          preset: AkashaThemePreset.amethyst,
          golden: 'goldens/theme_amethyst_standard.png',
        ),
        (
          preset: AkashaThemePreset.nocturne,
          golden: 'goldens/theme_nocturne_standard.png',
        ),
      ]) {
        await tester.pumpWidget(
          AkashaThemeHarness(preset: fixture.preset, reduceMotion: true),
        );
        await tester.pump();
        await tester.runAsync(
          () => _precachePresetArtwork(
            tester.element(find.byType(Scaffold)),
            fixture.preset,
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(AkashaThemeHarness.surfaceKey),
          matchesGoldenFile(fixture.golden),
        );
      }
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'official theme Hero artwork matches the visual baseline',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(960, 320));

      for (final fixture in const [
        (
          preset: AkashaThemePreset.classicDark,
          golden: 'goldens/theme_classic_dark_hero.png',
        ),
        (
          preset: AkashaThemePreset.midnightBlue,
          golden: 'goldens/theme_midnight_blue_hero.png',
        ),
        (
          preset: AkashaThemePreset.sakura,
          golden: 'goldens/theme_sakura_hero.png',
        ),
        (
          preset: AkashaThemePreset.amethyst,
          golden: 'goldens/theme_amethyst_hero.png',
        ),
        (
          preset: AkashaThemePreset.nocturne,
          golden: 'goldens/theme_nocturne_hero.png',
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey<String>('hero-${fixture.preset.id}'),
            debugShowCheckedModeBanner: false,
            theme: AkashaTheme.forPreset(fixture.preset),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: HomeDashboardHero(
                  summary: summary,
                  onStartRecording: _noop,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.runAsync(
          () => _precachePresetArtwork(
            tester.element(find.byType(Scaffold)),
            fixture.preset,
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(HomeDashboardHero.panelKey),
          matchesGoldenFile(fixture.golden),
        );
      }
    },
    skip: !Platform.isWindows,
  );
}

void _noop() {}

Future<void> _precachePresetArtwork(
  BuildContext context,
  AkashaThemePreset preset,
) async {
  for (final path in preset.assets.paths) {
    await precacheImage(AssetImage(path), context);
  }
}
