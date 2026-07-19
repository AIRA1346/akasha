import 'package:akasha/config/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Steam v1 hides post-v1 home and R15 chrome', () {
    expect(FeatureFlags.showRecallCard, isFalse);
    expect(FeatureFlags.showDiscoveryHome, isFalse);
    expect(FeatureFlags.showHomeUniverseSection, isFalse);
    expect(FeatureFlags.showTimeline, isFalse);
    expect(FeatureFlags.showWorkbenchBreadcrumb, isFalse);
  });

  test('Steam v1 keeps catalog enabled and experimental Graph CTAs off', () {
    expect(FeatureFlags.catalogContributions, isTrue);
    expect(FeatureFlags.showKnowledgeGraph, isFalse);
  });

  test('Steam v1 production Commerce candidate enables IAP without sandbox', () {
    expect(FeatureFlags.steamInAppPurchasesEnabled, isTrue);
    expect(FeatureFlags.steamInventorySandboxTransactionsEnabled, isFalse);
    expect(FeatureFlags.steamInventoryPlaytimeRewardsEnabled, isTrue);
    expect(FeatureFlags.steamCommerceProviderEnabled, isTrue);
    expect(FeatureFlags.steamCommerceTransactionsEnabled, isTrue);
  });

  test('Production Commerce does not enable post-v1 experimental surfaces', () {
    // Debug/POC/sandbox defaults must not be confused with production IAP.
    expect(FeatureFlags.steamInventorySandboxTransactionsEnabled, isFalse);
    expect(FeatureFlags.showRecallCard, isFalse);
    expect(FeatureFlags.showKnowledgeGraph, isFalse);
    expect(FeatureFlags.showDiscoveryHome, isFalse);
  });
}
