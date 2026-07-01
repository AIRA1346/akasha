import 'dart:io';

import 'package:flutter/services.dart';

Future<void> quitAkashaApp() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Flutter desktop does not consistently map SystemNavigator.pop to
    // process shutdown, so the explicit app menu exit uses the host process.
    // ignore: avoid_exit
    exit(0);
  }

  await SystemNavigator.pop();
}
