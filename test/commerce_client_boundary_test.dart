import 'package:akasha/core/commerce/commerce.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CommerceApiClient stays unwired; flag path unchanged', () {
    const client = UnwiredCommerceApiClient();
    expect(
      () => client.getWallet(authTicketHex: 'x'),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('Flutter commerce barrel exports shared domain only + client', () {
    expect(
      CurrencyDisplay.name(CurrencyKind.premium, languageTag: 'en'),
      'Astra',
    );
    expect(CommerceCatalog.premiumPack100.grantPremiumAmount, 100);
    expect(CommerceCatalog.launchThemePackages, hasLength(3));
    expect(CommerceCatalog.sakuraThemePackage.payment?.premiumPrice, 500);
    expect(CommerceCatalog.sakuraThemePackage.payment?.earnedPrice, 500);
  });
}
