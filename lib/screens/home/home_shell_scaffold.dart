import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/feature_flags.dart';
import '../../theme/akasha_palette.dart';
import '../../models/akasha_item.dart';
import '../../models/user_catalog_entity.dart';
import '../../models/browse_card.dart';
import '../../models/browse_entity_scope.dart';
import '../../models/work_drag_payload.dart';
import 'app_destination.dart';
import 'dialogs/app_preferences_dialog.dart';
import 'dialogs/home_dialogs_facade.dart';
import 'home_app_bar.dart';
import 'home_shell_body.dart';
import 'home_shell_controller.dart';
import 'shell_layout_spec.dart';
import '../../utils/app_l10n.dart';

part 'home_shell_scaffold_layout_part.dart';
part 'home_shell_scaffold_app_bar_part.dart';
part 'home_shell_scaffold_body_part.dart';
part 'home_shell_scaffold_bottom_nav_part.dart';

/// CallbackShortcuts · Scaffold · AppBar · HomeShellBody (Wave 1.4).
class HomeShellScaffold extends StatefulWidget {
  const HomeShellScaffold({super.key, required this.controller});

  final HomeShellController controller;

  @override
  State<HomeShellScaffold> createState() => _HomeShellScaffoldState();
}

class _HomeShellScaffoldState extends State<HomeShellScaffold> {
  late final FocusNode _shortcutFocusNode = FocusNode(
    debugLabel: 'HomeShellScaffold.shortcuts',
  );
  late bool _hadOpenWorkbenchDetail;

  @override
  void initState() {
    super.initState();
    _hadOpenWorkbenchDetail = widget.controller.workbench.hasOpenDetail;
    widget.controller.workbench.addListener(_handleWorkbenchFocusTransition);
  }

  @override
  void didUpdateWidget(HomeShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.workbench.removeListener(
      _handleWorkbenchFocusTransition,
    );
    _hadOpenWorkbenchDetail = widget.controller.workbench.hasOpenDetail;
    widget.controller.workbench.addListener(_handleWorkbenchFocusTransition);
  }

  @override
  void dispose() {
    widget.controller.workbench.removeListener(_handleWorkbenchFocusTransition);
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  void _handleWorkbenchFocusTransition() {
    final hasOpenDetail = widget.controller.workbench.hasOpenDetail;
    if (_hadOpenWorkbenchDetail && !hasOpenDetail) {
      _requestShortcutFocusAfterFrame();
    }
    _hadOpenWorkbenchDetail = hasOpenDetail;
  }

  void _requestShortcutFocusAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      _shortcutFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _homeShellScaffoldRoot(
      context,
      widget.controller,
      _shortcutFocusNode,
    );
  }
}
