/// Responsive window classes used by the Home shell.
enum ShellLayoutClass { wide, standard, compact }

/// How the primary sidebar participates in the shell layout.
enum ShellSidebarPresentation { persistent, drawer }

/// How the contextual preview is presented without changing its content.
enum ShellPreviewPresentation { inline, overlay, sheet }

/// The topmost modal shell layer dismissed by Escape.
enum ShellEscapeTarget { none, fullscreen, sidebar, commerce, preview }

/// Resolves Escape ordering independently from shell controller state.
ShellEscapeTarget resolveShellEscapeTarget({
  required ShellLayoutSpec layoutSpec,
  required bool sidebarOpen,
  bool commerceOpen = false,
  required bool previewOpen,
  bool fullscreen = false,
}) {
  if (fullscreen) return ShellEscapeTarget.fullscreen;
  if (sidebarOpen &&
      layoutSpec.sidebarPresentation == ShellSidebarPresentation.drawer) {
    return ShellEscapeTarget.sidebar;
  }
  if (commerceOpen) return ShellEscapeTarget.commerce;
  if (previewOpen) return ShellEscapeTarget.preview;
  return ShellEscapeTarget.none;
}

/// Whether the shell preview surface should occupy layout space.
///
/// Desktop inline inspector is gated by [isInspectorOpen]. Compact selection
/// sheets follow actual selection visibility and ignore the inspector pref.
bool resolveShellPreviewVisible({
  required bool persistentInspector,
  required bool isInspectorOpen,
  required bool showSelectionPreview,
}) {
  return persistentInspector ? isInspectorOpen : showSelectionPreview;
}

/// Whether Escape should treat the preview/inspector surface as open.
bool resolveShellPreviewEscapeOpen({
  required ShellLayoutSpec layoutSpec,
  required bool hasOpenPreview,
  required bool isInspectorOpen,
}) {
  if (!hasOpenPreview) return false;
  if (layoutSpec.previewPresentation == ShellPreviewPresentation.inline) {
    return isInspectorOpen;
  }
  return true;
}

/// The minimum-width policy for the center canvas.
enum ShellContentConstraint {
  desktopMinimum(minWidth: ShellLayoutSpec.desktopCenterMinWidth),
  viewportBound(minWidth: 0);

  const ShellContentConstraint({required this.minWidth});

  final double minWidth;
}

/// How much non-essential visual decoration the shell may render.
enum ShellDecorationDensity { full, reduced, minimal }

enum BuildIdentityDockPresentation { hidden, condensed, full }

BuildIdentityDockPresentation resolveBuildIdentityDockPresentation({
  required ShellLayoutClass layoutClass,
  required double viewportWidth,
  required bool hasAppVersion,
}) {
  if (!hasAppVersion) return BuildIdentityDockPresentation.hidden;
  if (layoutClass != ShellLayoutClass.compact) {
    return BuildIdentityDockPresentation.full;
  }
  return viewportWidth >= 840
      ? BuildIdentityDockPresentation.condensed
      : BuildIdentityDockPresentation.hidden;
}

/// Theme-independent geometry and presentation policy for the Home shell.
///
/// Themes may change colors, artwork, and effects, but must not alter any value
/// in this contract.
final class ShellLayoutSpec {
  const ShellLayoutSpec._({
    required this.layoutClass,
    required this.sidebarPresentation,
    required this.previewPresentation,
    required this.contentConstraint,
    required this.decorationDensity,
    required this.sidebarWidth,
    required this.previewWidth,
    required this.appBarHeight,
    required this.dockHeight,
  });

  /// Minimum center width for desktop (wide/standard) layouts.
  static const double desktopCenterMinWidth = 800;

  static const double wideBreakpoint = 1440;
  static const double wideSidebarWidth = 256;
  static const double standardSidebarWidth = 232;
  static const double previewRailWidth = 288;

  /// First width where sidebar + inspector + center minimum all fit inline.
  static const double standardBreakpoint =
      standardSidebarWidth + previewRailWidth + desktopCenterMinWidth;

  static const double appBarContractHeight = 64;
  static const double dockContractHeight = 56;

  static const wide = ShellLayoutSpec._(
    layoutClass: ShellLayoutClass.wide,
    sidebarPresentation: ShellSidebarPresentation.persistent,
    previewPresentation: ShellPreviewPresentation.inline,
    contentConstraint: ShellContentConstraint.desktopMinimum,
    decorationDensity: ShellDecorationDensity.full,
    sidebarWidth: wideSidebarWidth,
    previewWidth: previewRailWidth,
    appBarHeight: appBarContractHeight,
    dockHeight: dockContractHeight,
  );

  static const standard = ShellLayoutSpec._(
    layoutClass: ShellLayoutClass.standard,
    sidebarPresentation: ShellSidebarPresentation.persistent,
    previewPresentation: ShellPreviewPresentation.inline,
    contentConstraint: ShellContentConstraint.desktopMinimum,
    decorationDensity: ShellDecorationDensity.reduced,
    sidebarWidth: standardSidebarWidth,
    previewWidth: previewRailWidth,
    appBarHeight: appBarContractHeight,
    dockHeight: dockContractHeight,
  );

  static const compact = ShellLayoutSpec._(
    layoutClass: ShellLayoutClass.compact,
    sidebarPresentation: ShellSidebarPresentation.drawer,
    previewPresentation: ShellPreviewPresentation.sheet,
    contentConstraint: ShellContentConstraint.viewportBound,
    decorationDensity: ShellDecorationDensity.minimal,
    sidebarWidth: wideSidebarWidth,
    previewWidth: previewRailWidth,
    appBarHeight: appBarContractHeight,
    dockHeight: dockContractHeight,
  );

  final ShellLayoutClass layoutClass;
  final ShellSidebarPresentation sidebarPresentation;
  final ShellPreviewPresentation previewPresentation;
  final ShellContentConstraint contentConstraint;
  final ShellDecorationDensity decorationDensity;
  final double sidebarWidth;
  final double previewWidth;
  final double appBarHeight;
  final double dockHeight;

  double get mainContentMinWidth => contentConstraint.minWidth;

  /// The dock is the compact navigation surface. Desktop layouts already
  /// expose the same destinations in the persistent sidebar.
  bool get showsBottomDock => layoutClass == ShellLayoutClass.compact;

  double get reservedSidebarWidth =>
      sidebarPresentation == ShellSidebarPresentation.persistent
      ? sidebarWidth
      : 0;

  double get reservedPreviewWidth =>
      previewPresentation == ShellPreviewPresentation.inline ? previewWidth : 0;

  /// Inline layouts must reserve enough width for both rails and the center min.
  double get minimumInlineViewportWidth =>
      reservedSidebarWidth + reservedPreviewWidth + mainContentMinWidth;

  static ShellLayoutSpec resolve(double viewportWidth) {
    if (!viewportWidth.isFinite || viewportWidth < 0) {
      throw ArgumentError.value(
        viewportWidth,
        'viewportWidth',
        'must be a finite non-negative value',
      );
    }
    if (viewportWidth >= wideBreakpoint) return wide;
    if (viewportWidth >= standardBreakpoint) return standard;
    return compact;
  }
}
