import 'package:akasha/main.dart';
import 'package:akasha/services/akasha_theme_controller.dart';
import 'package:akasha/theme/akasha_palette.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preloaded Midnight is active on the first frame', (
    tester,
  ) async {
    final controller = AkashaThemeController.fallback(
      preferredThemeId: 'midnightBlue',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AkashaApp(
        themeController: controller,
        home: const Scaffold(body: Text('root theme')),
      ),
    );

    final context = tester.element(find.text('root theme'));
    expect(
      context.akashaPalette.background,
      AkashaThemePreset.midnightBlue.backgroundColor,
    );
  });

  testWidgets('dialog inherits the root effective theme', (tester) async {
    final controller = AkashaThemeController.fallback(
      preferredThemeId: 'midnightBlue',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AkashaApp(
        themeController: controller,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    const AlertDialog(content: Text('themed dialog')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('themed dialog'));
    expect(
      context.akashaPalette.accent,
      AkashaThemePreset.midnightBlue.accentColor,
    );
  });

  testWidgets('bottom sheet, popup, and snackbar inherit root theme', (
    tester,
  ) async {
    final controller = AkashaThemeController.fallback(
      preferredThemeId: 'midnightBlue',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AkashaApp(
        themeController: controller,
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const Text('themed sheet'),
                  ),
                  child: const Text('sheet'),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'one', child: Text('themed popup')),
                  ],
                  child: const Text('popup'),
                ),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('themed snackbar')),
                  ),
                  child: const Text('snackbar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('sheet'));
    await tester.pumpAndSettle();
    expect(
      tester.element(find.text('themed sheet')).akashaPalette.accent,
      AkashaThemePreset.midnightBlue.accentColor,
    );
    Navigator.of(tester.element(find.text('themed sheet'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('popup'));
    await tester.pumpAndSettle();
    expect(
      tester.element(find.text('themed popup')).akashaPalette.accent,
      AkashaThemePreset.midnightBlue.accentColor,
    );
    Navigator.of(tester.element(find.text('themed popup'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('snackbar'));
    await tester.pump();
    expect(
      tester.element(find.text('themed snackbar')).akashaPalette.accent,
      AkashaThemePreset.midnightBlue.accentColor,
    );
  });
}
