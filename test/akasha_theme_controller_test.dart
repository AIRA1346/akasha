import 'package:akasha/models/theme_catalog.dart';
import 'package:akasha/services/akasha_theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('load migrates legacy preference before the first frame', () async {
    SharedPreferences.setMockInitialValues({
      'akasha_library_theme_id': 'midnight',
    });
    final controller = await AkashaThemeController.load();
    addTearDown(controller.dispose);

    expect(controller.preferredThemeId, 'midnightBlue');
    expect(controller.effectiveThemeId, 'midnightBlue');
  });

  test('bundled preferred theme is effective without authority', () {
    final controller = AkashaThemeController.fallback(
      preferredThemeId: 'midnightBlue',
    );
    addTearDown(controller.dispose);

    expect(controller.preferredThemeId, 'midnightBlue');
    expect(controller.effectiveThemeId, 'midnightBlue');
    expect(controller.preferredAccessState, ThemeAccessState.free);
  });

  test('premium preference survives unavailable fallback', () {
    final controller = AkashaThemeController.fallback(
      preferredThemeId: 'sakura',
    );
    addTearDown(controller.dispose);

    expect(controller.preferredThemeId, 'sakura');
    expect(controller.effectiveThemeId, 'classicDark');
    expect(controller.preferredAccessState, ThemeAccessState.unavailable);
  });

  test('authority ownership reapplies preserved premium preference', () {
    final controller = AkashaThemeController.fallback(
      preferredThemeId: 'sakura',
    );
    addTearDown(controller.dispose);

    controller.updateAccess(
      commerceEnabled: true,
      authorityAvailable: true,
      isChecking: false,
      ownedPresetIds: const {'sakura'},
    );

    expect(controller.preferredThemeId, 'sakura');
    expect(controller.effectiveThemeId, 'sakura');
    expect(controller.preferredAccessState, ThemeAccessState.owned);
  });

  test('locked choice is not persisted', () async {
    final controller = AkashaThemeController.fallback();
    addTearDown(controller.dispose);

    expect(await controller.setPreferredTheme('sakura'), isFalse);
    expect(controller.preferredThemeId, 'classicDark');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('akasha_preferred_theme_id'), isNull);
  });

  test('bundled selection is persisted as canonical preferred ID', () async {
    final controller = AkashaThemeController.fallback();
    addTearDown(controller.dispose);

    expect(await controller.setPreferredTheme('midnight'), isTrue);
    expect(controller.preferredThemeId, 'midnightBlue');
    expect(controller.effectiveThemeId, 'midnightBlue');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('akasha_preferred_theme_id'), 'midnightBlue');
  });
}
