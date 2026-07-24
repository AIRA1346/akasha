import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/screens/home/app_destination.dart';
import 'package:akasha/screens/home/shell_layout_spec.dart';
import 'package:akasha/screens/home/views/home_inspector_panel.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('default inspector composes registered context modules', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: HomeInspectorPanel(
              width: 288,
              presentation: ShellPreviewPresentation.inline,
              snapshot: HomeInspectorSnapshot(
                destination: AppDestination.library,
                vaultLinked: true,
                archiveCount: 12,
                collectionCount: 3,
                recentCount: 4,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeInspectorPanel.panelKey), findsOneWidget);
    expect(find.text('Context inspector'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Archive summary'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Local vault connected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('module registry is ordered and can be extended independently', (
    tester,
  ) async {
    const module = _FixtureInspectorModule();
    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: const Scaffold(
          body: HomeInspectorPanel(
            width: 288,
            presentation: ShellPreviewPresentation.inline,
            snapshot: HomeInspectorSnapshot(
              destination: AppDestination.home,
              vaultLinked: false,
              archiveCount: 0,
              collectionCount: 0,
              recentCount: 0,
            ),
            modules: [module],
          ),
        ),
      ),
    );

    expect(find.text('Future module'), findsOneWidget);
    expect(find.text('Context inspector'), findsOneWidget);
  });

  testWidgets(
    'rail preserves contextual state while default context is shown',
    (tester) async {
      const contextualKey = ValueKey('contextual-state');

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeInspectorRail(
            defaultPanel: Text('Default context'),
            contextualPanel: _StatefulSentinel(key: contextualKey),
            showContextual: true,
          ),
        ),
      );
      final contextualState = tester.state(
        find.byKey(contextualKey, skipOffstage: false),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeInspectorRail(
            defaultPanel: Text('Default context'),
            contextualPanel: _StatefulSentinel(key: contextualKey),
            showContextual: false,
          ),
        ),
      );

      expect(find.text('Default context'), findsOneWidget);
      expect(
        tester.state(find.byKey(contextualKey, skipOffstage: false)),
        same(contextualState),
      );
    },
  );
}

class _StatefulSentinel extends StatefulWidget {
  const _StatefulSentinel({super.key});

  @override
  State<_StatefulSentinel> createState() => _StatefulSentinelState();
}

class _StatefulSentinelState extends State<_StatefulSentinel> {
  @override
  Widget build(BuildContext context) => const Text('Contextual preview');
}

class _FixtureInspectorModule implements HomeInspectorModule {
  const _FixtureInspectorModule();

  @override
  String get id => 'fixture';

  @override
  int get priority => 1;

  @override
  bool supports(HomeInspectorSnapshot snapshot) => true;

  @override
  Widget build(BuildContext context, HomeInspectorSnapshot snapshot) {
    return const Text('Future module');
  }
}
