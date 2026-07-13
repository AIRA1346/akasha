import 'package:akasha/screens/home/app_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registry has one stable ordered entry for every destination', () {
    final entries = AppDestinationRegistry.ordered;

    expect(entries.map((entry) => entry.destination), AppDestination.values);
    expect(entries.map((entry) => entry.stableId).toSet(), hasLength(6));
    expect(entries.map((entry) => entry.l10nLabelKey).toSet(), hasLength(6));
    expect(entries.map((entry) => entry.shortcut.trigger), const [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
    ]);
    expect(entries.every((entry) => entry.shortcut.alt), isTrue);
  });

  test('Graph and Timeline remain available existing destinations', () {
    final graph = AppDestinationRegistry.definitionFor(AppDestination.graph);
    final timeline = AppDestinationRegistry.definitionFor(
      AppDestination.timeline,
    );

    expect(graph.stableId, 'graph');
    expect(graph.available, isTrue);
    expect(graph.resolveLabel(null), 'Graph');
    expect(timeline.stableId, 'timeline');
    expect(timeline.available, isTrue);
    expect(timeline.resolveLabel(null), 'Timeline');
  });

  test('bindings derive selection and invoke the shared callback', () {
    AppDestination? activated;
    final bindings = AppDestinationRegistry.bindings(
      currentDestination: AppDestination.graph,
      onSelected: (destination) => activated = destination,
    );

    expect(
      bindings.where((binding) => binding.isSelected).single.destination,
      AppDestination.graph,
    );
    expect(bindings.where((binding) => !binding.isSelected), hasLength(5));

    final timeline = bindings.singleWhere(
      (binding) => binding.destination == AppDestination.timeline,
    );
    expect(timeline.action, isNotNull);
    timeline.action!();
    expect(activated, AppDestination.timeline);
  });

  testWidgets('Alt shortcut dispatches the matching global destination', (
    tester,
  ) async {
    AppDestination? activated;
    await tester.pumpWidget(
      MaterialApp(
        home: CallbackShortcuts(
          bindings: AppDestinationRegistry.shortcutBindings(
            onSelected: (destination) => activated = destination,
          ),
          child: const Focus(autofocus: true, child: SizedBox()),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);

    expect(activated, AppDestination.graph);
  });
}
