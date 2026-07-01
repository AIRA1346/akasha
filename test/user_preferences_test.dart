import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akasha/services/user_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserPreferences.uiScaleListenable.value = UserPreferences.defaultUiScale;
  });

  test('loads default UI scale when preference is absent', () async {
    final scale = await UserPreferences.loadInitialUiScale();

    expect(scale, UserPreferences.defaultUiScale);
    expect(
      UserPreferences.uiScaleListenable.value,
      UserPreferences.defaultUiScale,
    );
  });

  test('persists clamped UI scale', () async {
    await UserPreferences.setUiScale(2);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(UserPreferences.uiScaleKey), 1.25);
    expect(UserPreferences.uiScaleListenable.value, 1.25);

    await UserPreferences.setUiScale(0.5);

    expect(prefs.getDouble(UserPreferences.uiScaleKey), 0.9);
    expect(UserPreferences.uiScaleListenable.value, 0.9);
  });
}
