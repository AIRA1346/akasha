import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:akasha/widgets/akasha_theme_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fallback backdrop preserves child and geometry', (tester) async {
    const preset = AkashaThemePreset(
      id: 'fallbackFixture',
      backgroundColor: Color(0xFF101018),
      accentColor: Color(0xFF8070FF),
      assets: AkashaThemeAssets.none,
      effects: AkashaThemeEffects.neutral,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 320,
          height: 240,
          child: AkashaThemeBackdrop(
            preset: preset,
            child: SizedBox(key: Key('content')),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('content')), findsOneWidget);
    final decorativeLayers = tester
        .widgetList<IgnorePointer>(find.byType(IgnorePointer))
        .where((widget) => widget.ignoring);
    expect(decorativeLayers, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing optional asset keeps the fallback visible', (
    tester,
  ) async {
    const preset = AkashaThemePreset(
      id: 'missingAssetFixture',
      backgroundColor: Color(0xFF101018),
      accentColor: Color(0xFF8070FF),
      assets: AkashaThemeAssets(backdropAssetPath: 'missing/theme.png'),
      effects: AkashaThemeEffects.neutral,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AkashaThemeBackdrop(
          preset: preset,
          child: Text('content survives'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('content survives'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion omits ambient artwork', (tester) async {
    const preset = AkashaThemePreset(
      id: 'ambientFixture',
      backgroundColor: Color(0xFF101018),
      accentColor: Color(0xFF8070FF),
      assets: AkashaThemeAssets(ambientAssetPath: 'missing/ambient.png'),
      effects: AkashaThemeEffects(
        backdrop: AkashaBackdropEffects(
          glowIntensity: 0,
          scrimOpacity: 0,
          textureOpacity: 0,
          ambientOpacity: 1,
        ),
        hero: AkashaHeroEffects(glowIntensity: 0, shadowIntensity: 0),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AkashaThemeBackdrop(preset: preset, child: Text('still')),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.text('still'), findsOneWidget);
  });
}
