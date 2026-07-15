import 'package:akasha/core/commerce/commerce.dart';
import 'package:akasha/main.dart';
import 'package:akasha/models/theme_catalog.dart';
import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/services/akasha_theme_controller.dart';
import 'package:akasha/services/commerce_controller.dart';
import 'package:akasha/theme/akasha_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('provider entitlement restores a preferred premium theme', (
    tester,
  ) async {
    final themeController = AkashaThemeController.fallback(
      preferredThemeId: 'sakura',
    );
    final commerceController = CommerceController(
      gateway: const _RootCommerceGateway(),
      enabled: true,
    );
    addTearDown(themeController.dispose);
    addTearDown(commerceController.dispose);

    await tester.pumpWidget(
      AkashaApp(
        themeController: themeController,
        commerceController: commerceController,
        home: const Scaffold(body: Text('commerce theme')),
      ),
    );
    expect(themeController.effectiveThemeId, 'classicDark');

    await commerceController.refresh();
    await tester.pump();

    expect(themeController.effectiveThemeId, 'sakura');
    expect(themeController.preferredAccessState, ThemeAccessState.owned);
  });

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
      AkashaThemeRegistry.midnightBluePreset.backgroundColor,
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.themeAnimationDuration,
      AkashaThemeRegistry
          .midnightBluePreset
          .effects
          .motion
          .themeTransitionDuration,
    );
    expect(
      app.themeAnimationCurve,
      AkashaThemeRegistry.midnightBluePreset.effects.motion.standardCurve,
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
      AkashaThemeRegistry.midnightBluePreset.accentColor,
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
      AkashaThemeRegistry.midnightBluePreset.accentColor,
    );
    Navigator.of(tester.element(find.text('themed sheet'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('popup'));
    await tester.pumpAndSettle();
    expect(
      tester.element(find.text('themed popup')).akashaPalette.accent,
      AkashaThemeRegistry.midnightBluePreset.accentColor,
    );
    Navigator.of(tester.element(find.text('themed popup'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('snackbar'));
    await tester.pump();
    expect(
      tester.element(find.text('themed snackbar')).akashaPalette.accent,
      AkashaThemeRegistry.midnightBluePreset.accentColor,
    );
  });
}

class _RootCommerceGateway implements CommerceGateway {
  const _RootCommerceGateway();

  @override
  Future<CommerceAccountSnapshot> loadAccount() async =>
      const CommerceAccountSnapshot(
        state: CommerceAuthorityState.ready,
        astraBalance: 500,
        echoBalance: 500,
        entitlementKeys: {'theme:sakura'},
      );

  @override
  Future<CommerceOperationResult> exchangeProduct({
    required String productId,
    required CurrencyKind payWith,
  }) => throw UnimplementedError();

  @override
  Future<CommerceOperationResult> purchaseAstraPack({
    required String productId,
  }) => throw UnimplementedError();
}
