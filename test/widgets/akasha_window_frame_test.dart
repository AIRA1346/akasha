import 'package:akasha/services/akasha_window_controller.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/widgets/akasha_window_frame.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('F11 toggles fullscreen and hides only the custom chrome', (
    tester,
  ) async {
    final controller = _FakeWindowController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_testApp(controller));
    expect(find.byKey(const ValueKey('akasha-window-chrome')), findsOneWidget);
    expect(find.text('workspace'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.f11);
    await tester.pump();

    expect(controller.isFullScreen, isTrue);
    expect(find.byKey(const ValueKey('akasha-window-chrome')), findsNothing);
    expect(find.text('workspace'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.f11);
    await tester.pump();

    expect(controller.isFullScreen, isFalse);
    expect(find.byKey(const ValueKey('akasha-window-chrome')), findsOneWidget);
  });

  testWidgets('window controls use the injected controller', (tester) async {
    final controller = _FakeWindowController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    await tester.tap(find.byKey(const ValueKey('window-control-minimize')));
    expect(controller.minimizeCount, 1);

    await tester.tap(find.byKey(const ValueKey('window-control-maximize')));
    await tester.pump();
    expect(controller.isMaximized, isTrue);

    await tester.tap(find.byKey(const ValueKey('window-control-close')));
    expect(controller.closeCount, 1);
  });

  testWidgets('window chrome stretches controls to the right edge', (
    tester,
  ) async {
    final controller = _FakeWindowController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    final chromeRect = tester.getRect(
      find.byKey(const ValueKey('akasha-window-chrome')),
    );
    final minimizeRect = tester.getRect(
      find.byKey(const ValueKey('window-control-minimize')),
    );
    final closeRect = tester.getRect(
      find.byKey(const ValueKey('window-control-close')),
    );

    expect(chromeRect.width, 800);
    expect(closeRect.right, chromeRect.right);
    expect(minimizeRect.left, closeRect.right - (46 * 3));
  });

  testWidgets('window control hover feedback clears on pointer exit', (
    tester,
  ) async {
    final controller = _FakeWindowController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    final control = find.byKey(const ValueKey('window-control-maximize'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(control));
    await tester.pumpAndSettle();

    expect(_controlColor(tester, control), isNot(Colors.transparent));

    await mouse.moveTo(tester.getCenter(find.text('workspace')));
    await tester.pumpAndSettle();

    expect(_controlColor(tester, control), Colors.transparent);
  });
}

Color _controlColor(WidgetTester tester, Finder control) {
  final animated = tester.widget<AnimatedContainer>(
    find.descendant(of: control, matching: find.byType(AnimatedContainer)),
  );
  return (animated.decoration! as BoxDecoration).color!;
}

Widget _testApp(AkashaWindowController controller) {
  return MaterialApp(
    theme: AkashaTheme.dark(),
    home: AkashaWindowFrame(
      controller: controller,
      child: const Scaffold(
        body: Focus(autofocus: true, child: Center(child: Text('workspace'))),
      ),
    ),
  );
}

class _FakeWindowController extends AkashaWindowController {
  bool _fullScreen = false;
  bool _maximized = false;
  int minimizeCount = 0;
  int closeCount = 0;

  @override
  bool get isFullScreen => _fullScreen;

  @override
  bool get isMaximized => _maximized;

  @override
  Future<void> toggleFullScreen() async {
    _fullScreen = !_fullScreen;
    notifyListeners();
  }

  @override
  Future<void> exitFullScreen() async {
    if (!_fullScreen) return;
    _fullScreen = false;
    notifyListeners();
  }

  @override
  Future<void> minimize() async {
    minimizeCount++;
  }

  @override
  Future<void> toggleMaximized() async {
    _maximized = !_maximized;
    notifyListeners();
  }

  @override
  Future<void> close() async {
    closeCount++;
  }
}
