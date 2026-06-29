import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/membership_apply_result.dart';
import '../models/personal_library_config.dart';
import '../services/library_membership_apply.dart';
import '../services/personal_library_membership_service.dart';
import '../theme/akasha_colors.dart';

part 'work_library_panel_logic_part.dart';
part 'work_library_panel_header_part.dart';
part 'work_library_panel_library_part.dart';
part 'work_library_panel_hide_part.dart';
part 'work_library_panel_actions_part.dart';

/// 서재 멤버십 체크리스트 + (선택) 표시 숨기기 — popover/dialog 공통 본문
class WorkLibraryPanel extends StatefulWidget {
  final String displayTitle;
  final bool showTitleEditor;
  final String initialTitle;
  final String? draftMetaLine;
  final List<String> singleWorkIds;
  final List<String> entireIpWorkIds;
  final bool showIpScopeOption;
  final PersonalLibraryMembershipService membership;
  final String? activeLibraryId;
  final Future<PersonalLibraryConfig?> Function()? onCreateLibrary;
  final VoidCallback? onHideFromRegistry;
  final VoidCallback? onHideFranchise;
  final WorkLibraryPanelApplyCallback? onApply;
  final void Function(MembershipApplyResult result)? onApplied;
  final VoidCallback? onCancel;

  const WorkLibraryPanel({
    super.key,
    required this.displayTitle,
    this.showTitleEditor = false,
    this.initialTitle = '',
    this.draftMetaLine,
    required this.singleWorkIds,
    required this.entireIpWorkIds,
    required this.showIpScopeOption,
    required this.membership,
    this.activeLibraryId,
    this.onCreateLibrary,
    this.onHideFromRegistry,
    this.onHideFranchise,
    this.onApply,
    this.onApplied,
    this.onCancel,
  });

  bool get hasLibrarySection => membership.curatedLibraries.isNotEmpty;

  bool get hasHideSection =>
      onHideFromRegistry != null || onHideFranchise != null;

  @override
  State<WorkLibraryPanel> createState() => _WorkLibraryPanelState();
}

class _WorkLibraryPanelState extends State<WorkLibraryPanel> {
  var _useEntireIp = false;
  late Map<String, bool?> _checked;
  late Map<String, bool?> _initialChecked;
  var _applying = false;
  var _hideExpanded = false;
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _titleCtrl.addListener(() => setState(() {}));
    _syncCheckedFromMembership(this);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _onIpScopeSelectionChanged(bool useEntireIp) {
    setState(() {
      _useEntireIp = useEntireIp;
      _syncCheckedFromMembership(this);
    });
  }

  void _onLibraryCheckChanged(String id, bool? value) {
    setState(() => _checked[id] = value);
  }

  void _onHideExpansionChanged(bool expanded) {
    setState(() => _hideExpanded = expanded);
  }

  void _onLibraryCreated(PersonalLibraryConfig created) {
    setState(() {
      _checked[created.id] = true;
      _initialChecked[created.id] = false;
    });
  }

  void _setApplying(bool applying) {
    setState(() => _applying = applying);
  }

  Future<void> _handleApply() => _workLibraryPanelApply(this);

  @override
  Widget build(BuildContext context) {
    final libraries = _sortedLibraries(this);
    final activeId = widget.activeLibraryId;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onCancel?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWorkLibraryPanelDisplayTitle(this),
                if (widget.showTitleEditor)
                  ..._buildWorkLibraryPanelTitleEditorSection(this),
                if (widget.hasLibrarySection)
                  ..._buildWorkLibraryPanelLibrarySection(
                    this,
                    context,
                    libraries,
                    activeId,
                  )
                else if (widget.onCreateLibrary != null)
                  _buildWorkLibraryPanelEmptyLibrariesHint(),
                if (widget.hasHideSection) ...[
                  const Divider(height: 1),
                  _buildWorkLibraryPanelHideSection(this),
                ],
                _buildWorkLibraryPanelActionsRow(this),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
