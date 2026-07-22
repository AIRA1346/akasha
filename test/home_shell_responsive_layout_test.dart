import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/screens/home/shell_layout_frame.dart';
import 'package:akasha/screens/home/shell_layout_spec.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('1600x900 lays out 256 + center + 288 inline', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpFrame(tester, size: const Size(1600, 900));

    final sidebar = tester.getRect(
      find.byKey(ShellLayoutFrame.sidebarFrameKey),
    );
    final center = tester.getRect(find.byKey(ShellLayoutFrame.centerKey));
    final preview = tester.getRect(find.byKey(ShellLayoutFrame.previewKey));

    expect(sidebar, const Rect.fromLTWH(0, 0, 256, 900));
    expect(center, const Rect.fromLTWH(256, 0, 1056, 900));
    expect(preview, const Rect.fromLTWH(1312, 0, 288, 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('1366x768 reserves a stable inline inspector rail', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const size = Size(1366, 768);
    await _pumpFrame(tester, size: size);

    final sidebar = tester.getRect(
      find.byKey(ShellLayoutFrame.sidebarFrameKey),
    );
    final centerWithPreview = tester.getRect(
      find.byKey(ShellLayoutFrame.centerKey),
    );
    final preview = tester.getRect(find.byKey(ShellLayoutFrame.previewKey));

    expect(sidebar, const Rect.fromLTWH(0, 0, 232, 768));
    expect(centerWithPreview, const Rect.fromLTWH(232, 0, 846, 768));
    expect(preview, const Rect.fromLTWH(1078, 0, 288, 768));

    await _pumpFrame(
      tester,
      size: size,
      preview: const _Slot(label: 'Replacement inspector content'),
    );
    expect(
      tester.getRect(find.byKey(ShellLayoutFrame.centerKey)),
      centerWithPreview,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('1272x720 inspector toggle releases and restores canvas width', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const size = Size(1272, 720);
    await _pumpFrame(tester, size: size);

    final centerWithPreview = tester.getRect(
      find.byKey(ShellLayoutFrame.centerKey),
    );
    expect(centerWithPreview, const Rect.fromLTWH(232, 0, 752, 720));
    expect(
      tester.getRect(find.byKey(ShellLayoutFrame.previewKey)),
      const Rect.fromLTWH(984, 0, 288, 720),
    );

    await _pumpFrame(tester, size: size, previewVisible: false);
    expect(
      tester.getRect(find.byKey(ShellLayoutFrame.centerKey)),
      const Rect.fromLTWH(232, 0, 1040, 720),
    );

    await _pumpFrame(tester, size: size);
    expect(
      tester.getRect(find.byKey(ShellLayoutFrame.centerKey)),
      centerWithPreview,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('1024x720 uses a drawer and bottom preview sheet', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpFrame(tester, size: const Size(1024, 720));

    final sidebar = tester.getRect(
      find.byKey(ShellLayoutFrame.sidebarFrameKey),
    );
    final center = tester.getRect(find.byKey(ShellLayoutFrame.centerKey));
    final preview = tester.getRect(find.byKey(ShellLayoutFrame.previewKey));

    expect(sidebar, const Rect.fromLTWH(0, 0, 256, 720));
    expect(center, const Rect.fromLTWH(0, 0, 1024, 720));
    expect(preview.width, 1024);
    expect(preview.bottom, 720);
    expect(preview.height, closeTo(518.4, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('all official themes keep identical shell geometry', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [
      Size(1600, 900),
      Size(1366, 768),
      Size(1024, 720),
    ]) {
      Map<String, Rect>? baseline;
      for (final preset in AkashaThemeRegistry.presets) {
        await _pumpFrame(tester, size: size, preset: preset);
        final current = _geometry(tester);
        baseline ??= current;
        expect(current, baseline, reason: '${preset.id} $size');
        expect(tester.takeException(), isNull, reason: '${preset.id} $size');
      }
    }
  });

  testWidgets(
    'center and preview state stay mounted across 1600-1366-1024-1600',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const centerKey = ValueKey<String>('center-mounted-sentinel');
      const previewKey = ValueKey<String>('preview-mounted-sentinel');
      const center = _MountedSentinel(key: centerKey, label: 'center');
      const preview = _MountedSentinel(key: previewKey, label: 'preview');

      await _pumpFrame(
        tester,
        size: const Size(1600, 900),
        center: center,
        preview: preview,
      );
      final centerState = tester.state(find.byKey(centerKey));
      final previewState = tester.state(find.byKey(previewKey));

      for (final size in const [
        Size(1366, 768),
        Size(1024, 720),
        Size(1600, 900),
      ]) {
        await _pumpFrame(tester, size: size, center: center, preview: preview);
        expect(tester.state(find.byKey(centerKey)), same(centerState));
        expect(tester.state(find.byKey(previewKey)), same(previewState));
        expect(centerState.mounted, isTrue);
        expect(previewState.mounted, isTrue);
      }
    },
  );

  testWidgets('inspector toggle preserves center and preview state', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    const centerKey = ValueKey<String>('preview-toggle-center-sentinel');
    const previewKey = ValueKey<String>('preview-toggle-preview-sentinel');
    final center = _MountedScrollableSentinel(
      key: centerKey,
      controller: scrollController,
    );
    const preview = _MountedSentinel(key: previewKey, label: 'Preview');
    const size = Size(1366, 768);

    await _pumpFrame(tester, size: size, center: center, preview: preview);
    final centerState = tester.state(find.byKey(centerKey));
    final previewState = tester.state(find.byKey(previewKey));
    final centerRect = tester.getRect(find.byKey(ShellLayoutFrame.centerKey));
    scrollController.jumpTo(320);
    await tester.pump();
    expect(scrollController.offset, 320);

    await _pumpFrame(
      tester,
      size: size,
      center: center,
      preview: preview,
      previewVisible: false,
    );
    expect(find.byKey(ShellLayoutFrame.previewKey), findsNothing);
    expect(
      tester.state(find.byKey(previewKey, skipOffstage: false)),
      same(previewState),
    );
    expect(previewState.mounted, isTrue);
    expect(tester.state(find.byKey(centerKey)), same(centerState));
    expect(centerState.mounted, isTrue);
    expect(scrollController.offset, 320);
    expect(
      tester.getRect(find.byKey(ShellLayoutFrame.centerKey)),
      const Rect.fromLTWH(232, 0, 1134, 768),
    );

    await _pumpFrame(tester, size: size, center: center, preview: preview);
    expect(find.byKey(ShellLayoutFrame.previewKey), findsOneWidget);
    expect(tester.state(find.byKey(previewKey)), same(previewState));
    expect(tester.state(find.byKey(centerKey)), same(centerState));
    expect(centerState.mounted, isTrue);
    expect(scrollController.offset, 320);
    expect(tester.getRect(find.byKey(ShellLayoutFrame.centerKey)), centerRect);
  });

  testWidgets(
    'compact drawer traps focus, excludes background, and restores focus',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1024, 720));
      final backgroundFocus = FocusNode(debugLabel: 'background');
      final firstDrawerFocus = FocusNode(debugLabel: 'drawer-first');
      final secondDrawerFocus = FocusNode(debugLabel: 'drawer-second');
      addTearDown(backgroundFocus.dispose);
      addTearDown(firstDrawerFocus.dispose);
      addTearDown(secondDrawerFocus.dispose);
      var sidebarOpen = false;
      late StateSetter setHostState;

      await tester.pumpWidget(
        MaterialApp(
          theme: AkashaTheme.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return ShellLayoutFrame(
                  layoutSpec: ShellLayoutSpec.compact,
                  sidebarOpen: sidebarOpen,
                  onDismissSidebar: () {
                    setState(() => sidebarOpen = false);
                  },
                  sidebar: Column(
                    children: [
                      TextButton(
                        focusNode: firstDrawerFocus,
                        onPressed: () {},
                        child: const Text('First drawer action'),
                      ),
                      TextButton(
                        focusNode: secondDrawerFocus,
                        onPressed: () {},
                        child: const Text('Second drawer action'),
                      ),
                    ],
                  ),
                  center: TextButton(
                    focusNode: backgroundFocus,
                    onPressed: () {},
                    child: const Text('Background action'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      backgroundFocus.requestFocus();
      await tester.pump();
      expect(backgroundFocus.hasFocus, isTrue);

      setHostState(() => sidebarOpen = true);
      await tester.pump();
      await tester.pump();

      expect(backgroundFocus.canRequestFocus, isFalse);
      expect(firstDrawerFocus.hasFocus || secondDrawerFocus.hasFocus, isTrue);

      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(backgroundFocus.hasFocus, isFalse);
        expect(firstDrawerFocus.hasFocus || secondDrawerFocus.hasFocus, isTrue);
      }

      setHostState(() => sidebarOpen = false);
      await tester.pump();
      await tester.pump();
      expect(backgroundFocus.canRequestFocus, isTrue);
      expect(backgroundFocus.hasFocus, isTrue);
    },
  );

  test('Escape orders fullscreen, compact drawer, commerce, and preview', () {
    expect(
      resolveShellEscapeTarget(
        layoutSpec: ShellLayoutSpec.compact,
        sidebarOpen: true,
        commerceOpen: true,
        previewOpen: true,
        fullscreen: true,
      ),
      ShellEscapeTarget.fullscreen,
    );
    expect(
      resolveShellEscapeTarget(
        layoutSpec: ShellLayoutSpec.compact,
        sidebarOpen: true,
        commerceOpen: true,
        previewOpen: true,
      ),
      ShellEscapeTarget.sidebar,
    );
    expect(
      resolveShellEscapeTarget(
        layoutSpec: ShellLayoutSpec.compact,
        sidebarOpen: false,
        commerceOpen: true,
        previewOpen: true,
      ),
      ShellEscapeTarget.commerce,
    );
    expect(
      resolveShellEscapeTarget(
        layoutSpec: ShellLayoutSpec.standard,
        sidebarOpen: true,
        commerceOpen: true,
        previewOpen: true,
      ),
      ShellEscapeTarget.commerce,
    );
    expect(
      resolveShellEscapeTarget(
        layoutSpec: ShellLayoutSpec.standard,
        sidebarOpen: true,
        previewOpen: true,
      ),
      ShellEscapeTarget.preview,
    );
  });
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  required Size size,
  AkashaThemePreset preset = AkashaThemeRegistry.classicDarkPreset,
  bool showPreview = true,
  bool previewVisible = true,
  Widget? center,
  Widget? preview,
}) async {
  await tester.binding.setSurfaceSize(size);
  final spec = ShellLayoutSpec.resolve(size.width);

  await tester.pumpWidget(
    MaterialApp(
      theme: AkashaTheme.forPreset(preset),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: const TextScaler.linear(1.25),
            disableAnimations: true,
          ),
          child: child!,
        );
      },
      home: Scaffold(
        body: ShellLayoutFrame(
          layoutSpec: spec,
          sidebarOpen: true,
          onDismissSidebar: () {},
          sidebar: const _Slot(label: 'Sidebar'),
          center: center ?? const _Slot(label: 'Center content at 125%'),
          preview: showPreview
              ? preview ?? const _Slot(label: 'Preview content at 125%')
              : null,
          previewVisible: previewVisible,
        ),
      ),
    ),
  );
  await tester.pump();
}

Map<String, Rect> _geometry(WidgetTester tester) {
  return {
    'sidebar': tester.getRect(find.byKey(ShellLayoutFrame.sidebarFrameKey)),
    'center': tester.getRect(find.byKey(ShellLayoutFrame.centerKey)),
    'preview': tester.getRect(find.byKey(ShellLayoutFrame.previewKey)),
  };
}

class _Slot extends StatelessWidget {
  const _Slot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(child: Text(label)),
    );
  }
}

class _MountedSentinel extends StatefulWidget {
  const _MountedSentinel({super.key, required this.label});

  final String label;

  @override
  State<_MountedSentinel> createState() => _MountedSentinelState();
}

class _MountedSentinelState extends State<_MountedSentinel> {
  @override
  Widget build(BuildContext context) => Text(widget.label);
}

class _MountedScrollableSentinel extends StatefulWidget {
  const _MountedScrollableSentinel({super.key, required this.controller});

  final ScrollController controller;

  @override
  State<_MountedScrollableSentinel> createState() =>
      _MountedScrollableSentinelState();
}

class _MountedScrollableSentinelState
    extends State<_MountedScrollableSentinel> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.controller,
      children: const [SizedBox(height: 2000)],
    );
  }
}
