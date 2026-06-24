import 'package:akasha/config/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Steam v1 hides post-v1 home and R15 chrome', () {
    expect(FeatureFlags.showRecallCard, isFalse);
    expect(FeatureFlags.showDiscoveryHome, isFalse);
    expect(FeatureFlags.showHomeUniverseSection, isFalse);
    expect(FeatureFlags.showTimeline, isFalse);
    expect(FeatureFlags.showWorkbenchBreadcrumb, isFalse);
    expect(FeatureFlags.showPreviewMemoBar, isFalse);
  });

  test('Steam v1 keeps core catalog and vault features enabled', () {
    expect(FeatureFlags.catalogContributions, isTrue);
    expect(FeatureFlags.showKnowledgeGraph, isTrue);
  });
}
