import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';
import 'package:intl/intl.dart';

/// Formats the raw local-currency price returned by Steam Inventory.
///
/// Steam reports inventory prices in hundredths of the account's local
/// currency (for example, Korean jeon or US cents). The Steam overlay remains
/// the checkout authority, but this keeps the in-app quote readable without
/// deriving a price from AKASHA's own economy settings.
String formatSteamInventoryPrice(
  CommerceLocalizedPrice price, {
  required String locale,
}) {
  final currencyCode = price.currencyCode.trim().toUpperCase();
  final amount = price.currentAmount / 100;
  final fractionDigits = price.currentAmount % 100 == 0 ? 0 : 2;
  final numberFormat = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = fractionDigits
    ..maximumFractionDigits = fractionDigits;
  return '${numberFormat.format(amount)} $currencyCode';
}
