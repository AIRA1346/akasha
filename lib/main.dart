import 'package:flutter/material.dart';

import 'config/catalog_locale.dart';
import 'generated/l10n/app_localizations.dart';
import 'data/adapters/markdown_vault_adapter.dart';
import 'data/adapters/works_registry_adapter.dart';
import 'screens/home/home_shell.dart';
import 'services/catalog_locale_preferences.dart';
import 'services/akasha_command_runner.dart';
import 'services/akasha_theme_controller.dart';
import 'services/akasha_window_controller.dart';
import 'services/franchise_registry.dart';
import 'services/local_derived_index_lifecycle.dart';
import 'services/user_preferences.dart';
import 'theme/akasha_theme.dart';
import 'widgets/akasha_theme_backdrop.dart';
import 'widgets/akasha_window_frame.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 확장형 올인원 아카이브 앱
//  앱 진입점 & 테마 설정
// ════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  CatalogLocaleScope.setCurrent(await CatalogLocalePreferences.loadInitial());
  await UserPreferences.loadInitialUiScale();

  // 어댑터를 통한 글로벌 사전 및 볼트 초기화
  await WorksRegistryAdapter().init();
  await MarkdownVaultAdapter().init();
  await LocalDerivedIndexLifecycle.app.start();
  await FranchiseRegistry.init();
  // cold start: manifest + eager 샤드만 (browse는 search_index 윈도우 lazy load)

  final windowController = await initializeAkashaDesktopWindow();
  final themeController = await AkashaThemeController.load();
  runApp(
    AkashaApp(
      themeController: themeController,
      windowController: windowController,
    ),
  );
}

/// Invoked only by the Windows runner for the command vocabulary it recognizes.
/// It must remain free of UI initialization so a local agent command cannot
/// accidentally launch normal AKASHA application behavior.
@pragma('vm:entry-point')
Future<void> commandMain(List<String> args) =>
    AkashaCommandRunner().runFromProcess(args);

class AkashaApp extends StatefulWidget {
  const AkashaApp({
    super.key,
    this.themeController,
    this.windowController,
    this.home,
  });

  final AkashaThemeController? themeController;
  final AkashaWindowController? windowController;
  final Widget? home;

  @override
  State<AkashaApp> createState() => _AkashaAppState();
}

class _AkashaAppState extends State<AkashaApp> {
  late AkashaThemeController _themeController;
  late bool _ownsThemeController;

  @override
  void initState() {
    super.initState();
    _installThemeController(widget.themeController);
    CatalogLocaleScope.localeListenable.addListener(_onLocaleChanged);
    UserPreferences.uiScaleListenable.addListener(_onUiScaleChanged);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    if (_ownsThemeController) _themeController.dispose();
    CatalogLocaleScope.localeListenable.removeListener(_onLocaleChanged);
    UserPreferences.uiScaleListenable.removeListener(_onUiScaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});
  void _onUiScaleChanged() => setState(() {});
  void _onThemeChanged() => setState(() {});

  void _installThemeController(AkashaThemeController? controller) {
    _themeController = controller ?? AkashaThemeController.fallback();
    _ownsThemeController = controller == null;
    _themeController.addListener(_onThemeChanged);
  }

  @override
  void didUpdateWidget(covariant AkashaApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeController == widget.themeController) return;
    _themeController.removeListener(_onThemeChanged);
    if (_ownsThemeController) _themeController.dispose();
    _installThemeController(widget.themeController);
  }

  Locale get _appLocale => Locale(CatalogLocaleScope.current.tag);

  @override
  Widget build(BuildContext context) {
    final effectivePreset = _themeController.effectivePreset;
    return MaterialApp(
      title: 'AKASHA',
      debugShowCheckedModeBanner: false,
      locale: _appLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AkashaTheme.forPreset(effectivePreset),
      themeAnimationDuration:
          effectivePreset.effects.motion.themeTransitionDuration,
      themeAnimationCurve: effectivePreset.effects.motion.standardCurve,
      builder: (context, child) {
        Widget content = AkashaThemeBackdrop(
          preset: effectivePreset,
          child: child ?? const SizedBox.shrink(),
        );
        if (widget.windowController case final windowController?) {
          content = AkashaWindowFrame(
            controller: windowController,
            child: content,
          );
        }
        final mediaQuery = MediaQuery.maybeOf(context);
        if (mediaQuery != null) {
          content = MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(
                UserPreferences.uiScaleListenable.value,
              ),
            ),
            child: content,
          );
        }
        return AkashaThemeScope(controller: _themeController, child: content);
      },
      home: widget.home ?? const HomeShell(),
    );
  }
}
