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
    expect(CommerceCatalog.astraPacks.map((pack) => pack.grantPremiumAmount), [
      500,
      1000,
      2500,
    ]);
    expect(
      CommerceCatalog.astraPacks.every(
        (pack) => CommerceCatalog.isApprovedAstraPack(pack.id),
      ),
      isTrue,
    );
    expect(CommerceCatalog.isApprovedAstraPack('astra_unit'), isFalse);
    expect(CommerceCatalog.launchThemePackages, hasLength(3));
    expect(CommerceCatalog.sakuraThemePackage.payment?.premiumPrice, 500);
    expect(CommerceCatalog.sakuraThemePackage.payment?.earnedPrice, 500);
  });
}
