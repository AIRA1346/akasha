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
  });
}
