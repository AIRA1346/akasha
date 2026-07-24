import 'package:akasha/screens/home/shell_layout_frame.dart';
import 'package:akasha/screens/home/shell_layout_spec.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'compact shows selection sheet even when inspector preference is false',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1024, 720));

      final visible = resolveShellPreviewVisible(
        persistentInspector: false,
        isInspectorOpen: false,
        showSelectionPreview: true,
      );
      expect(visible, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AkashaTheme.dark(),
          home: Scaffold(
            body: ShellLayoutFrame(
              layoutSpec: ShellLayoutSpec.compact,
              sidebarOpen: false,
              onDismissSidebar: () {},
              sidebar: const SizedBox.shrink(),
              center: const Text('Center'),
              preview: const Text('Selection Sheet'),
              previewVisible: visible,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Selection Sheet'), findsOneWidget);
      expect(find.byKey(ShellLayoutFrame.previewKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact hides sheet when there is no selection regardless of inspector pref',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1024, 720));

      final visible = resolveShellPreviewVisible(
        persistentInspector: false,
        isInspectorOpen: true,
        showSelectionPreview: false,
      );
      expect(visible, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          theme: AkashaTheme.dark(),
          home: Scaffold(
            body: ShellLayoutFrame(
              layoutSpec: ShellLayoutSpec.compact,
              sidebarOpen: false,
              onDismissSidebar: () {},
              sidebar: const SizedBox.shrink(),
              center: const Text('Center'),
              preview: const Text('Selection Sheet'),
              previewVisible: visible,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(ShellLayoutFrame.previewKey), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('standard hides inline rail when inspector preference is false', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1366, 768));

    final visible = resolveShellPreviewVisible(
      persistentInspector: true,
      isInspectorOpen: false,
      showSelectionPreview: true,
    );
    expect(visible, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: Scaffold(
          body: ShellLayoutFrame(
            layoutSpec: ShellLayoutSpec.standard,
            sidebarOpen: true,
            onDismissSidebar: () {},
            sidebar: const SizedBox(width: 232, child: Text('Sidebar')),
            center: const Text('Center'),
            preview: const Text('Inspector'),
            previewVisible: visible,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(ShellLayoutFrame.previewKey), findsNothing);
    expect(
      tester.getRect(find.byKey(ShellLayoutFrame.centerKey)).width,
      greaterThanOrEqualTo(800),
    );
    expect(tester.takeException(), isNull);
  });

  test('Escape preview targeting ignores inspector pref on compact', () {
    expect(
      resolveShellEscapeTarget(
        layoutSpec: ShellLayoutSpec.compact,
        sidebarOpen: false,
        previewOpen: resolveShellPreviewEscapeOpen(
          layoutSpec: ShellLayoutSpec.compact,
          hasOpenPreview: true,
          isInspectorOpen: false,
        ),
      ),
      ShellEscapeTarget.preview,
    );

    expect(
      resolveShellEscapeTarget(
        layoutSpec: ShellLayoutSpec.standard,
        sidebarOpen: true,
        previewOpen: resolveShellPreviewEscapeOpen(
          layoutSpec: ShellLayoutSpec.standard,
          hasOpenPreview: true,
          isInspectorOpen: false,
        ),
      ),
      ShellEscapeTarget.none,
    );
  });

  testWidgets(
    'Escape closes compact selection sheet content via shortcut path',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1024, 720));

      var previewOpen = true;
      late StateSetter setHostState;

      await tester.pumpWidget(
        MaterialApp(
          theme: AkashaTheme.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                final layoutSpec = ShellLayoutSpec.compact;
                return CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape): () {
                      final target = resolveShellEscapeTarget(
                        layoutSpec: layoutSpec,
                        sidebarOpen: false,
                        previewOpen: resolveShellPreviewEscapeOpen(
                          layoutSpec: layoutSpec,
                          hasOpenPreview: previewOpen,
                          isInspectorOpen: false,
                        ),
                      );
                      if (target == ShellEscapeTarget.preview) {
                        setState(() => previewOpen = false);
                      }
                    },
                  },
                  child: Focus(
                    autofocus: true,
                    child: ShellLayoutFrame(
                      layoutSpec: layoutSpec,
                      sidebarOpen: false,
                      onDismissSidebar: () {},
                      sidebar: const SizedBox.shrink(),
                      center: const Text('Center'),
                      preview: const Text('Selection Sheet'),
                      previewVisible: previewOpen,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Selection Sheet'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      setHostState(() {});
      await tester.pump();

      expect(previewOpen, isFalse);
      expect(find.byKey(ShellLayoutFrame.previewKey), findsNothing);
    },
  );
}
