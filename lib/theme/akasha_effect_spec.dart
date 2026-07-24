import 'package:flutter/foundation.dart';

/// Stable compositor slots available to visual effect implementations.
enum AkashaEffectLayer { background, interaction }

/// Declarative, theme-owned request for an effect implementation.
///
/// Presets never contain executable widgets. They select a registered effect
/// by ID and provide bounded tuning data; the runtime registry owns painting,
/// input handling, lifecycle, and performance behavior.
@immutable
class AkashaEffectSpec {
  const AkashaEffectSpec({
    required this.id,
    required this.layer,
    this.requiresMotion = true,
    this.intensity = 1,
    this.maxActiveElements = 32,
  }) : assert(id != ''),
       assert(intensity >= 0 && intensity <= 1),
       assert(maxActiveElements >= 0 && maxActiveElements <= 256);

  final String id;
  final AkashaEffectLayer layer;
  final bool requiresMotion;
  final double intensity;
  final int maxActiveElements;

  @override
  bool operator ==(Object other) {
    return other is AkashaEffectSpec &&
        other.id == id &&
        other.layer == layer &&
        other.requiresMotion == requiresMotion &&
        other.intensity == intensity &&
        other.maxActiveElements == maxActiveElements;
  }

  @override
  int get hashCode =>
      Object.hash(id, layer, requiresMotion, intensity, maxActiveElements);
}
