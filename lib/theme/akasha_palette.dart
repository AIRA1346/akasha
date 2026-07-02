import 'package:flutter/material.dart';

import '../models/library_theme.dart';

@immutable
class AkashaPalette extends ThemeExtension<AkashaPalette> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color sidebar;
  final Color sidebarFooter;
  final Color bottomBar;
  final Color menuSelected;
  final Color hoverSurface;
  final Color searchField;
  final Color previewRail;
  final Color workbenchPanel;
  final Color workbenchEditor;
  final Color workbenchTile;
  final Color posterCard;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color thumbPlaceholder;

  const AkashaPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.sidebar,
    required this.sidebarFooter,
    required this.bottomBar,
    required this.menuSelected,
    required this.hoverSurface,
    required this.searchField,
    required this.previewRail,
    required this.workbenchPanel,
    required this.workbenchEditor,
    required this.workbenchTile,
    required this.posterCard,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.thumbPlaceholder,
  });

  static final classic = AkashaPalette.fromLibraryTheme(LibraryTheme.classic);

  factory AkashaPalette.fromLibraryTheme(LibraryTheme theme) {
    final background = theme.backgroundColor;
    final accent = theme.accentColor;
    final surface = _mix(background, Colors.white, 0.045);
    final surfaceElevated = _mix(background, Colors.white, 0.085);
    final sidebar = _mix(background, accent, 0.08);
    final sidebarFooter = _mix(background, Colors.black, 0.16);
    final bottomBar = _mix(background, accent, 0.16);
    final menuSelected = _mix(background, accent, 0.22);
    final hoverSurface = _mix(background, accent, 0.12);
    final searchField = _mix(background, Colors.white, 0.035);
    final previewRail = _mix(background, accent, 0.055);
    final workbenchPanel = _mix(background, accent, 0.075);
    final workbenchEditor = _mix(background, Colors.black, 0.055);
    final workbenchTile = _mix(background, Colors.white, 0.07);
    final posterCard = _mix(background, accent, 0.045);
    final border = _mix(background, accent, 0.34);
    final thumbPlaceholder = _mix(background, Colors.white, 0.12);

    return AkashaPalette(
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      sidebar: sidebar,
      sidebarFooter: sidebarFooter,
      bottomBar: bottomBar,
      menuSelected: menuSelected,
      hoverSurface: hoverSurface,
      searchField: searchField,
      previewRail: previewRail,
      workbenchPanel: workbenchPanel,
      workbenchEditor: workbenchEditor,
      workbenchTile: workbenchTile,
      posterCard: posterCard,
      border: border,
      accent: accent,
      accentSoft: accent.withValues(alpha: 0.14),
      thumbPlaceholder: thumbPlaceholder,
    );
  }

  static Color _mix(Color a, Color b, double amount) {
    return Color.lerp(a, b, amount) ?? a;
  }

  Color borderSubtle([double alpha = 0.14]) => border.withValues(alpha: alpha);

  BoxDecoration surfaceCard({Color? borderColor, double radius = 12}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? borderSubtle(0.24)),
    );
  }

  @override
  AkashaPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? sidebar,
    Color? sidebarFooter,
    Color? bottomBar,
    Color? menuSelected,
    Color? hoverSurface,
    Color? searchField,
    Color? previewRail,
    Color? workbenchPanel,
    Color? workbenchEditor,
    Color? workbenchTile,
    Color? posterCard,
    Color? border,
    Color? accent,
    Color? accentSoft,
    Color? thumbPlaceholder,
  }) {
    return AkashaPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      sidebar: sidebar ?? this.sidebar,
      sidebarFooter: sidebarFooter ?? this.sidebarFooter,
      bottomBar: bottomBar ?? this.bottomBar,
      menuSelected: menuSelected ?? this.menuSelected,
      hoverSurface: hoverSurface ?? this.hoverSurface,
      searchField: searchField ?? this.searchField,
      previewRail: previewRail ?? this.previewRail,
      workbenchPanel: workbenchPanel ?? this.workbenchPanel,
      workbenchEditor: workbenchEditor ?? this.workbenchEditor,
      workbenchTile: workbenchTile ?? this.workbenchTile,
      posterCard: posterCard ?? this.posterCard,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      thumbPlaceholder: thumbPlaceholder ?? this.thumbPlaceholder,
    );
  }

  @override
  AkashaPalette lerp(ThemeExtension<AkashaPalette>? other, double t) {
    if (other is! AkashaPalette) return this;
    return AkashaPalette(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t) ??
          surfaceElevated,
      sidebar: Color.lerp(sidebar, other.sidebar, t) ?? sidebar,
      sidebarFooter:
          Color.lerp(sidebarFooter, other.sidebarFooter, t) ?? sidebarFooter,
      bottomBar: Color.lerp(bottomBar, other.bottomBar, t) ?? bottomBar,
      menuSelected:
          Color.lerp(menuSelected, other.menuSelected, t) ?? menuSelected,
      hoverSurface:
          Color.lerp(hoverSurface, other.hoverSurface, t) ?? hoverSurface,
      searchField: Color.lerp(searchField, other.searchField, t) ?? searchField,
      previewRail: Color.lerp(previewRail, other.previewRail, t) ?? previewRail,
      workbenchPanel:
          Color.lerp(workbenchPanel, other.workbenchPanel, t) ?? workbenchPanel,
      workbenchEditor:
          Color.lerp(workbenchEditor, other.workbenchEditor, t) ??
          workbenchEditor,
      workbenchTile:
          Color.lerp(workbenchTile, other.workbenchTile, t) ?? workbenchTile,
      posterCard: Color.lerp(posterCard, other.posterCard, t) ?? posterCard,
      border: Color.lerp(border, other.border, t) ?? border,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      thumbPlaceholder:
          Color.lerp(thumbPlaceholder, other.thumbPlaceholder, t) ??
          thumbPlaceholder,
    );
  }
}

extension AkashaPaletteContext on BuildContext {
  AkashaPalette get akashaPalette {
    return Theme.of(this).extension<AkashaPalette>() ?? AkashaPalette.classic;
  }
}
