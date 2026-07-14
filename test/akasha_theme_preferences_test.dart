import 'package:akasha/services/akasha_theme_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy IDs migrate to canonical preferred ID', () async {
    for (final entry in const {
      'classic': 'classicDark',
      'midnight': 'midnightBlue',
      'obsidian': 'amethyst',
    }.entries) {
      SharedPreferences.setMockInitialValues({
        'akasha_library_theme_id': entry.key,
      });
      expect(await AkashaThemePreferences.loadPreferredId(), entry.value);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('akasha_preferred_theme_id'), entry.value);
    }
  });

  test('unknown preferred ID remains stored instead of being erased', () async {
    SharedPreferences.setMockInitialValues({
      'akasha_preferred_theme_id': 'futureTheme',
    });

    expect(await AkashaThemePreferences.loadPreferredId(), 'futureTheme');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('akasha_preferred_theme_id'), 'futureTheme');
  });

  test('unknown legacy ID is copied to the durable preferred key', () async {
    SharedPreferences.setMockInitialValues({
      'akasha_library_theme_id': 'futureLegacyTheme',
    });

    expect(await AkashaThemePreferences.loadPreferredId(), 'futureLegacyTheme');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('akasha_preferred_theme_id'), 'futureLegacyTheme');
  });

  test('save normalizes known legacy alias', () async {
    SharedPreferences.setMockInitialValues({});
    await AkashaThemePreferences.savePreferredId('midnight');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('akasha_preferred_theme_id'), 'midnightBlue');
  });
}
