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
}
