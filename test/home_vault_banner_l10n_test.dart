import 'package:akasha/config/feature_flags.dart';
import 'package:akasha/screens/home/home_vault_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';

void main() {
  testWidgets('HomeVaultBanner shows English copy under en locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeVaultBanner(
            onConnectVault: () {},
            onCreateDefaultVault: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Exploring the catalog. Link a local folder to save records.',
      ),
      findsOneWidget,
    );
    expect(find.text('Link existing folder'), findsOneWidget);
    expect(find.text('Create default archive'), findsOneWidget);
    expect(find.textContaining('카탈로그'), findsNothing);
  });

  test('Steam v1 keeps Timeline off the primary nav contract', () {
    expect(FeatureFlags.showTimeline, isFalse);
  });
}
