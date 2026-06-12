import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/membership_apply_result.dart';
import '../../../models/personal_library_config.dart';
import '../../../services/library_membership_apply.dart';
import '../../../services/personal_library_membership_service.dart';
import '../../../widgets/work_library_panel.dart';

/// popover/dialog가 열려 있는 동안 true — 그리드 스크롤 dismiss용
bool get isWorkLibraryMenuOpen => _workLibraryMenuOpenCount > 0;
int _workLibraryMenuOpenCount = 0;

Future<T?> _withMenuOpen<T>(Future<T?> Function() show) async {
  _workLibraryMenuOpenCount++;
  try {
    return await show();
  } finally {
    _workLibraryMenuOpenCount--;
  }
}

/// E1 — 카드 근처 popover · E2/E3 중앙 dialog
class WorkLibraryMenuRequest {
  final String displayTitle;
  final AkashaItem draftItem;
  final bool showTitleEditor;
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

  const WorkLibraryMenuRequest({
    required this.displayTitle,
    required this.draftItem,
    required this.showTitleEditor,
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
  const panelSize = Size(320, 480);

  return _withMenuOpen(
    () => showGeneralDialog<MembershipApplyResult>(
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

      return _ScrollDismissOverlay(
        onDismiss: () => Navigator.of(ctx).pop(),
        child: Stack(
          fit: StackFit.expand,
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
        ),
      );
    },
    ),
  );
}

/// 워크벤치·검색 등 anchor 없는 진입점 (E2/E3/E4)
Future<MembershipApplyResult?> showWorkLibraryDialog(
  BuildContext context, {
  required WorkLibraryMenuRequest request,
}) {
  return _withMenuOpen(
    () => showDialog<MembershipApplyResult>(
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
    showTitleEditor: request.showTitleEditor,
    initialTitle: request.draftItem.title,
    draftMetaLine: request.draftMetaLine,
    singleWorkIds: request.singleWorkIds,
    entireIpWorkIds: request.entireIpWorkIds,
    showIpScopeOption: request.showIpScopeOption,
    membership: request.membership,
    activeLibraryId: request.activeLibraryId,
    onCreateLibrary: request.onCreateLibrary,
    onHideFromRegistry: request.onHideFromRegistry,
    onHideFranchise: request.onHideFranchise,
    onApply: request.onApply,
    onApplied: onApplied,
    onCancel: onCancel,
  );
}

/// popover 열린 상태에서 휠·스크롤 시 닫기 (Phase C)
class _ScrollDismissOverlay extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _ScrollDismissOverlay({
    required this.child,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification) {
          onDismiss();
        }
        return false;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerSignal: (signal) {
          if (signal is PointerScrollEvent) {
            onDismiss();
          }
        },
        child: child,
      ),
    );
  }
}
