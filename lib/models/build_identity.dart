import 'package:flutter/foundation.dart';

enum SteamBuildIdentityState { checking, available, local, unavailable }

/// Immutable identity of the executable currently running AKASHA.
///
/// App version/build metadata and SteamPipe BuildID are deliberately separate:
/// they are issued by different systems and are not expected to match.
@immutable
final class BuildIdentity {
  const BuildIdentity({
    required this.version,
    required this.buildNumber,
    required this.steamBuildId,
    required this.gitCommitShort,
    required this.buildMode,
    required this.executionEnvironment,
    required this.steamState,
  });

  const BuildIdentity.loading()
    : version = '',
      buildNumber = '',
      steamBuildId = null,
      gitCommitShort = null,
      buildMode = 'unknown',
      executionEnvironment = 'unknown',
      steamState = SteamBuildIdentityState.checking;

  final String version;
  final String buildNumber;
  final int? steamBuildId;
  final String? gitCommitShort;
  final String buildMode;
  final String executionEnvironment;
  final SteamBuildIdentityState steamState;

  bool get hasAppVersion => version.trim().isNotEmpty;

  String get versionLabel {
    final cleanVersion = version.trim().replaceFirst(RegExp(r'^v'), '');
    if (cleanVersion.isEmpty) return '';
    final cleanBuild = buildNumber.trim();
    return cleanBuild.isEmpty ? 'v$cleanVersion' : 'v$cleanVersion+$cleanBuild';
  }

  String summaryLabel({
    required String localLabel,
    required String steamCheckingLabel,
  }) {
    final app = versionLabel;
    if (app.isEmpty) return '';
    return switch (steamState) {
      SteamBuildIdentityState.available
          when steamBuildId != null && steamBuildId! > 0 =>
        '$app • Steam $steamBuildId',
      SteamBuildIdentityState.available => app,
      SteamBuildIdentityState.local => '$app • $localLabel',
      SteamBuildIdentityState.checking => '$app • $steamCheckingLabel',
      SteamBuildIdentityState.unavailable => app,
    };
  }

  String copyText({
    String localLabel = 'Local',
    String unavailableLabel = 'unavailable',
    String checkingLabel = 'Steam checking',
  }) {
    final segments = <String>[
      'AKASHA${versionLabel.isEmpty ? '' : ' $versionLabel'}',
    ];
    switch (steamState) {
      case SteamBuildIdentityState.available:
        final id = steamBuildId;
        segments.add(id != null && id > 0 ? 'Steam $id' : unavailableLabel);
      case SteamBuildIdentityState.local:
        segments.add(localLabel);
      case SteamBuildIdentityState.checking:
        segments.add(checkingLabel);
      case SteamBuildIdentityState.unavailable:
        segments.add('Steam $unavailableLabel');
    }
    if (gitCommitShort case final commit? when commit.isNotEmpty) {
      segments.add('Git $commit');
    }
    if (buildMode != 'unknown' && buildMode.isNotEmpty) {
      segments.add(buildMode);
    }
    if (executionEnvironment != 'unknown' && executionEnvironment.isNotEmpty) {
      segments.add(executionEnvironment);
    }
    return segments.join(' | ');
  }

  BuildIdentity copyWith({
    String? version,
    String? buildNumber,
    int? steamBuildId,
    bool clearSteamBuildId = false,
    String? gitCommitShort,
    bool clearGitCommitShort = false,
    String? buildMode,
    String? executionEnvironment,
    SteamBuildIdentityState? steamState,
  }) {
    return BuildIdentity(
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      steamBuildId: clearSteamBuildId
          ? null
          : (steamBuildId ?? this.steamBuildId),
      gitCommitShort: clearGitCommitShort
          ? null
          : (gitCommitShort ?? this.gitCommitShort),
      buildMode: buildMode ?? this.buildMode,
      executionEnvironment: executionEnvironment ?? this.executionEnvironment,
      steamState: steamState ?? this.steamState,
    );
  }
}
