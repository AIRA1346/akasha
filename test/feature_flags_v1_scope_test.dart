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

  test('Steam IAP remains disabled until payment flow is verified', () {
    expect(FeatureFlags.steamInAppPurchasesEnabled, isFalse);
    expect(FeatureFlags.steamInventorySandboxTransactionsEnabled, isFalse);
    expect(FeatureFlags.steamCommerceProviderEnabled, isFalse);
    expect(FeatureFlags.steamCommerceTransactionsEnabled, isFalse);
  });
}
