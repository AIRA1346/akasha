import 'package:flutter/material.dart';

import 'akasha_colors.dart';

/// AKASHA typography scale (R14-A).
abstract final class AkashaTypography {
  static const headline = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AkashaColors.textPrimary,
    height: 1.25,
  );

  static const headlineEditable = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AkashaColors.textPrimary,
    height: 1.2,
  );

  static const sectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AkashaColors.accent,
  );

  static const sectionLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AkashaColors.textMuted,
    letterSpacing: 0.5,
  );

  static const body = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AkashaColors.textPrimary,
  );

  static const bodyEmphasis = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AkashaColors.linkAccent,
  );

  static const bodySecondary = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AkashaColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AkashaColors.textCaption,
  );

  static const micro = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: AkashaColors.textSecondary,
  );

  /// Dialog body copy (R14-B Home).
  static const dialogBody = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AkashaColors.textPrimary,
  );

  /// Settings / form section labels (R14-B Home).
  static const settingsLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AkashaColors.textMuted,
  );

  /// Preview rail title (R14-B).
  static const previewTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AkashaColors.textPrimary,
    height: 1.25,
  );

  /// Compact button / tab labels (R14-B Preview·Sanctum).
  static const compactLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AkashaColors.textSecondary,
  );

  /// Primary action button label (R14-B Preview).
  static const buttonLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AkashaColors.textPrimary,
  );

  /// Graph / browse section titles (R14-B).
  static const graphTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AkashaColors.textPrimary,
  );

  /// List row title (R14-B Graph).
  static const listItemTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AkashaColors.textPrimary,
  );

  /// Sanctum editable title field (R14-B).
  static const editableTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AkashaColors.textPrimary,
  );

  /// Home dashboard section chrome (R14-B).
  static const dashboardSectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AkashaColors.textPrimary,
  );

  static const dashboardPanelTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AkashaColors.textPrimary,
  );

  static const dashboardHero = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AkashaColors.textPrimary,
  );

  static const dashboardLead = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AkashaColors.textMuted,
  );

  /// Smallest dashboard metadata (R14-B).
  static const nano = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w400,
    color: AkashaColors.textMuted,
  );

  /// Sidebar chrome (R14-B).
  static const sidebarBrand = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AkashaColors.textPrimary,
    letterSpacing: 1.2,
  );

  static const sidebarTagline = TextStyle(
    fontSize: 10,
    color: AkashaColors.textCaption,
    letterSpacing: 0.2,
  );

  static const sidebarNavLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AkashaColors.textSecondary,
  );

  static const sidebarNavLabelSelected = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AkashaColors.textPrimary,
  );

  static const sidebarSectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AkashaColors.textCaption,
    letterSpacing: 0.3,
  );

  static const sidebarTrailingLink = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AkashaColors.accent,
  );

  static const sidebarThumbTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AkashaColors.textPrimary,
  );

  static const sidebarThumbTitleActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AkashaColors.textPrimary,
  );

  static const sidebarFooterLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AkashaColors.textMuted,
  );

  /// Markdown editor (R14-B).
  static const editorStatus = caption;

  static const editorSaving = TextStyle(
    fontSize: 10,
    color: AkashaColors.editorAccent,
  );

  static const editorDirty = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AkashaColors.editorUnsaved,
  );

  static const editorMono = TextStyle(
    fontSize: 13,
    height: 1.45,
    fontFamily: 'Consolas',
    color: AkashaColors.textPrimary,
  );

  static const editorSlashTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AkashaColors.textPrimary,
  );

  static const editorSlashTitleSelected = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AkashaColors.editorAccent,
  );

  static const editorSlashSubtitle = TextStyle(
    fontSize: 10,
    color: AkashaColors.textMuted,
  );

  static const editorFindInput = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AkashaColors.textPrimary,
  );

  /// Poster card layouts (R14-B).
  static const posterFactCardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 1.25,
    color: AkashaColors.textPrimary,
  );

  static const posterMetaTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AkashaColors.textPrimary,
  );

  static const posterCategoryLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    color: Color(0xE6FFFFFF),
  );

  static const posterLibraryBadge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AkashaColors.libraryCountBadgeAccent,
  );

  static const posterMetaPill = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  static const posterEntityLinkCount = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AkashaColors.editorAccent,
  );

  static const posterRatingPending = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AkashaColors.ratingPendingAccent,
  );

  static const posterEntityTypeBadge = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: AkashaColors.editorAccent,
  );
}
