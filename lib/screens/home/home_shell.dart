import 'package:flutter/material.dart';

import 'home_shell_controller.dart';
import 'home_shell_host.dart';
import 'home_shell_scaffold.dart';

/// Home ?? Shell ? controller ??? ?? (Wave 1.4 ? ADR-007 ?250?).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> implements HomeShellHost {
  late final HomeShellController _controller;

  @override
  void scheduleRebuild([void Function()? mutate]) {
    if (!mounted) return;
    setState(() => mutate?.call());
  }

  @override
  void initState() {
    super.initState();
    _controller = HomeShellController(this);
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeShellScaffold(controller: _controller);
  }
}
