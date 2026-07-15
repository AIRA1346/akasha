import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Theme-independent operations exposed by the desktop window shell.
///
/// Widgets depend on this contract rather than the plugin so widget tests and
/// future desktop adapters do not need a native method channel.
abstract class AkashaWindowController extends ChangeNotifier {
  bool get isFullScreen;
  bool get isMaximized;

  Future<void> toggleFullScreen();
  Future<void> exitFullScreen();
  Future<void> minimize();
  Future<void> toggleMaximized();
  Future<void> close();
}

/// Initializes the Windows frame before the first application frame.
///
/// Command-mode entrypoints never call this function. Non-Windows platforms
/// keep their native frame until an explicit adapter is introduced.
Future<AkashaWindowController?> initializeAkashaDesktopWindow() async {
  if (kIsWeb || !Platform.isWindows) return null;

  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(1024, 720),
    center: true,
    backgroundColor: Color(0xFF090B0F),
    skipTaskbar: false,
    title: 'AKASHA',
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final controller = _WindowManagerAkashaWindowController();
  await controller.attach();
  return controller;
}

final class _WindowManagerAkashaWindowController extends AkashaWindowController
    with WindowListener {
  bool _isFullScreen = false;
  bool _isMaximized = false;
  bool _attached = false;

  @override
  bool get isFullScreen => _isFullScreen;

  @override
  bool get isMaximized => _isMaximized;

  Future<void> attach() async {
    if (_attached) return;
    _attached = true;
    windowManager.addListener(this);
    _isFullScreen = await windowManager.isFullScreen();
    _isMaximized = await windowManager.isMaximized();
  }

  @override
  Future<void> toggleFullScreen() async {
    await _setFullScreen(!_isFullScreen);
  }

  @override
  Future<void> exitFullScreen() async {
    if (_isFullScreen) await _setFullScreen(false);
  }

  Future<void> _setFullScreen(bool value) async {
    await windowManager.setFullScreen(value);
    _update(fullScreen: value);
  }

  @override
  Future<void> minimize() => windowManager.minimize();

  @override
  Future<void> toggleMaximized() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
      _update(maximized: false);
    } else {
      await windowManager.maximize();
      _update(maximized: true);
    }
  }

  @override
  Future<void> close() => windowManager.close();

  void _update({bool? fullScreen, bool? maximized}) {
    final nextFullScreen = fullScreen ?? _isFullScreen;
    final nextMaximized = maximized ?? _isMaximized;
    if (nextFullScreen == _isFullScreen && nextMaximized == _isMaximized) {
      return;
    }
    _isFullScreen = nextFullScreen;
    _isMaximized = nextMaximized;
    notifyListeners();
  }

  @override
  void onWindowEnterFullScreen() => _update(fullScreen: true);

  @override
  void onWindowLeaveFullScreen() => _update(fullScreen: false);

  @override
  void onWindowMaximize() => _update(maximized: true);

  @override
  void onWindowUnmaximize() => _update(maximized: false);

  @override
  void dispose() {
    if (_attached) windowManager.removeListener(this);
    super.dispose();
  }
}
