/// Responsive window classes used by the Home shell.
enum ShellLayoutClass { wide, standard, compact }

/// How the primary sidebar participates in the shell layout.
enum ShellSidebarPresentation { persistent, drawer }

/// How the contextual preview is presented without changing its content.
enum ShellPreviewPresentation { inline, overlay, sheet }

/// The topmost modal shell layer dismissed by Escape.
enum ShellEscapeTarget { none, fullscreen, sidebar, preview }

/// Resolves Escape ordering independently from shell controller state.
ShellEscapeTarget resolveShellEscapeTarget({
  required ShellLayoutSpec layoutSpec,
  required bool sidebarOpen,
  required bool previewOpen,
  bool fullscreen = false,
}) {
  if (fullscreen) return ShellEscapeTarget.fullscreen;
  if (sidebarOpen &&
      layoutSpec.sidebarPresentation == ShellSidebarPresentation.drawer) {
    return ShellEscapeTarget.sidebar;
  }
  if (previewOpen) return ShellEscapeTarget.preview;
  return ShellEscapeTarget.none;
}

/// The minimum-width policy for the center canvas.
enum ShellContentConstraint {
  desktopMinimum(minWidth: 800),
  viewportBound(minWidth: 0);

  const ShellContentConstraint({required this.minWidth});

  final double minWidth;
}

/// How much non-essential visual decoration the shell may render.
enum ShellDecorationDensity { full, reduced, minimal }

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

  static const double wideBreakpoint = 1440;
  static const double standardBreakpoint = 1180;

  static const double wideSidebarWidth = 256;
  static const double standardSidebarWidth = 232;
  static const double previewRailWidth = 288;
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
    previewPresentation: ShellPreviewPresentation.overlay,
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

  double get reservedSidebarWidth =>
      sidebarPresentation == ShellSidebarPresentation.persistent
      ? sidebarWidth
      : 0;

  double get reservedPreviewWidth =>
      previewPresentation == ShellPreviewPresentation.inline ? previewWidth : 0;

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
