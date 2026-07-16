import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/commerce/steam_inventory/steam_inventory_price_formatter.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/commerce_controller.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_theme_registry.dart';
import 'commerce_transaction_dialogs.dart';

/// Read-only commerce discovery surface while production Steam transactions
/// remain disabled. A real [CommerceAccountSnapshot] can be injected later
/// without changing the store or inventory geometry.
Future<void> showCommerceCenterDialog(
  BuildContext context, {
  CommerceAccountSnapshot? account,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final viewport = MediaQuery.sizeOf(dialogContext);
      final inset = viewport.width < 600 ? 12.0 : 24.0;
      final width = (viewport.width - (inset * 2)).clamp(280.0, 920.0);
      final height = (viewport.height - (inset * 2)).clamp(400.0, 700.0);
      final l10n = AppLocalizations.of(dialogContext);
      final palette = dialogContext.akashaPalette;
      final controller = account == null
          ? CommerceScope.maybeOf(dialogContext)
          : null;
      final effectiveAccount =
          account ??
          controller?.snapshot ??
          const CommerceAccountSnapshot.disabled();

      return Dialog(
        key: const ValueKey('commerce-center-dialog'),
        backgroundColor: palette.surfaceElevated,
        insetPadding: EdgeInsets.all(inset),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          height: height,
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.commerceCenterTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.commerceCenterSubtitle,
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.appPreferencesClose,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.storefront_outlined),
                      text: l10n.commerceStoreTab,
                    ),
                    Tab(
                      icon: const Icon(Icons.inventory_2_outlined),
                      text: l10n.commerceInventoryTab,
                    ),
                  ],
                ),
                Divider(height: 1, color: palette.borderSubtle(0.55)),
                Expanded(
                  child: TabBarView(
                    children: [
                      _CommerceStoreTab(
                        l10n: l10n,
                        account: effectiveAccount,
                        controller: controller,
                      ),
                      _CommerceInventoryTab(
                        l10n: l10n,
                        account: effectiveAccount,
                        controller: controller,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CommerceStoreTab extends StatelessWidget {
  const _CommerceStoreTab({
    required this.l10n,
    required this.account,
    required this.controller,
  });

  final AppLocalizations l10n;
  final CommerceAccountSnapshot account;
  final CommerceController? controller;

  @override
  Widget build(BuildContext context) {
    final definitions = AkashaThemeRegistry.all
        .where((definition) => definition.catalog.isPremium)
        .toList(growable: false);

    return CustomScrollView(
      key: const PageStorageKey('commerce-store-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: _CommerceAuthorityBanner(
            l10n: l10n,
            account: account,
            controller: controller,
          ),
        ),
        SliverToBoxAdapter(
          child: _CommerceSectionHeader(
            title: l10n.commerceAstraPackSection,
            body: l10n.commerceAstraPackSectionBody,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverGrid.builder(
            itemCount: CommerceCatalog.astraPacks.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 184,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) => _AstraPackCard(
              product: CommerceCatalog.astraPacks[index],
              account: account,
              controller: controller,
              l10n: l10n,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _CommerceSectionHeader(
            title: l10n.commerceThemePackageSection,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          sliver: SliverGrid.builder(
            itemCount: definitions.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisExtent: 380,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) => _ThemePackageCard(
              definition: definitions[index],
              account: account,
              controller: controller,
              l10n: l10n,
            ),
          ),
        ),
      ],
    );
  }
}

class _CommerceSectionHeader extends StatelessWidget {
  const _CommerceSectionHeader({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (body case final body?) ...[
            const SizedBox(height: 3),
            Text(
              body,
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _AstraPackCard extends StatelessWidget {
  const _AstraPackCard({
    required this.product,
    required this.account,
    required this.controller,
    required this.l10n,
  });

  final CommerceProduct product;
  final CommerceAccountSnapshot account;
  final CommerceController? controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final price = account.priceOf(product.id);
    final amount = product.grantPremiumAmount ?? 0;
    final priceLabel = price == null
        ? l10n.commerceSteamPricePending
        : l10n.commerceSteamPriceReady(
            formatSteamInventoryPrice(
              price,
              locale: Localizations.localeOf(context).toLanguageTag(),
            ),
          );
    final operationForProduct =
        controller?.operationInFlight == true &&
        controller?.activeProductId == product.id;
    final canBuy =
        controller != null &&
        account.canTransact &&
        price != null &&
        controller?.operationInFlight != true;
    final productName = _productName(context, product);

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.borderSubtle(0.62)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: palette.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.commerceAstraPackGrant(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              priceLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.textMuted, fontSize: 10),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: ValueKey('commerce-buy-${product.id}'),
                onPressed: canBuy
                    ? () => confirmAstraPackPurchase(
                        context,
                        controller: controller!,
                        product: product,
                        productName: productName,
                        priceLabel: priceLabel,
                      )
                    : null,
                icon: operationForProduct
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        canBuy
                            ? Icons.shopping_bag_outlined
                            : Icons.schedule_rounded,
                        size: 16,
                      ),
                label: Text(
                  operationForProduct
                      ? l10n.commerceOperationInProgress
                      : canBuy
                      ? l10n.commerceBuyOnSteam
                      : l10n.commerceComingSoon,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePackageCard extends StatelessWidget {
  const _ThemePackageCard({
    required this.definition,
    required this.account,
    required this.controller,
    required this.l10n,
  });

  final AkashaThemeDefinition definition;
  final CommerceAccountSnapshot account;
  final CommerceController? controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final catalog = definition.catalog;
    final product = catalog.entitlementKey == null
        ? null
        : CommerceCatalog.byEntitlementKey(catalog.entitlementKey!);
    final payment = product?.payment;
    final astra = payment?.premiumPrice ?? catalog.astraCost;
    final echo = payment?.earnedPrice ?? catalog.echoCost;
    final owned =
        catalog.entitlementKey != null && account.owns(catalog.entitlementKey!);
    final operationForProduct =
        product != null &&
        controller?.operationInFlight == true &&
        controller?.activeProductId == product.id;
    final canExchange =
        product != null &&
        controller != null &&
        account.canTransact &&
        !owned &&
        controller?.operationInFlight != true;
    final themeName = _themeName(l10n, definition);

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.borderSubtle(0.62)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: Image.asset(
              definition.preset.assets.heroAssetPath ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: definition.preset.backgroundColor,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: definition.preset.accentColor,
                  size: 34,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    themeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.commerceThemePackageLabel,
                    style: TextStyle(color: palette.accent, fontSize: 11),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    l10n.commerceThemePackageContents,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
                  const Spacer(),
                  if (astra != null && echo != null)
                    Text(
                      l10n.themePriceChooseOne(astra, echo),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: product == null
                          ? null
                          : ValueKey('commerce-exchange-${product.id}'),
                      onPressed: canExchange
                          ? () => chooseThemeExchangeCurrency(
                              context,
                              controller: controller!,
                              product: product,
                              productName: themeName,
                              account: account,
                            )
                          : null,
                      icon: operationForProduct
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              owned
                                  ? Icons.check_circle_outline_rounded
                                  : canExchange
                                  ? Icons.payments_outlined
                                  : Icons.schedule_rounded,
                              size: 16,
                            ),
                      label: Text(
                        owned
                            ? l10n.commerceOwned
                            : operationForProduct
                            ? l10n.commerceOperationInProgress
                            : canExchange
                            ? l10n.commerceChooseCurrency
                            : l10n.commerceComingSoon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommerceInventoryTab extends StatelessWidget {
  const _CommerceInventoryTab({
    required this.l10n,
    required this.account,
    required this.controller,
  });

  final AppLocalizations l10n;
  final CommerceAccountSnapshot account;
  final CommerceController? controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final ownedThemes = AkashaThemeRegistry.all
        .where((definition) {
          if (definition.catalog.isBundled) return true;
          final key = definition.catalog.entitlementKey;
          return key != null && account.owns(key);
        })
        .toList(growable: false);

    return ListView(
      key: const PageStorageKey('commerce-inventory-scroll'),
      padding: const EdgeInsets.all(18),
      children: [
        _CommerceAuthorityBanner(
          l10n: l10n,
          account: account,
          controller: controller,
          margin: EdgeInsets.zero,
        ),
        const SizedBox(height: 18),
        Text(
          l10n.commerceCurrencySection,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final astra = _CurrencyCard(
              icon: Icons.auto_awesome_rounded,
              label: l10n.commerceAstraLabel,
              value: account.astraBalance,
              unavailableLabel: l10n.commerceBalanceUnavailable,
            );
            final echo = _CurrencyCard(
              icon: Icons.graphic_eq_rounded,
              label: l10n.commerceEchoLabel,
              value: account.echoBalance,
              unavailableLabel: l10n.commerceBalanceUnavailable,
            );
            if (constraints.maxWidth < 480) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [astra, const SizedBox(height: 10), echo],
              );
            }
            return Row(
              children: [
                Expanded(child: astra),
                const SizedBox(width: 12),
                Expanded(child: echo),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.borderSubtle(0.55)),
          ),
          child: Text(
            l10n.commerceAuthorityNotice,
            style: TextStyle(color: palette.textMuted, fontSize: 11),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.commerceOwnedThemeSection,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ownedThemes.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            mainAxisExtent: 76,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final definition = ownedThemes[index];
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.borderSubtle(0.55)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: definition.preset.accentColor.withValues(
                      alpha: 0.16,
                    ),
                    foregroundColor: definition.preset.accentColor,
                    child: const Icon(Icons.palette_outlined, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _themeName(l10n, definition),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          definition.catalog.isBundled
                              ? l10n.commerceIncluded
                              : l10n.commerceOwned,
                          style: TextStyle(
                            color: definition.preset.accentColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (account.state != CommerceAuthorityState.ready &&
            account.state != CommerceAuthorityState.offlineCache) ...[
          const SizedBox(height: 12),
          Text(
            l10n.commerceOwnershipUnavailable,
            style: TextStyle(color: palette.textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _CommerceAuthorityBanner extends StatelessWidget {
  const _CommerceAuthorityBanner({
    required this.l10n,
    required this.account,
    required this.controller,
    this.margin = const EdgeInsets.fromLTRB(16, 16, 16, 0),
  });

  final AppLocalizations l10n;
  final CommerceAccountSnapshot account;
  final CommerceController? controller;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final readyIssueMessage = switch (account.issueCode) {
      'steam_overlay_unavailable' => l10n.commerceAccountOverlayUnavailable,
      'steam_app_subscription_missing' =>
        l10n.commerceAccountSubscriptionMissing,
      'steam_purchase_prices_incomplete' =>
        l10n.commerceAccountPricesIncomplete,
      _ => l10n.commerceAccountReadyReadOnly,
    };
    final (
      icon,
      color,
      message,
      showProgress,
      canRetry,
    ) = switch (account.state) {
      CommerceAuthorityState.disabled => (
        Icons.info_outline_rounded,
        palette.warning,
        l10n.commerceStorePreviewNotice,
        false,
        false,
      ),
      CommerceAuthorityState.loading => (
        Icons.sync_rounded,
        palette.info,
        l10n.commerceAccountLoading,
        true,
        false,
      ),
      CommerceAuthorityState.ready => (
        account.transactionsEnabled
            ? Icons.verified_outlined
            : Icons.warning_amber_rounded,
        account.transactionsEnabled ? palette.success : palette.warning,
        account.transactionsEnabled
            ? l10n.commerceAccountReadyTransactions
            : readyIssueMessage,
        false,
        !account.transactionsEnabled &&
            account.issueCode != null &&
            controller?.enabled == true,
      ),
      CommerceAuthorityState.offlineCache => (
        Icons.cloud_off_outlined,
        palette.warning,
        l10n.commerceAccountOfflineCache,
        false,
        controller?.enabled == true,
      ),
      CommerceAuthorityState.unavailable => (
        Icons.error_outline_rounded,
        palette.danger,
        l10n.commerceAccountUnavailable,
        false,
        controller?.enabled == true,
      ),
    };
    final supportReport = controller?.buildSupportReport();

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        key: ValueKey('commerce-authority-${account.state.name}'),
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(message, style: const TextStyle(fontSize: 12)),
                ),
                if (canRetry) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    key: const ValueKey('commerce-retry-button'),
                    onPressed: controller?.refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(l10n.commerceRetry),
                  ),
                ],
                if (supportReport != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    key: const ValueKey('commerce-copy-diagnostics'),
                    tooltip: l10n.commerceCopyDiagnostics,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: supportReport),
                      );
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      messenger
                        ?..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(l10n.commerceDiagnosticsCopied),
                          ),
                        );
                    },
                    icon: const Icon(Icons.content_copy_rounded, size: 17),
                  ),
                ],
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 9),
              LinearProgressIndicator(
                minHeight: 2,
                color: color,
                backgroundColor: color.withValues(alpha: 0.14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  const _CurrencyCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unavailableLabel,
  });

  final IconData icon;
  final String label;
  final int? value;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle(0.55)),
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  value?.toString() ?? '—',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (value == null)
                  Text(
                    unavailableLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.textMuted, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _themeName(AppLocalizations l10n, AkashaThemeDefinition definition) {
  final catalog = definition.catalog;
  return switch (catalog.displayNameL10nKey) {
    'themeClassicDarkName' => l10n.themeClassicDarkName,
    'themeMidnightBlueName' => l10n.themeMidnightBlueName,
    'themeSakuraName' => l10n.themeSakuraName,
    'themeAmethystName' => l10n.themeAmethystName,
    'themeNocturneName' => l10n.themeNocturneName,
    _ => catalog.fallbackDisplayName,
  };
}

String _productName(BuildContext context, CommerceProduct product) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ko') {
    return product.displayNameKo ?? product.displayNameEn ?? '';
  }
  return product.displayNameEn ?? product.displayNameKo ?? '';
}
