import 'dart:io';

/// Credentials for Steam Publisher Web API.
///
/// Never hardcode production keys. Load from environment / secret manager only.
/// Must not be shipped inside the Flutter client build.
class SteamPublisherCredentials {
  SteamPublisherCredentials({
    required this.webApiKey,
    required this.appId,
    this.useSandbox = true,
  }) {
    if (webApiKey.trim().isEmpty) {
      throw ArgumentError('Steam Publisher Web API key must not be empty.');
    }
  }

  final String webApiKey;
  final int appId;
  final bool useSandbox;

  /// Reads `STEAM_PUBLISHER_WEB_API_KEY` (required) and optional `STEAM_APP_ID`.
  ///
  /// Production deploys must set the env var. Local unit tests should use
  /// [forLocalHarness] instead so they never require real secrets.
  factory SteamPublisherCredentials.fromEnvironment({
    int defaultAppId = 4677560,
    bool useSandbox = true,
    Map<String, String>? environment,
  }) {
    final env = environment ?? Platform.environment;
    final resolved = env['STEAM_PUBLISHER_WEB_API_KEY']?.trim() ?? '';
    if (resolved.isEmpty) {
      throw StateError(
        'STEAM_PUBLISHER_WEB_API_KEY is not set. '
        'Provide it via environment on the commerce server only.',
      );
    }
    final appRaw = env['STEAM_APP_ID'];
    final appId = (appRaw == null || appRaw.isEmpty)
        ? defaultAppId
        : int.parse(appRaw);
    return SteamPublisherCredentials(
      webApiKey: resolved,
      appId: appId,
      useSandbox: useSandbox,
    );
  }

  /// Explicit non-production key for sandbox/unit harnesses only.
  factory SteamPublisherCredentials.forLocalHarness({
    int appId = 4677560,
    bool useSandbox = true,
  }) {
    return SteamPublisherCredentials(
      webApiKey: 'SANDBOX_TEST_KEY_NOT_FOR_PRODUCTION',
      appId: appId,
      useSandbox: useSandbox,
    );
  }

  /// Safe for logs — never the raw key.
  String get redactedKeyHint {
    if (webApiKey.length < 8) return '***';
    return '${webApiKey.substring(0, 4)}…${webApiKey.substring(webApiKey.length - 2)}';
  }
}
