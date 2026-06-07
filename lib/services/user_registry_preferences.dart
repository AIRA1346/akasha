import 'package:shared_preferences/shared_preferences.dart';
import 'franchise_registry.dart';
import 'works_registry.dart';

/// 사전(Registry) 표시 관련 사용자 설정 — 숨김·다중 매체 추적
class UserRegistryPreferences {
  static const String hiddenWorkIdsKey = 'akasha_hidden_registry_ids';
  static const String multiFormatFranchisesKey =
      'akasha_multi_format_franchises';

  static final UserRegistryPreferences instance =
      UserRegistryPreferences._internal();
  UserRegistryPreferences._internal();

  final Set<String> _hiddenWorkIds = {};
  final Set<String> _multiFormatFranchiseIds = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  Set<String> get hiddenWorkIds => Set.unmodifiable(_hiddenWorkIds);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hiddenWorkIds
      ..clear()
      ..addAll(prefs.getStringList(hiddenWorkIdsKey) ?? const []);
    _multiFormatFranchiseIds
      ..clear()
      ..addAll(prefs.getStringList(multiFormatFranchisesKey) ?? const []);
    _loaded = true;
  }

  bool isHidden(String workId) {
    if (workId.isEmpty) return false;
    final resolved = WorksRegistry.resolveWorkId(workId);
    return _hiddenWorkIds.contains(workId) ||
        (resolved.isNotEmpty && _hiddenWorkIds.contains(resolved));
  }

  bool tracksMultipleFormats(String franchiseId) {
    return _multiFormatFranchiseIds.contains(franchiseId);
  }

  Future<void> hideWork(String workId) async {
    if (workId.isEmpty) return;
    final resolved = WorksRegistry.resolveWorkId(workId);
    _hiddenWorkIds.add(resolved.isNotEmpty ? resolved : workId);
    await _persistHidden();
  }

  /// 프랜차이즈(IP) 전체 숨김 — 모든 매체 workId
  Future<void> hideFranchise(String franchiseId) async {
    final group = FranchiseRegistry.groupById(franchiseId);
    if (group == null) return;
    for (final member in group.members) {
      await hideWork(member);
    }
  }

  Future<void> unhideFranchise(String franchiseId) async {
    final group = FranchiseRegistry.groupById(franchiseId);
    if (group == null) return;
    for (final member in group.members) {
      await unhideWork(member);
    }
  }

  Future<void> unhideWork(String workId) async {
    if (workId.isEmpty) return;
    final resolved = WorksRegistry.resolveWorkId(workId);
    _hiddenWorkIds.remove(workId);
    if (resolved.isNotEmpty) _hiddenWorkIds.remove(resolved);
    await _persistHidden();
  }

  Future<void> setTracksMultipleFormats(
    String franchiseId, {
    required bool enabled,
  }) async {
    if (franchiseId.isEmpty) return;
    if (enabled) {
      _multiFormatFranchiseIds.add(franchiseId);
    } else {
      _multiFormatFranchiseIds.remove(franchiseId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      multiFormatFranchisesKey,
      _multiFormatFranchiseIds.toList(),
    );
  }

  Future<void> _persistHidden() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(hiddenWorkIdsKey, _hiddenWorkIds.toList());
  }
}
