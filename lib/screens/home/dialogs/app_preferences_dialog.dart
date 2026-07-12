import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/catalog_locale.dart';
import '../../../dev/steam_inventory_poc/steam_inventory_poc.dart';
import '../../../dev/steam_inventory_poc/steam_inventory_poc_dialog.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../services/app_lifecycle.dart';
import '../../../services/catalog_locale_preferences.dart';
import '../../../services/user_preferences.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';

Future<void> showAppPreferencesDialog(
  BuildContext hostContext, {
  VoidCallback? onOpenAppTheme,
  VoidCallback? onOpenVaultSettings,
  VoidCallback? onQuit,
}) {
  return showDialog<void>(
    context: hostContext,
    builder: (dialogContext) {
      var localScale = UserPreferences.uiScaleListenable.value;
      var localLocale = CatalogLocaleScope.current;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          final l10n = AppLocalizations.of(context);
          final percent = (localScale * 100).round();

          Future<void> persistScale(double value) async {
            final scale = UserPreferences.normalizeUiScale(value);
            await UserPreferences.setUiScale(scale);
            if (!context.mounted) return;
            setDialogState(() => localScale = scale);
          }

          void closeThen(VoidCallback? action) {
            Navigator.of(dialogContext).pop();
            if (action == null) return;
            WidgetsBinding.instance.addPostFrameCallback((_) => action());
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.tune, size: 20, color: AkashaColors.accent),
                const SizedBox(width: AkashaSpacing.sm),
                Text(l10n.appPreferencesTitle),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsDisplayLanguage,
                      style: AkashaTypography.settingsLabel,
                    ),
                    const SizedBox(height: AkashaSpacing.sm),
                    InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CatalogLocale>(
                          value: localLocale,
                          isDense: true,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: CatalogLocale.ko,
                              child: Text(l10n.localeKo),
                            ),
                            DropdownMenuItem(
                              value: CatalogLocale.en,
                              child: Text(l10n.localeEn),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            await CatalogLocalePreferences.save(value);
                            CatalogLocaleScope.setCurrent(value);
                            if (!context.mounted) return;
                            setDialogState(() => localLocale = value);
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.appPreferencesDisplayScale,
                            style: AkashaTypography.settingsLabel,
                          ),
                        ),
                        Text('$percent%', style: AkashaTypography.bodyEmphasis),
                      ],
                    ),
                    Slider(
                      value: localScale,
                      min: UserPreferences.minUiScale,
                      max: UserPreferences.maxUiScale,
                      divisions: 7,
                      label: '$percent%',
                      onChanged: (value) {
                        setDialogState(() => localScale = value);
                      },
                      onChangeEnd: persistScale,
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () =>
                              persistScale(UserPreferences.defaultUiScale),
                          child: Text(l10n.appPreferencesResetScale),
                        ),
                        const SizedBox(width: AkashaSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.appPreferencesScaleHelp,
                            style: AkashaTypography.caption,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.palette_outlined),
                      title: Text(l10n.appPreferencesThemeTitle),
                      subtitle: Text(l10n.appPreferencesThemeSubtitle),
                      onTap: onOpenAppTheme == null
                          ? null
                          : () => closeThen(onOpenAppTheme),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_open_outlined),
                      title: Text(l10n.appPreferencesVaultTitle),
                      subtitle: Text(l10n.appPreferencesVaultSubtitle),
                      onTap: onOpenVaultSettings == null
                          ? null
                          : () => closeThen(onOpenVaultSettings),
                    ),
                    if (isSteamInventoryPocEnabled) ...[
                      const Divider(height: 28),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.science_outlined),
                        title: const Text('Steam Inventory POC'),
                        subtitle: const Text(
                          'Internal harness only — IAP flag stays false',
                        ),
                        onTap: () => closeThen(
                          () {
                            if (!hostContext.mounted) return;
                            showSteamInventoryPocDialog(hostContext);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (onQuit != null) {
                    onQuit();
                  } else {
                    unawaited(quitAkashaApp());
                  }
                },
                icon: const Icon(Icons.power_settings_new),
                label: Text(l10n.appPreferencesQuit),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.appPreferencesClose),
              ),
            ],
          );
        },
      );
    },
  );
}
