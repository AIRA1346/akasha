import 'package:flutter/material.dart';

import '../../../models/membership_apply_result.dart';
import '../../../models/personal_library_config.dart';
import '../../../services/personal_library_membership_service.dart';
import '../../../widgets/work_library_panel.dart';

/// E1 — 카드 근처 popover · E2/E3 중앙 dialog
class WorkLibraryMenuRequest {
  final String displayTitle;
  final List<String> singleWorkIds;
  final List<String> entireIpWorkIds;
  final bool showIpScopeOption;
  final PersonalLibraryMembershipService membership;
  final String? activeLibraryId;
  final Future<PersonalLibraryConfig?> Function()? onCreateLibrary;
  final VoidCallback? onHideFromRegistry;
  final VoidCallback? onHideFranchise;

  const WorkLibraryMenuRequest({
    required this.displayTitle,
    required this.singleWorkIds,
    required this.entireIpWorkIds,
    required this.showIpScopeOption,
    required this.membership,
    this.activeLibraryId,
    this.onCreateLibrary,
    this.onHideFromRegistry,
    this.onHideFranchise,
  });
}

Offset _clampPopoverPosition({
  required Offset anchor,
  required Size screen,
  required Size panel,
}) {
  const margin = 8.0;
  var left = anchor.dx;
  var top = anchor.dy;
  if (left + panel.width > screen.width - margin) {
    left = screen.width - panel.width - margin;
  }
  if (top + panel.height > screen.height - margin) {
    top = anchor.dy - panel.height;
  }
  left = left.clamp(margin, screen.width - panel.width - margin);
  top = top.clamp(margin, screen.height - panel.height - margin);
  return Offset(left, top);
}

/// 우클릭 좌표 근처 popover (Windows E1)
Future<MembershipApplyResult?> showWorkLibraryPopover(
  BuildContext context, {
  required Offset anchor,
  required WorkLibraryMenuRequest request,
}) {
  const panelSize = Size(320, 420);

  return showGeneralDialog<MembershipApplyResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '서재 메뉴 닫기',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, animation, secondaryAnimation) {
      final screen = MediaQuery.sizeOf(ctx);
      final pos = _clampPopoverPosition(
        anchor: anchor,
        screen: screen,
        panel: panelSize,
      );

      return Stack(
        children: [
          Positioned(
            left: pos.dx,
            top: pos.dy,
            child: Material(
              elevation: 12,
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: _buildPanel(
                ctx,
                request,
                (result) => Navigator.of(ctx).pop(result),
                () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// 워크벤치·검색 등 anchor 없는 진입점 (E2/E3/E4)
Future<MembershipApplyResult?> showWorkLibraryDialog(
  BuildContext context, {
  required WorkLibraryMenuRequest request,
}) {
  return showDialog<MembershipApplyResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      contentPadding: EdgeInsets.zero,
      content: _buildPanel(
        ctx,
        request,
        (result) => Navigator.of(ctx).pop(result),
        () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

Widget _buildPanel(
  BuildContext context,
  WorkLibraryMenuRequest request,
  void Function(MembershipApplyResult result) onApplied,
  VoidCallback onCancel,
) {
  return WorkLibraryPanel(
    displayTitle: request.displayTitle,
    singleWorkIds: request.singleWorkIds,
    entireIpWorkIds: request.entireIpWorkIds,
    showIpScopeOption: request.showIpScopeOption,
    membership: request.membership,
    activeLibraryId: request.activeLibraryId,
    onCreateLibrary: request.onCreateLibrary,
    onHideFromRegistry: request.onHideFromRegistry,
    onHideFranchise: request.onHideFranchise,
    onApplied: onApplied,
    onCancel: onCancel,
  );
}

/// @deprecated `showWorkLibraryDialog` 사용
Future<void> showAddToLibrarySheet(
  BuildContext context, {
  required String displayTitle,
  required PersonalLibraryMembershipService membership,
  required List<String> workIds,
  String? activeLibraryId,
  Future<PersonalLibraryConfig?> Function()? onCreateLibrary,
  bool showIpScopeOption = false,
  List<String>? entireIpWorkIds,
}) async {
  await showWorkLibraryDialog(
    context,
    request: WorkLibraryMenuRequest(
      displayTitle: displayTitle,
      singleWorkIds: workIds,
      entireIpWorkIds: entireIpWorkIds ?? workIds,
      showIpScopeOption: showIpScopeOption,
      membership: membership,
      activeLibraryId: activeLibraryId,
      onCreateLibrary: onCreateLibrary,
    ),
  );
}
