import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';

/// Legacy local entitlement categories. These are not Steam ownership.
enum LegacyEntitlementKind {
  /// Historical cosmetic test grants only.
  cosmetic,

  /// Historical external-content placeholder grants.
  content,
}

/// Legacy local test product. Do not confuse this with the production
/// `akasha_commerce_domain` catalog.
class LegacyEntitlementProduct {
  const LegacyEntitlementProduct({
    required this.id,
    required this.kind,
    required this.label,
  });

  final String id;
  final LegacyEntitlementKind kind;
  final String label;
}

/// SharedPreferences-backed compatibility stub.
///
/// It must never back Astra, Echo, paid theme ownership, Store, or Inventory.
/// Production commerce reads Steam through `CommerceGateway` instead.
class EntitlementService {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  static const String themePackProductId = 'akasha_library_theme_pack';
  static const String supporterPackId = 'akasha_supporter_pack';
  static const _prefsKey = 'akasha_entitlements';
  static const _contentPrefsKey = 'akasha_content_entitlements';

  static const List<LegacyEntitlementProduct> catalog = [
    LegacyEntitlementProduct(
      id: themePackProductId,
      kind: LegacyEntitlementKind.cosmetic,
      label: 'Legacy theme test pack',
    ),
    LegacyEntitlementProduct(
      id: supporterPackId,
      kind: LegacyEntitlementKind.cosmetic,
      label: 'Legacy supporter test pack',
    ),
  ];

  final Set<String> _owned = {};
  final Set<String> _contentOwned = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    final contentRaw = prefs.getStringList(_contentPrefsKey) ?? const [];
    _owned
      ..clear()
      ..addAll(raw);
    _contentOwned
      ..clear()
      ..addAll(contentRaw);
    _loaded = true;
  }

  bool owns(String productId) => _owned.contains(productId);

  bool ownsContent(String entitlementKey) =>
      _contentOwned.contains(entitlementKey);

  /// Compatibility entry point. It never performs a production purchase.
  Future<bool> purchaseCosmetic(String productId) async {
    if (!FeatureFlags.steamInAppPurchasesEnabled) return false;

    await load();
    LegacyEntitlementProduct? product;
    for (final entry in catalog) {
      if (entry.id == productId) {
        product = entry;
        break;
      }
    }
    if (product == null || product.kind != LegacyEntitlementKind.cosmetic) {
      return false;
    }

    // Production purchase is intentionally not routed through this stub.
    return false;
  }

  /// Test/migration helper only. Never call after a paid Steam transaction.
  Future<void> grantCosmeticEntitlement(String productId) async {
    await load();
    _owned.add(productId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _owned.toList());
  }

  Future<void> grantEntitlement(String productId) =>
      grantCosmeticEntitlement(productId);

  /// Legacy external-content entitlement placeholder.
  Future<void> grantContentEntitlement(String entitlementKey) async {
    await load();
    _contentOwned.add(entitlementKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_contentPrefsKey, _contentOwned.toList());
  }
}
