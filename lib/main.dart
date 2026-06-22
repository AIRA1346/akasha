import 'package:flutter/material.dart';

import 'config/catalog_locale.dart';
import 'generated/l10n/app_localizations.dart';
import 'data/adapters/markdown_vault_adapter.dart';
import 'data/adapters/works_registry_adapter.dart';
import 'screens/home/home_shell.dart';
import 'services/catalog_locale_preferences.dart';
import 'services/franchise_registry.dart';
import 'theme/akasha_theme.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 확장형 올인원 아카이브 앱
//  앱 진입점 & 테마 설정
// ════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  CatalogLocaleScope.setCurrent(await CatalogLocalePreferences.loadInitial());

  // 어댑터를 통한 글로벌 사전 및 볼트 초기화
  await WorksRegistryAdapter().init();
  await MarkdownVaultAdapter().init();
  await FranchiseRegistry.init();
  // cold start: manifest + eager 샤드만 (browse는 search_index 윈도우 lazy load)

  runApp(const AkashaApp());
}

class AkashaApp extends StatefulWidget {
  const AkashaApp({super.key});

  @override
  State<AkashaApp> createState() => _AkashaAppState();
}

class _AkashaAppState extends State<AkashaApp> {
  @override
  void initState() {
    super.initState();
    CatalogLocaleScope.localeListenable.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    CatalogLocaleScope.localeListenable.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  Locale get _appLocale => Locale(CatalogLocaleScope.current.tag);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AKASHA',
      debugShowCheckedModeBanner: false,
      locale: _appLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AkashaTheme.dark(),
      home: const HomeShell(),
    );
  }
}
