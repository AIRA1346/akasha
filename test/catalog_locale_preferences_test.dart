import 'package:akasha/config/catalog_locale.dart';
import 'package:akasha/services/catalog_locale_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    CatalogLocaleScope.setCurrent(CatalogLocale.ko);
  });

  test('CatalogLocalePreferences persists display locale', () async {
    SharedPreferences.setMockInitialValues({});
    await CatalogLocalePreferences.save(CatalogLocale.en);
    expect(await CatalogLocalePreferences.loadInitial(), CatalogLocale.en);

    await CatalogLocalePreferences.save(CatalogLocale.ko);
    expect(await CatalogLocalePreferences.loadInitial(), CatalogLocale.ko);
  });

  test('CatalogLocaleScope notifies listeners on change', () {
    var notifyCount = 0;
    void onChanged() => notifyCount++;
    CatalogLocaleScope.setCurrent(CatalogLocale.ko);
    CatalogLocaleScope.localeListenable.addListener(onChanged);

    CatalogLocaleScope.setCurrent(CatalogLocale.en);
    CatalogLocaleScope.setCurrent(CatalogLocale.en);
    CatalogLocaleScope.setCurrent(CatalogLocale.ko);

    expect(notifyCount, 2);
    CatalogLocaleScope.localeListenable.removeListener(onChanged);
  });
}
