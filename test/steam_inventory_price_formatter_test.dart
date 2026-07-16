import 'package:akasha/core/commerce/steam_inventory/steam_inventory_price_formatter.dart';
import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats Steam hundredths in the current locale', () {
    const price = CommerceLocalizedPrice(
      productId: 'astra_pack_500',
      currencyCode: 'KRW',
      currentAmount: 550000,
    );

    expect(formatSteamInventoryPrice(price, locale: 'ko'), '5,500 KRW');
  });

  test('retains a non-zero local-currency fraction', () {
    const price = CommerceLocalizedPrice(
      productId: 'astra_pack_500',
      currencyCode: 'USD',
      currentAmount: 499,
    );

    expect(formatSteamInventoryPrice(price, locale: 'en'), '4.99 USD');
  });
}
