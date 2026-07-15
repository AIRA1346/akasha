import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../services/commerce_controller.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_theme_registry.dart';

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
      final width = (viewport.width - 48).clamp(320.0, 920.0);
      final height = (viewport.height - 48).clamp(440.0, 700.0);
      final l10n = AppLocalizations.of(dialogContext);
      final palette = dialogContext.akashaPalette;
      final effectiveAccount =
          account ??
          CommerceScope.maybeOf(dialogContext)?.snapshot ??
          const CommerceAccountSnapshot.disabled();

      return Dialog(
        key: const ValueKey('commerce-center-dialog'),
        backgroundColor: palette.surfaceElevated,
        insetPadding: const EdgeInsets.all(24),
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
                      _CommerceStoreTab(l10n: l10n),
                      _CommerceInventoryTab(
                        l10n: l10n,
                        account: effectiveAccount,
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
  const _CommerceStoreTab({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final definitions = AkashaThemeRegistry.all
        .where((definition) => definition.catalog.isPremium)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: palette.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.warning.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: palette.warning,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  l10n.commerceStorePreviewNotice,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: definitions.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisExtent: 380,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) =>
                _ThemePackageCard(definition: definitions[index], l10n: l10n),
          ),
        ),
      ],
    );
  }
}

class _ThemePackageCard extends StatelessWidget {
  const _ThemePackageCard({required this.definition, required this.l10n});

  final AkashaThemeDefinition definition;
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
                    _themeName(l10n, definition),
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
                      onPressed: null,
                      icon: const Icon(Icons.schedule_rounded, size: 16),
                      label: Text(l10n.commerceComingSoon),
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
  const _CommerceInventoryTab({required this.l10n, required this.account});

  final AppLocalizations l10n;
  final CommerceAccountSnapshot account;

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
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          l10n.commerceCurrencySection,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CurrencyCard(
                icon: Icons.auto_awesome_rounded,
                label: l10n.commerceAstraLabel,
                value: account.astraBalance,
                unavailableLabel: l10n.commerceBalanceUnavailable,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CurrencyCard(
                icon: Icons.graphic_eq_rounded,
                label: l10n.commerceEchoLabel,
                value: account.echoBalance,
                unavailableLabel: l10n.commerceBalanceUnavailable,
              ),
            ),
          ],
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
