import 'package:akasha/effects/akasha_effect_runtime.dart';
import 'package:akasha/theme/akasha_effect_spec.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime policy bounds effect-owned element budgets', () {
    const policy = AkashaEffectRuntimePolicy(
      motionEnabled: true,
      quality: AkashaEffectQuality.low,
      globalElementLimit: 24,
      intensityScale: 0.5,
    );
    const spec = AkashaEffectSpec(
      id: 'fixture',
      layer: AkashaEffectLayer.interaction,
      intensity: 0.8,
      maxActiveElements: 80,
    );

    expect(policy.elementBudgetFor(spec), 24);
    expect(policy.intensityFor(spec), closeTo(0.4, 0.001));
  });

  testWidgets(
    'host observes pointers and repaints without rebuilding content',
    (tester) async {
      late _FixtureEffectController controller;
      var created = 0;
      var taps = 0;
      var childBuilds = 0;
      final registry = AkashaEffectRegistry(
        factories: {
          'fixture-interaction':
              ({required vsync, required spec, required policy}) {
                created++;
                controller = _FixtureEffectController(spec);
                return controller;
              },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AkashaTheme.forPreset(_effectPreset()),
          home: Scaffold(
            body: AkashaEffectsHost(
              registry: registry,
              child: Builder(
                builder: (context) {
                  childBuilds++;
                  return GestureDetector(
                    key: const ValueKey('effect-target'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps++,
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(created, 1);
      final buildsBeforeRepaint = childBuilds;
      final paintsBeforeRepaint = controller.paintCount;

      await tester.tap(find.byKey(const ValueKey('effect-target')));
      expect(taps, 1);
      expect(controller.pointerEventCount, greaterThanOrEqualTo(2));

      controller.requestRepaint();
      await tester.pump();
      expect(controller.paintCount, greaterThan(paintsBeforeRepaint));
      expect(childBuilds, buildsBeforeRepaint);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.disposed, isTrue);
    },
  );

  testWidgets('reduced motion does not instantiate motion effects', (
    tester,
  ) async {
    var created = 0;
    final registry = AkashaEffectRegistry(
      factories: {
        'fixture-interaction':
            ({required vsync, required spec, required policy}) {
              created++;
              return _FixtureEffectController(spec);
            },
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.forPreset(_effectPreset()),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AkashaEffectsHost(
            registry: registry,
            child: const SizedBox(key: ValueKey('content')),
          ),
        ),
      ),
    );

    expect(created, 0);
    expect(find.byKey(const ValueKey('content')), findsOneWidget);
  });
}

AkashaThemePreset _effectPreset() {
  return const AkashaThemePreset(
    id: 'effect-fixture',
    backgroundColor: Color(0xFF101018),
    accentColor: Color(0xFF8070FF),
    assets: AkashaThemeAssets.none,
    effects: AkashaThemeEffects(
      backdrop: AkashaBackdropEffects(
        glowIntensity: 0,
        scrimOpacity: 0,
        textureOpacity: 0,
        ambientOpacity: 0,
      ),
      hero: AkashaHeroEffects(glowIntensity: 0, shadowIntensity: 0),
      extensions: [
        AkashaEffectSpec(
          id: 'fixture-interaction',
          layer: AkashaEffectLayer.interaction,
          maxActiveElements: 12,
        ),
      ],
    ),
  );
}

class _FixtureEffectController extends ChangeNotifier
    implements AkashaEffectController {
  _FixtureEffectController(this.spec);

  @override
  final AkashaEffectSpec spec;

  int pointerEventCount = 0;
  int paintCount = 0;
  bool disposed = false;

  @override
  void handlePointerEvent(PointerEvent event) {
    pointerEventCount++;
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintCount++;
    canvas.drawCircle(
      size.center(Offset.zero),
      4,
      Paint()..color = Colors.white,
    );
  }

  void requestRepaint() => notifyListeners();

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
