import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../services/commerce_controller.dart';

Future<CommerceOperationResult?> confirmAstraPackPurchase(
  BuildContext context, {
  required CommerceController controller,
  required CommerceProduct product,
  required String productName,
  required String priceLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('commerce-purchase-confirmation'),
      title: Text(l10n.commercePurchaseConfirmTitle(productName)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(priceLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(l10n.commercePurchaseConfirmBody),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commerceCancel),
        ),
        FilledButton.icon(
          key: const ValueKey('commerce-confirm-purchase'),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.open_in_new_rounded, size: 17),
          label: Text(l10n.commerceContinue),
        ),
      ],
    ),
  );
  if (accepted != true || !context.mounted) return null;

  final result = await controller.purchaseAstraPack(product.id);
  if (context.mounted) {
    _showOperationFeedback(context, result, isPurchase: true);
  }
  return result;
}

Future<CommerceOperationResult?> chooseThemeExchangeCurrency(
  BuildContext context, {
  required CommerceController controller,
  required CommerceProduct product,
  required String productName,
  required CommerceAccountSnapshot account,
}) async {
  final l10n = AppLocalizations.of(context);
  final payment = product.payment;
  if (payment == null) return null;

  final currency = await showDialog<CurrencyKind>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('commerce-currency-choice'),
      title: Text(l10n.commerceExchangeConfirmTitle(productName)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.commerceChooseCurrencyBody),
            const SizedBox(height: 16),
            _CurrencyChoiceButton(
              key: const ValueKey('commerce-pay-astra'),
              icon: Icons.auto_awesome_rounded,
              currency: CurrencyKind.premium,
              currencyLabel: l10n.commerceAstraLabel,
              cost: payment.premiumPrice,
              balance: account.astraBalance,
            ),
            const SizedBox(height: 10),
            _CurrencyChoiceButton(
              key: const ValueKey('commerce-pay-echo'),
              icon: Icons.graphic_eq_rounded,
              currency: CurrencyKind.earned,
              currencyLabel: l10n.commerceEchoLabel,
              cost: payment.earnedPrice,
              balance: account.echoBalance,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commerceCancel),
        ),
      ],
    ),
  );
  if (currency == null || !context.mounted) return null;

  final result = await controller.exchangeTheme(
    productId: product.id,
    payWith: currency,
  );
  if (context.mounted) {
    _showOperationFeedback(context, result, isPurchase: false);
  }
  return result;
}

class _CurrencyChoiceButton extends StatelessWidget {
  const _CurrencyChoiceButton({
    super.key,
    required this.icon,
    required this.currency,
    required this.currencyLabel,
    required this.cost,
    required this.balance,
  });

  final IconData icon;
  final CurrencyKind currency;
  final String currencyLabel;
  final int? cost;
  final int? balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final knownCost = cost;
    final knownBalance = balance;
    final canAfford =
        knownCost != null &&
        knownBalance != null &&
        knownCost > 0 &&
        knownBalance >= knownCost;
    final detail = knownCost == null || knownBalance == null
        ? l10n.commerceBalanceUnavailable
        : l10n.commerceCurrencyOption(currencyLabel, knownCost, knownBalance);

    return OutlinedButton(
      onPressed: canAfford ? () => Navigator.of(context).pop(currency) : null,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(detail)),
          if (!canAfford && knownBalance != null)
            Text(
              l10n.commerceInsufficientCurrency,
              style: const TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }
}

void _showOperationFeedback(
  BuildContext context,
  CommerceOperationResult result, {
  required bool isPurchase,
}) {
  final l10n = AppLocalizations.of(context);
  final message = switch (result.status) {
    CommerceOperationStatus.confirmed =>
      isPurchase
          ? l10n.commerceResultPurchaseConfirmed
          : l10n.commerceResultExchangeConfirmed,
    CommerceOperationStatus.noChange => l10n.commerceResultNoChange,
    CommerceOperationStatus.cancelled => l10n.commerceResultCancelled,
    CommerceOperationStatus.rejected => l10n.commerceResultRejected,
    CommerceOperationStatus.failed => l10n.commerceResultFailed,
    CommerceOperationStatus.indeterminate => l10n.commerceResultIndeterminate,
  };
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: ValueKey('commerce-result-${result.status.name}'),
        content: Text(message),
      ),
    );
}
