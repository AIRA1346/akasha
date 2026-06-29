import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/feature_flags.dart';
import '../../theme/akasha_colors.dart';
import '../../models/akasha_item.dart';
import '../../models/user_catalog_entity.dart';
import '../../models/browse_card.dart';
import '../../models/browse_entity_scope.dart';
import '../../models/work_drag_payload.dart';
import 'dialogs/home_dialogs_facade.dart';
import 'home_app_bar.dart';
import 'home_shell_body.dart';
import 'home_shell_controller.dart';

part 'home_shell_scaffold_layout_part.dart';
part 'home_shell_scaffold_app_bar_part.dart';
part 'home_shell_scaffold_body_part.dart';
part 'home_shell_scaffold_bottom_nav_part.dart';

/// CallbackShortcuts · Scaffold · AppBar · HomeShellBody (Wave 1.4).
class HomeShellScaffold extends StatelessWidget {
  const HomeShellScaffold({super.key, required this.controller});

  final HomeShellController controller;

  @override
  Widget build(BuildContext context) {
    return _homeShellScaffoldRoot(context, controller);
  }
}
