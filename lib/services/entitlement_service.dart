import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_theme.dart';

/// Steam IAP / 서재 꾸미기 권한 (v1 스텁 — 출시 전 실결제 배선)
class EntitlementService {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  static const String libraryThemePackId = 'akasha_library_theme_pack';
  static const String supporterPackId = 'akasha_supporter_pack';
  static const _prefsKey = 'akasha_entitlements';

  final Set<String> _owned = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    _owned
      ..clear()
      ..addAll(raw);
    _loaded = true;
  }

  bool owns(String productId) => _owned.contains(productId);

  bool canUseTheme(LibraryTheme theme) {
    if (!theme.requiresIap) return true;
    return owns(libraryThemePackId);
  }

  /// Steam microtxn 연동 예정 — 현재는 구매 실패(no-op)
  Future<bool> purchase(String productId) async {
    await load();
    // TODO(steam): Steamworks IAP 콜백에서 grantEntitlement 호출
    return false;
  }

  Future<void> grantEntitlement(String productId) async {
    await load();
    _owned.add(productId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _owned.toList());
  }

  /// 개발·QA용 — IAP 없이 테마 팩 잠금 해제
  Future<void> devUnlockLibraryThemes() async {
    await grantEntitlement(libraryThemePackId);
  }
}
