import 'dart:ui' show Tristate;

import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/screens/home/app_destination.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/screens/home/home_shell_body.dart';
import 'package:akasha/screens/home/home_shell_body_center.dart';
import 'package:akasha/screens/home/shell_layout_spec.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/widgets/dashboard_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Sidebar renders every registry destination and dispatches Graph/Timeline',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final selected = <AppDestination>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AkashaTheme.dark(),
          home: Scaffold(
            body: DashboardSidebar(
              isOpen: true,
              width: 256,
              selectedDestination: AppDestination.home,
              onSelectDestination: selected.add,
              selectionMode: SidebarSelectionMode.dashboard,
              onSelectCollectibleCollection: (_) {},
              onAddPersonalLibrary: () {},
              onSelectPersonalLibrary: (_) {},
            ),
          ),
        ),
      );

      for (final definition in AppDestinationRegistry.ordered) {
        expect(
          find.byKey(ValueKey('destination-${definition.stableId}-sidebar')),
          findsOneWidget,
          reason: definition.stableId,
        );
      }

      final homeSemantics = tester.getSemantics(
        find
            .descendant(
              of: find.byKey(const ValueKey('destination-home-sidebar')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(homeSemantics.flagsCollection.isButton, isTrue);
      expect(homeSemantics.flagsCollection.isSelected, Tristate.isTrue);
      expect(homeSemantics.flagsCollection.isEnabled, Tristate.isTrue);

      await tester.tap(find.byKey(const ValueKey('destination-graph-sidebar')));
      await tester.tap(
        find.byKey(const ValueKey('destination-timeline-sidebar')),
      );

      expect(selected, [AppDestination.graph, AppDestination.timeline]);
    },
  );

  test('Sidebar and dock bindings derive the same selected destination', () {
    for (final current in AppDestination.values) {
      final sidebarBindings = AppDestinationRegistry.bindings(
        currentDestination: current,
        onSelected: (_) {},
      );
      final dockBindings = AppDestinationRegistry.bindings(
        currentDestination: current,
        onSelected: (_) {},
      );

      final sidebarSelected = sidebarBindings
          .where((binding) => binding.isSelected)
          .map((binding) => binding.destination)
          .toList();
      final dockSelected = dockBindings
          .where((binding) => binding.isSelected)
          .map((binding) => binding.destination)
          .toList();

      expect(sidebarSelected, [current], reason: current.name);
      expect(dockSelected, sidebarSelected, reason: current.name);
    }
  });

  test('unavailable destination metadata binds no action', () {
    var selections = 0;
    const unavailable = AppDestinationDefinition(
      destination: AppDestination.graph,
      purpose: AppDestinationPurpose.relationships,
      stableId: 'graph-unavailable-fixture',
      l10nLabelKey: 'sidebarGraph',
      fallbackLabel: 'Graph',
      icon: Icons.hub_outlined,
      available: false,
      shortcut: SingleActivator(LogicalKeyboardKey.digit5, alt: true),
    );

    final binding = unavailable.bind(
      currentDestination: AppDestination.home,
      onSelected: (_) => selections++,
    );

    expect(binding.destination, AppDestination.graph);
    expect(binding.isSelected, isFalse);
    expect(binding.action, isNull);
    expect(selections, 0);
  });

  test('compact open sidebar row navigates before dismissing the drawer', () {
    final events = <String>[];

    runHomeShellSidebarNavigation(
      layoutSpec: ShellLayoutSpec.compact,
      sidebarOpen: true,
      navigate: () => events.add('navigate'),
      onDismissSidebar: () => events.add('dismiss'),
    );

    expect(events, ['navigate', 'dismiss']);
  });

  test('sidebar row does not dismiss a closed or persistent sidebar', () {
    for (final scenario in [
      (spec: ShellLayoutSpec.compact, sidebarOpen: false),
      (spec: ShellLayoutSpec.standard, sidebarOpen: true),
    ]) {
      final events = <String>[];
      runHomeShellSidebarNavigation(
        layoutSpec: scenario.spec,
        sidebarOpen: scenario.sidebarOpen,
        navigate: () => events.add('navigate'),
        onDismissSidebar: () => events.add('dismiss'),
      );
      expect(events, ['navigate']);
    }
  });

  test('empty collections state is limited to collections destination', () {
    expect(
      shouldShowEmptyCollections(
        destination: AppDestination.collections,
        collectionCount: 0,
      ),
      isTrue,
    );
    expect(
      shouldShowEmptyCollections(
        destination: AppDestination.collections,
        collectionCount: 1,
      ),
      isFalse,
    );
    expect(
      shouldShowEmptyCollections(
        destination: AppDestination.library,
        collectionCount: 0,
      ),
      isFalse,
    );
  });

  testWidgets('zero-collection center CTA dispatches collection creation', (
    tester,
  ) async {
    var createCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: buildHomeShellEmptyCollectionsView(
            onAddCollection: () => createCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Collections'), findsOneWidget);
    expect(find.text('Add Collection'), findsOneWidget);
    final addButton = find.byKey(const ValueKey('empty-collections-add'));
    expect(addButton, findsOneWidget);

    await tester.tap(addButton);
    expect(createCount, 1);
  });
}
