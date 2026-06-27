import 'package:flutter/material.dart';

/// AKASHA spacing scale (R14-A).
abstract final class AkashaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const EdgeInsets workbenchPanel =
      EdgeInsets.fromLTRB(md, md, md, lg);

  /// Home vault banner horizontal/vertical inset (R14-B).
  static const EdgeInsets vaultBanner =
      EdgeInsets.symmetric(horizontal: lg, vertical: 6);

  /// Preview panel header padding (R14-B).
  static const EdgeInsets previewPanelHeader =
      EdgeInsets.fromLTRB(md, 10, xs, md);

  static const EdgeInsets previewPanelHeaderCompact =
      EdgeInsets.fromLTRB(md, 10, xs, 10);

  /// Sanctum page panel top chrome (R14-B).
  static const EdgeInsets sanctumPanelHeader =
      EdgeInsets.fromLTRB(md, sm, md, xs);

  /// Knowledge graph page header (R14-B).
  static const EdgeInsets graphPageHeader =
      EdgeInsets.fromLTRB(xl, xl, xl, sm);
}
