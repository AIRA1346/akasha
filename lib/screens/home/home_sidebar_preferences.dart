import 'package:shared_preferences/shared_preferences.dart';

/// 사이드바 열림/닫힘 상태 영속화
class HomeSidebarPreferences {
  static const _prefKey = 'akasha_sidebar_open';

  static Future<bool> loadOpen({bool defaultOpen = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? defaultOpen;
    } catch (_) {
      return defaultOpen;
    }
  }

  static Future<void> saveOpen(bool open) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, open);
    } catch (_) {}
  }
}
