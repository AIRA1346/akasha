import 'package:flutter/material.dart';

/// AKASHA 프리미엄 다크 테마 팔레트 (시안 기준).
abstract final class AkashaColors {
  static const background = Color(0xFF0F111A);
  static const surface = Color(0xFF161824);
  static const surfaceElevated = Color(0xFF1E1E2E);
  static const sidebar = Color(0xFF1E1E2F);
  static const sidebarFooter = Color(0xFF161622);
  static const proBanner = Color(0xFF171725);
  static const border = Color(0xFF2D2D44);
  static const menuSelected = Color(0xFF2A2A3E);
  static const accent = Color(0xFF6C63FF);
  static const accentDark = Color(0xFF4D3FC3);
  static const proButton = Color(0xFF5D3FD3);
  static const thumbPlaceholder = Color(0xFF222533);
  static const newBadgeBg = Color(0xFF1E2838);
  static const newBadgeBorder = Color(0xFF2C3E5A);
  static const newBadgeText = Color(0xFF00E5FF);

  static const personAccent = Color(0xFF00E5FF);
  static const conceptAccent = Color(0xFFFFB74D);
  static const placeAccent = Color(0xFF81C784);
  static const eventAccent = Color(0xFFFF5252);

  /// Workbench surfaces (R14-A).
  static const workbenchPanel = Color(0xFF1A1A28);
  static const workbenchEditor = Color(0xFF12121A);
  static const workbenchListTile = Color(0xFF252535);
  static const workbenchMutedButton = Color(0xFF2E2E3E);

  /// Home dashboard surfaces (R14-B).
  static const dashboardRegistryBridge = Color(0xFF141A28);
  static const browseCardHighlight = Color(0xFF2A3540);

  /// Semantic text (R14-A).
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB0B0B8);
  static const textMuted = Color(0xFF9E9E9E);
  static const textCaption = Color(0xFF757575);
  static const linkAccent = personAccent;

  static const statusDirty = Color(0xFFFFE082);
  static const statusSaved = Color(0xFFB9F6CA);
  static const statusSaving = Color(0xFFB0B0B8);
  static const statusWarning = Color(0xFFFFB300);
  static const editorUnsaved = Color(0xFFFFA000);

  /// Markdown / Sanctum editor chrome (R14-B).
  static const editorAccent = Colors.tealAccent;
  static const editorFieldBg = Color(0xFF0E0E16);
  static const editorPanelBg = Color(0xFF1A1A26);
  static const editorSlashMenuBg = Color(0xE5181824);
  static const editorSlashMenuSelected = Color(0xFF2E2E42);

  /// Poster card fact layout (R14-B).
  static const posterGradientEnd = Color(0xFF252536);
  static const posterArchivedBadge = Color(0xFFCCCCCC);
  static const libraryCountBadgeAccent = Colors.amberAccent;
  static const ratingPendingAccent = Colors.amber;

  static Color borderSubtle([double alpha = 0.04]) =>
      Colors.white.withValues(alpha: alpha);

  static BoxDecoration surfaceCard({Color? borderColor, double radius = 12}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? borderSubtle()),
    );
  }
}
