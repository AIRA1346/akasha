import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_theme.dart';

/// IAP·제휴 권한 종류 — Steam 수수료 회피를 위해 결제 채널 분리
enum EntitlementKind {
  /// Steam microtxn — 서재 테마·서포터 등 코스메틱만
  cosmetic,
  /// 제휴사 웹결제·OAuth — 작품 구매·스트리밍 권한 (Steam 밖)
  content,
}

/// 등록 상품 메타 (Steamworks / 제휴 SKU 공통)
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

/// Steam IAP / 서재 꾸미기 권한 (v1 스텁 — 출시 전 실결제 배선)
class EntitlementService {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  static const String libraryThemePackId = 'akasha_library_theme_pack';
  static const String supporterPackId = 'akasha_supporter_pack';
  static const _prefsKey = 'akasha_entitlements';
  static const _contentPrefsKey = 'akasha_content_entitlements';

  static const List<CommerceProduct> catalog = [
    CommerceProduct(
      id: libraryThemePackId,
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
  bool ownsContent(String entitlementKey) => _contentOwned.contains(entitlementKey);

  bool canUseTheme(LibraryTheme theme) {
    if (!theme.requiresIap) return true;
    return owns(libraryThemePackId);
  }

  /// Steam microtxn — cosmetic SKU만
  Future<bool> purchaseCosmetic(String productId) async {
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
    // TODO(steam): Steamworks IAP 콜백에서 grantCosmeticEntitlement 호출
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

  /// 제휴사 웹결제·OAuth 콜백 — Steam과 분리 저장
  Future<void> grantContentEntitlement(String entitlementKey) async {
    await load();
    _contentOwned.add(entitlementKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_contentPrefsKey, _contentOwned.toList());
  }

  /// 개발·QA용 — IAP 없이 테마 팩 잠금 해제
  Future<void> devUnlockLibraryThemes() async {
    await grantEntitlement(libraryThemePackId);
  }
}
