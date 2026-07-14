import 'package:flutter/material.dart';

import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../shell_layout_spec.dart';

/// Theme-independent geometry for Work and Entity Preview surfaces.
///
/// The desktop rail keeps the Shell's 288px contract. Compact Preview uses a
/// full-width bottom sheet, but its readable content stays centered and capped
/// so artwork and metadata do not stretch with the viewport.
abstract final class PreviewPanelLayoutSpec {
  static const double sheetContentMaxWidth = 680;
  static const double railHeroMaxHeight = 300;
  static const double sheetHeroMaxHeight = 260;
  static const double sectionGap = 16;
  static const double compactGap = 12;

  static const EdgeInsets railContentPadding = EdgeInsets.fromLTRB(
    14,
    12,
    14,
    20,
  );
  static const EdgeInsets sheetContentPadding = EdgeInsets.fromLTRB(
    24,
    14,
    24,
    28,
  );

  static bool isSheet(ShellPreviewPresentation presentation) =>
      presentation == ShellPreviewPresentation.sheet;

  static double heroMaxHeight(ShellPreviewPresentation presentation) =>
      isSheet(presentation) ? sheetHeroMaxHeight : railHeroMaxHeight;
}

class PreviewPanelSurface extends StatelessWidget {
  const PreviewPanelSurface({
    super.key,
    required this.width,
    required this.presentation,
    required this.child,
  });

  final double width;
  final ShellPreviewPresentation presentation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final isSheet = PreviewPanelLayoutSpec.isSheet(presentation);
    final isOverlay = presentation == ShellPreviewPresentation.overlay;

    return Container(
      width: width,
      clipBehavior: isSheet ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: palette.previewRail,
        borderRadius: isSheet
            ? const BorderRadius.only(
                topLeft: Radius.circular(AkashaRadius.xl),
                topRight: Radius.circular(AkashaRadius.xl),
              )
            : null,
        border: Border(
          left: isSheet
              ? BorderSide.none
              : BorderSide(color: palette.borderSubtle(0.52)),
          top: isSheet
              ? BorderSide(color: palette.borderSubtle(0.52))
              : BorderSide.none,
        ),
        boxShadow: isOverlay || isSheet
            ? [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: isSheet ? 28 : 20,
                  offset: Offset(isSheet ? 0 : -8, isSheet ? -8 : 0),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class PreviewPanelScrollBody extends StatelessWidget {
  const PreviewPanelScrollBody({
    super.key,
    required this.presentation,
    required this.children,
  });

  static const contentKey = ValueKey<String>('preview-panel-content');

  final ShellPreviewPresentation presentation;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isSheet = PreviewPanelLayoutSpec.isSheet(presentation);

    return SingleChildScrollView(
      padding: isSheet
          ? PreviewPanelLayoutSpec.sheetContentPadding
          : PreviewPanelLayoutSpec.railContentPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isSheet
                ? PreviewPanelLayoutSpec.sheetContentMaxWidth
                : double.infinity,
          ),
          child: SizedBox(
            key: contentKey,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
