import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/models/build_identity.dart';
import 'package:akasha/theme/akasha_palette.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/widgets/build_identity_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const identity = BuildIdentity(
    version: '0.9.0',
    buildNumber: '42',
    steamBuildId: 24271481,
    gitCommitShort: 'f9d0b94b',
    buildMode: 'release',
    executionEnvironment: 'steamInstall',
    steamState: SteamBuildIdentityState.available,
  );

  testWidgets('full and condensed dock labels use the expected copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        child: const SizedBox(
          width: 276,
          height: 56,
          child: BuildIdentityDockLabel(identity: identity),
        ),
      ),
    );

    expect(find.text('v0.9.0+42 • Steam 24271481'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('build-identity-dock-label')),
    );
    expect(
      semantics.label,
      contains('Copy build information: v0.9.0+42 • Steam 24271481'),
    );
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _harness(
        child: const SizedBox(
          width: 112,
          height: 56,
          child: BuildIdentityDockLabel(identity: identity, condensed: true),
        ),
      ),
    );

    expect(find.text('v0.9.0+42'), findsOneWidget);
    expect(find.textContaining('Steam 24271481'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dock copy is accessible and confirms clipboard success', (
    tester,
  ) async {
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      _harness(
        child: const Scaffold(
          bottomNavigationBar: SizedBox(
            width: 276,
            height: 56,
            child: BuildIdentityDockLabel(identity: identity),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('build-identity-dock-label')));
    await tester.pump();

    expect(
      clipboardText,
      'AKASHA v0.9.0+42 | Steam 24271481 | Git f9d0b94b | '
      'release | steamInstall',
    );
    expect(
      find.text('Build information copied to the clipboard.'),
      findsOneWidget,
    );
  });

  testWidgets('app information shows every identity field without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _harness(
        textScale: 1.25,
        child: const Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: BuildIdentityInfoSection(identity: identity),
            ),
          ),
        ),
      ),
    );

    for (final label in const [
      'App version',
      'Build number',
      'Steam BuildID',
      'Git commit',
      'Build mode',
      'Execution environment',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    for (final value in const [
      '0.9.0',
      '42',
      '24271481',
      'f9d0b94b',
      'release',
      'steamInstall',
    ]) {
      expect(find.text(value), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('official themes retain readable identity text geometry', (
    tester,
  ) async {
    for (final preset in AkashaThemeRegistry.presets) {
      final palette = AkashaPalette.fromPreset(preset);
      expect(
        AkashaPalette.contrastRatio(palette.textMuted, palette.bottomBar),
        greaterThanOrEqualTo(4.5),
        reason: preset.id,
      );
      await tester.pumpWidget(
        _harness(
          theme: AkashaTheme.forPreset(preset),
          textScale: 1.25,
          child: Builder(
            builder: (context) {
              final palette = context.akashaPalette;
              return ColoredBox(
                color: palette.bottomBar,
                child: const SizedBox(
                  width: 276,
                  height: 56,
                  child: BuildIdentityDockLabel(identity: identity),
                ),
              );
            },
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('build-identity-dock-label')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: preset.id);
    }
  });
}

Widget _harness({
  required Widget child,
  ThemeData? theme,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: theme ?? AkashaTheme.dark(),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScale)),
        child: appChild!,
      );
    },
    home: Center(child: child),
  );
}
