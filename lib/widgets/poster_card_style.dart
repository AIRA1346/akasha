import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/enums.dart';
import '../theme/akasha_palette.dart';
import '../utils/status_helpers.dart';

/// PosterCard border·glow·shadow 스타일 상수·해석.
abstract final class PosterCardStyle {
  static const double yearRowHeight = 14;

  static const double borderWidthNotStarted = 2.0;
  static const double borderWidthActive = 2.5;

  static const double depthShadowBlur = 8;
  static const double depthShadowOffsetY = 3;
  static const double idleGlowBlur = 11;
  static const double hoverGlowBlur = 21;
  static const double hoverGlowOffsetY = 8;

  static Color categoryAccent(AkashaItem item, {AkashaPalette? palette}) {
    if (item is EntityItem) {
      return palette?.accent ?? Colors.tealAccent;
    }
    final accent = palette?.accent;
    if (accent != null) {
      return Color.lerp(accent, _categoryBaseAccent(item.category), 0.34) ??
          accent;
    }
    return _categoryBaseAccent(item.category);
  }

  static Color _categoryBaseAccent(MediaCategory category) {
    return switch (category) {
      MediaCategory.manga => const Color(0xFF818CF8),
      MediaCategory.webtoon => const Color(0xFF34D399),
      MediaCategory.animation => const Color(0xFFF472B6),
      MediaCategory.game => const Color(0xFF4ADE80),
      MediaCategory.book => const Color(0xFFFBBF24),
      MediaCategory.movie => const Color(0xFF60A5FA),
      MediaCategory.drama => const Color(0xFFA78BFA),
      MediaCategory.music => const Color(0xFFE879F9),
    };
  }

  static ({Border border, Color glowColor, bool softGlow}) resolveChrome({
    required AkashaItem item,
    required bool highlighted,
    required bool showPoster,
    required List<Color> gradColors,
    required AkashaPalette palette,
  }) {
    final isEntity = item is EntityItem;
    final isNotStarted = isWatchlistItem(item);
    final isFinished = isFinishedItem(item);
    final categoryAccent = PosterCardStyle.categoryAccent(
      item,
      palette: palette,
    );
    final activeAccent = palette.accent;

    if (highlighted) {
      return (
        border: Border.all(color: activeAccent, width: 2.0),
        glowColor: activeAccent,
        softGlow: false,
      );
    }
    if (isEntity) {
      return (
        border: Border.all(
          color: activeAccent.withValues(alpha: 0.42),
          width: 1.0,
        ),
        glowColor: activeAccent,
        softGlow: true,
      );
    }
    if (isNotStarted) {
      return (
        border: Border.all(
          color: showPoster
              ? Colors.white.withValues(alpha: 0.17)
              : categoryAccent.withValues(alpha: 0.44),
          width: borderWidthNotStarted,
        ),
        glowColor: showPoster ? gradColors[0] : categoryAccent,
        softGlow: true,
      );
    }
    if (isFinished) {
      return (
        border: Border.all(
          color: activeAccent.withValues(alpha: 0.76),
          width: borderWidthActive,
        ),
        glowColor: activeAccent,
        softGlow: false,
      );
    }
    final watchingAccent =
        Color.lerp(activeAccent, Colors.greenAccent, 0.32) ?? activeAccent;
    return (
      border: Border.all(
        color: watchingAccent.withValues(alpha: 0.65),
        width: borderWidthActive,
      ),
      glowColor: watchingAccent,
      softGlow: false,
    );
  }

  static List<BoxShadow> cardShadows({
    required bool hovered,
    required Color glowColor,
    required bool softGlow,
  }) {
    final depth = BoxShadow(
      color: Colors.black.withValues(alpha: hovered ? 0.32 : 0.28),
      blurRadius: depthShadowBlur,
      offset: Offset(0, hovered ? depthShadowOffsetY + 1 : depthShadowOffsetY),
    );

    if (hovered) {
      return [
        depth,
        BoxShadow(
          color: glowColor.withValues(alpha: softGlow ? 0.35 : 0.55),
          blurRadius: hoverGlowBlur,
          spreadRadius: 0.5,
          offset: const Offset(0, hoverGlowOffsetY),
        ),
      ];
    }

    return [
      depth,
      BoxShadow(
        color: glowColor.withValues(alpha: softGlow ? 0.08 : 0.12),
        blurRadius: idleGlowBlur,
        offset: Offset.zero,
      ),
    ];
  }
}

/// Shared icon map for entity gallery cards.
IconData iconForEntityAnchorType(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.person => Icons.person_outline,
    EntityAnchorType.concept => Icons.lightbulb_outline,
    EntityAnchorType.event => Icons.event_outlined,
    EntityAnchorType.place => Icons.place_outlined,
    EntityAnchorType.organization => Icons.groups_outlined,
    _ => Icons.category_outlined,
  };
}
