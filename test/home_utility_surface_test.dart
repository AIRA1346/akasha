import 'dart:ui' show Tristate;

import 'package:akasha/core/commerce/commerce.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/screens/home/app_destination.dart';
import 'package:akasha/screens/home/home_app_bar.dart';
import 'package:akasha/screens/home/home_shell_controller.dart';
import 'package:akasha/screens/home/home_shell_host.dart';
import 'package:akasha/screens/home/home_utility_surface.dart';
import 'package:akasha/screens/home/shell_layout_frame.dart';
import 'package:akasha/screens/home/shell_layout_spec.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/widgets/commerce_center_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomeShellController toggles commerce without navigating', () {
    final host = _FakeHomeShellHost();
    final controller = HomeShellController(host);

    expect(controller.activeUtilitySurface, isNull);
    controller.toggleCommerceSurface();
    expect(controller.activeUtilitySurface, HomeUtilitySurface.commerce);
    expect(controller.isCommerceSurfaceOpen, isTrue);

    controller.toggleCommerceSurface();
    expect(controller.activeUtilitySurface, isNull);

    controller.openCommerceSurface();
    controller.openCommerceSurface();
    expect(controller.isCommerceSurfaceOpen, isTrue);
    controller.closeUtilitySurface();
    expect(controller.activeUtilitySurface, isNull);
    expect(host.rebuildCount, 4);
  });

  testWidgets(
    'commerce replaces only center and restores editor and preview state',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1440, 800));

      var commerceOpen = false;
      const currentDestination = AppDestination.library;
      late StateSetter setHostState;
      const primaryKey = ValueKey<String>('utility-test-primary');
      const previewKey = ValueKey<String>('utility-test-preview');

      await tester.pumpWidget(
        MaterialApp(
          theme: AkashaTheme.dark(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              void toggleCommerce() {
                setState(() => commerceOpen = !commerceOpen);
              }

              return Scaffold(
                appBar: HomeAppBar(
                  isSidebarOpen: true,
                  isInspectorOpen: true,
                  vaultLinked: true,
                  onToggleSidebar: () {},
                  onToggleInspector: () {},
                  onClipboardImport: () {},
                  onPromptTemplates: () {},
                  onVaultSettings: () {},
                  onSettings: () {},
                  onCommerce: toggleCommerce,
                  commerceSelected: commerceOpen,
                ),
                body: ShellLayoutFrame(
                  layoutSpec: ShellLayoutSpec.wide,
                  sidebarOpen: true,
                  onDismissSidebar: () {},
                  sidebar: const ColoredBox(
                    key: ValueKey('utility-test-sidebar'),
                    color: Colors.black12,
                  ),
                  center: HomeUtilitySurfaceStack(
                    utilityActive: commerceOpen,
                    primary: const _EditablePrimary(key: primaryKey),
                    utility: CommerceCenterView(
                      account: const CommerceAccountSnapshot.disabled(),
                      onClose: () => setState(() => commerceOpen = false),
                    ),
                  ),
                  preview: const _PreviewSentinel(key: previewKey),
                  previewVisible: !commerceOpen,
                ),
                bottomNavigationBar: const SizedBox(
                  key: ValueKey('utility-test-dock'),
                  height: 56,
                ),
              );
            },
          ),
        ),
      );

      final primaryState = tester.state<_EditablePrimaryState>(
        find.byKey(primaryKey),
      );
      final previewState = tester.state<_PreviewSentinelState>(
        find.byKey(previewKey),
      );
      await tester.enterText(
        find.byKey(const ValueKey('utility-test-editor')),
        'unsaved draft',
      );
      primaryState.dirty = true;

      final commerceButton = find.byKey(
        const ValueKey('home-utility-commerce'),
      );
      await tester.tap(commerceButton);
      await tester.pumpAndSettle();

      expect(currentDestination, AppDestination.library);
      expect(
        find.byKey(const ValueKey('commerce-center-view')),
        findsOneWidget,
      );
      expect(find.byType(Dialog), findsNothing);
      expect(find.byKey(const ValueKey('home-shell-app-bar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('utility-test-sidebar')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('utility-test-dock')), findsOneWidget);
      expect(
        tester.getSemantics(commerceButton).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(find.byKey(previewKey), findsNothing);
      expect(
        tester.state(find.byKey(previewKey, skipOffstage: false)),
        same(previewState),
      );
      expect(
        tester.state(find.byKey(primaryKey, skipOffstage: false)),
        same(primaryState),
      );
      expect(primaryState.controller.text, 'unsaved draft');
      expect(primaryState.dirty, isTrue);
      expect(primaryState.canvasSession, isNotNull);
      expect(TickerMode.valuesOf(primaryState.context).enabled, isFalse);

      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const PageStorageKey('commerce-inventory-scroll')),
        findsOneWidget,
      );

      await tester.tap(commerceButton);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('commerce-center-view')), findsNothing);
      expect(tester.state(find.byKey(primaryKey)), same(primaryState));
      expect(tester.state(find.byKey(previewKey)), same(previewState));
      expect(primaryState.controller.text, 'unsaved draft');

      setHostState(() => commerceOpen = true);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const PageStorageKey('commerce-inventory-scroll')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('commerce-center-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('commerce-center-view')), findsNothing);
      expect(tester.state(find.byKey(primaryKey)), same(primaryState));
    },
  );
}

class _FakeHomeShellHost implements HomeShellHost {
  var rebuildCount = 0;

  @override
  BuildContext get context => throw StateError('context is not used');

  @override
  bool get mounted => true;

  @override
  void scheduleRebuild([void Function()? mutate]) {
    mutate?.call();
    rebuildCount++;
  }
}

class _EditablePrimary extends StatefulWidget {
  const _EditablePrimary({super.key});

  @override
  State<_EditablePrimary> createState() => _EditablePrimaryState();
}

class _EditablePrimaryState extends State<_EditablePrimary> {
  final controller = TextEditingController(text: 'initial');
  final canvasSession = Object();
  bool dirty = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('utility-test-editor'),
      controller: controller,
    );
  }
}

class _PreviewSentinel extends StatefulWidget {
  const _PreviewSentinel({super.key});

  @override
  State<_PreviewSentinel> createState() => _PreviewSentinelState();
}

class _PreviewSentinelState extends State<_PreviewSentinel> {
  @override
  Widget build(BuildContext context) => const Text('preserved preview');
}
