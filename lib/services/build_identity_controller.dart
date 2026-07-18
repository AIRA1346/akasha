import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/commerce/steam_inventory/method_channel_steam_inventory_read_port.dart';
import '../core/commerce/steam_inventory/steam_inventory_read_port.dart';
import '../core/commerce/steam_inventory/steam_runtime_environment.dart';
import '../models/build_identity.dart';

@immutable
final class PackageBuildMetadata {
  const PackageBuildMetadata({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final String buildNumber;
}

typedef PackageBuildMetadataLoader = Future<PackageBuildMetadata> Function();
typedef SteamBuildDiagnosticLoader =
    Future<SteamInventoryDiagnostic> Function();

/// Loads build identity once per process and publishes the cached snapshot.
///
/// Steam diagnostic failures are intentionally isolated from Commerce and
/// Inventory authority. They can only change the presentation fallback here.
final class BuildIdentityController extends ChangeNotifier {
  BuildIdentityController({
    required PackageBuildMetadataLoader packageMetadataLoader,
    required SteamBuildDiagnosticLoader steamDiagnosticLoader,
    BuildIdentity initialIdentity = const BuildIdentity.loading(),
  }) : _packageMetadataLoader = packageMetadataLoader,
       _steamDiagnosticLoader = steamDiagnosticLoader,
       _identity = initialIdentity;

  factory BuildIdentityController.production({
    SteamInventoryReadPort steamPort =
        const MethodChannelSteamInventoryReadPort(),
  }) {
    return BuildIdentityController(
      packageMetadataLoader: () async {
        final info = await PackageInfo.fromPlatform();
        return PackageBuildMetadata(
          version: info.version,
          buildNumber: info.buildNumber,
        );
      },
      steamDiagnosticLoader: steamPort.diagnostic,
    );
  }

  factory BuildIdentityController.seeded(BuildIdentity identity) {
    return BuildIdentityController(
      packageMetadataLoader: () async => PackageBuildMetadata(
        version: identity.version,
        buildNumber: identity.buildNumber,
      ),
      steamDiagnosticLoader: () async => const SteamInventoryDiagnostic(
        status: SteamInventoryReadStatus.unavailable,
      ),
      initialIdentity: identity,
    );
  }

  final PackageBuildMetadataLoader _packageMetadataLoader;
  final SteamBuildDiagnosticLoader _steamDiagnosticLoader;
  BuildIdentity _identity;
  Future<void>? _loadFuture;
  bool _disposed = false;

  BuildIdentity get identity => _identity;

  Future<void> load() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final package = await _packageMetadataLoader();
      _publish(
        _identity.copyWith(
          version: package.version.trim(),
          buildNumber: package.buildNumber.trim(),
          steamState: SteamBuildIdentityState.checking,
        ),
      );
    } catch (_) {
      // Package metadata is useful support information, never a startup gate.
    }
    if (_disposed) return;

    SteamInventoryDiagnostic diagnostic;
    try {
      diagnostic = await _steamDiagnosticLoader();
    } catch (_) {
      diagnostic = const SteamInventoryDiagnostic(
        status: SteamInventoryReadStatus.unavailable,
      );
    }
    _publish(_fromDiagnostic(_identity, diagnostic));
  }

  static BuildIdentity _fromDiagnostic(
    BuildIdentity current,
    SteamInventoryDiagnostic diagnostic,
  ) {
    final environment = diagnostic.executionEnvironment;
    final buildId = diagnostic.steamBuildId;
    final steamState = switch (environment) {
      SteamRuntimeExecutionEnvironment.localDebug ||
      SteamRuntimeExecutionEnvironment.localProfile ||
      SteamRuntimeExecutionEnvironment.localRelease =>
        SteamBuildIdentityState.local,
      SteamRuntimeExecutionEnvironment.steamInstall
          when diagnostic.initialized && buildId != null && buildId > 0 =>
        SteamBuildIdentityState.available,
      SteamRuntimeExecutionEnvironment.steamInstall =>
        SteamBuildIdentityState.unavailable,
      SteamRuntimeExecutionEnvironment.unknown
          when diagnostic.initialized && buildId != null && buildId > 0 =>
        SteamBuildIdentityState.available,
      SteamRuntimeExecutionEnvironment.unknown => SteamBuildIdentityState.local,
    };
    final gitCommitShort = _shortGitCommit(diagnostic.gitCommit);
    return current.copyWith(
      steamBuildId: buildId,
      clearSteamBuildId: buildId == null || buildId <= 0,
      gitCommitShort: gitCommitShort,
      clearGitCommitShort: gitCommitShort == null,
      buildMode: _normalizeBuildMode(diagnostic.buildMode),
      executionEnvironment: environment.name,
      steamState: steamState,
    );
  }

  static String _normalizeBuildMode(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'debug' ||
        normalized == 'profile' ||
        normalized == 'release') {
      return normalized;
    }
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }

  static String? _shortGitCommit(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{8,40}$').hasMatch(normalized)) return null;
    return normalized.substring(0, 8);
  }

  void _publish(BuildIdentity next) {
    if (_disposed) return;
    _identity = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class BuildIdentityScope extends InheritedNotifier<BuildIdentityController> {
  const BuildIdentityScope({
    super.key,
    required BuildIdentityController controller,
    required super.child,
  }) : super(notifier: controller);

  static BuildIdentityController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BuildIdentityScope>()
        ?.notifier;
  }

  static BuildIdentity of(BuildContext context) =>
      maybeOf(context)?.identity ?? const BuildIdentity.loading();
}
