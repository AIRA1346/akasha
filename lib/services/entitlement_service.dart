import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';

/// Post-launch 권한 종류.
/// Steam IAP는 [FeatureFlags.steamInAppPurchasesEnabled]가 true일 때만 실연동한다.
enum EntitlementKind {
  /// 향후 Steam microtxn 후보 — 테마·서포터 등 코스메틱만.
  cosmetic,

  /// 향후 외부 콘텐츠 권한 후보.
  content,
}

/// 등록 상품 메타. 현재는 post-launch 실험용 스텁으로만 유지한다.
class CommerceProduct {
  final String id;
  final EntitlementKind kind;
  final String label;

  const CommerceProduct({
    required this.id,
    required this.kind,
    required this.label,
  });
}

/// 유료 권한 스텁. v1 무료 출시에서는 테마 잠금이나 구매 UI에 연결하지 않는다.
class EntitlementService {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  static const String themePackProductId = 'akasha_library_theme_pack';
  static const String supporterPackId = 'akasha_supporter_pack';
  static const _prefsKey = 'akasha_entitlements';
  static const _contentPrefsKey = 'akasha_content_entitlements';

  static const List<CommerceProduct> catalog = [
    CommerceProduct(
      id: themePackProductId,
      kind: EntitlementKind.cosmetic,
      label: '나의 서재 테마 팩',
    ),
    CommerceProduct(
      id: supporterPackId,
      kind: EntitlementKind.cosmetic,
      label: '서포터 팩',
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

  /// 제휴 콘텐츠 SKU (partnerId:sku 또는 workId 기반)
  bool ownsContent(String entitlementKey) =>
      _contentOwned.contains(entitlementKey);

  /// Cosmetic purchase entry. Returns false while IAP is unimplemented.
  Future<bool> purchaseCosmetic(String productId) async {
    if (!FeatureFlags.steamInAppPurchasesEnabled) {
      return false;
    }
    await load();
    CommerceProduct? product;
    for (final entry in catalog) {
      if (entry.id == productId) {
        product = entry;
        break;
      }
    }
    if (product == null || product.kind != EntitlementKind.cosmetic) {
      return false;
    }
    // TODO(steam): Steam Wallet confirm → grant → ledger (Blocker P5).
    return false;
  }

  Future<void> grantCosmeticEntitlement(String productId) async {
    await load();
    _owned.add(productId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _owned.toList());
  }

  Future<void> grantEntitlement(String productId) =>
      grantCosmeticEntitlement(productId);

  /// Post-launch external content entitlement placeholder.
  Future<void> grantContentEntitlement(String entitlementKey) async {
    await load();
    _contentOwned.add(entitlementKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_contentPrefsKey, _contentOwned.toList());
  }
}
