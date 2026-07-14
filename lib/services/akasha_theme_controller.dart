import 'package:flutter/widgets.dart';

import '../config/feature_flags.dart';
import '../theme/akasha_theme_registry.dart';
import '../models/theme_catalog.dart';
import '../theme/akasha_theme_preset.dart';
import 'akasha_theme_preferences.dart';

/// App-root theme state.
///
/// The user's preferred ID is persisted. The effective ID is always derived
/// from preset availability and the latest access state, and is never written
/// back as a replacement preference.
class AkashaThemeController extends ChangeNotifier {
  AkashaThemeController._({
    required String preferredThemeId,
    required bool commerceEnabled,
    required bool authorityAvailable,
    required bool isChecking,
    required Set<String> ownedPresetIds,
  }) : _preferredThemeId = preferredThemeId,
       _commerceEnabled = commerceEnabled,
       _authorityAvailable = authorityAvailable,
       _isChecking = isChecking,
       _ownedPresetIds = Set<String>.of(ownedPresetIds) {
    _recompute();
  }

  static Future<AkashaThemeController> load() async {
    return AkashaThemeController._(
      preferredThemeId: await AkashaThemePreferences.loadPreferredId(),
      commerceEnabled: FeatureFlags.steamInAppPurchasesEnabled,
      authorityAvailable: false,
      isChecking: false,
      ownedPresetIds: const {},
    );
  }

  /// Synchronous Classic fallback for widget tests and recovery surfaces.
  factory AkashaThemeController.fallback({
    String preferredThemeId = AkashaThemeRegistry.defaultThemeId,
  }) {
    return AkashaThemeController._(
      preferredThemeId: preferredThemeId,
      commerceEnabled: false,
      authorityAvailable: false,
      isChecking: false,
      ownedPresetIds: const {},
    );
  }

  late ThemeSelection _selection;
  String _preferredThemeId;
  bool _commerceEnabled;
  bool _authorityAvailable;
  bool _isChecking;
  Set<String> _ownedPresetIds;

  String get preferredThemeId => _preferredThemeId;
  String get effectiveThemeId => _selection.effectiveThemeId;
  ThemeAccessState get preferredAccessState => _selection.accessState;
  ThemeSelection get selection => _selection;

  AkashaThemePreset get effectivePreset =>
      AkashaThemeRegistry.presetById(effectiveThemeId) ??
      AkashaThemeRegistry.classicDarkPreset;

  Map<String, ThemeAccessState> get accessByPresetId =>
      Map.unmodifiable(_buildAccessMap());

  /// Selects only a currently usable preset. Locked/unavailable choices are
  /// not persisted, while an already stored premium preference remains intact.
  Future<bool> setPreferredTheme(String presetId) async {
    final canonical = AkashaThemeRegistry.canonicalId(presetId);
    if (canonical == null) {
      return false;
    }
    final access = _buildAccessMap()[canonical];
    if (access == null || !access.grantsAccess) return false;

    await AkashaThemePreferences.savePreferredId(canonical);
    _preferredThemeId = canonical;
    _recompute();
    notifyListeners();
    return true;
  }

  /// Updates provider-derived access without persisting ownership locally.
  void updateAccess({
    required bool commerceEnabled,
    required bool authorityAvailable,
    required bool isChecking,
    required Set<String> ownedPresetIds,
  }) {
    _commerceEnabled = commerceEnabled;
    _authorityAvailable = authorityAvailable;
    _isChecking = isChecking;
    _ownedPresetIds = Set<String>.of(ownedPresetIds);
    _recompute();
    notifyListeners();
  }

  Map<String, ThemeAccessState> _buildAccessMap() {
    return {
      for (final entry in AkashaThemeRegistry.catalogEntries)
        entry.presetId: ThemeAccessResolver.resolve(
          entry: entry,
          authorityAvailable: _commerceEnabled && _authorityAvailable,
          isChecking: _isChecking,
          isOwned: _ownedPresetIds.contains(entry.presetId),
        ),
    };
  }

  void _recompute() {
    _selection = ThemeAccessResolver.select(
      preferredThemeId: _preferredThemeId,
      availablePresetIds: {
        for (final preset in AkashaThemeRegistry.presets) preset.id,
      },
      accessByPresetId: _buildAccessMap(),
      fallbackThemeId: AkashaThemeRegistry.defaultThemeId,
    );
  }
}

class AkashaThemeScope extends InheritedNotifier<AkashaThemeController> {
  const AkashaThemeScope({
    super.key,
    required AkashaThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AkashaThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AkashaThemeScope>();
    assert(scope != null, 'AkashaThemeScope is missing above this context.');
    return scope!.notifier!;
  }
}
