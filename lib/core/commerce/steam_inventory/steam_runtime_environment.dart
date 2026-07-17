enum SteamRuntimeExecutionEnvironment {
  localDebug,
  localProfile,
  localRelease,
  steamInstall,
  unknown,
}

SteamRuntimeExecutionEnvironment classifySteamRuntimeExecution(
  String? executablePath,
) {
  final normalized = _normalizeWindowsPath(executablePath).toLowerCase();
  if (normalized.endsWith(r'\build\windows\x64\runner\debug\akasha.exe')) {
    return SteamRuntimeExecutionEnvironment.localDebug;
  }
  if (normalized.endsWith(r'\build\windows\x64\runner\profile\akasha.exe')) {
    return SteamRuntimeExecutionEnvironment.localProfile;
  }
  if (normalized.endsWith(r'\build\windows\x64\runner\release\akasha.exe')) {
    return SteamRuntimeExecutionEnvironment.localRelease;
  }
  if (normalized.contains(r'\steamapps\common\') &&
      normalized.endsWith(r'\akasha.exe')) {
    return SteamRuntimeExecutionEnvironment.steamInstall;
  }
  return SteamRuntimeExecutionEnvironment.unknown;
}

String sanitizeSteamRuntimePath(String? value) {
  final normalized = _normalizeWindowsPath(value);
  if (normalized.isEmpty) return 'unknown';

  switch (classifySteamRuntimeExecution(normalized)) {
    case SteamRuntimeExecutionEnvironment.localDebug:
      return r'<repo>\build\windows\x64\runner\Debug\akasha.exe';
    case SteamRuntimeExecutionEnvironment.localProfile:
      return r'<repo>\build\windows\x64\runner\Profile\akasha.exe';
    case SteamRuntimeExecutionEnvironment.localRelease:
      return r'<repo>\build\windows\x64\runner\Release\akasha.exe';
    case SteamRuntimeExecutionEnvironment.steamInstall:
      final markerIndex = normalized.toLowerCase().indexOf(
        r'\steamapps\common\',
      );
      return '<steam-library>${normalized.substring(markerIndex)}';
    case SteamRuntimeExecutionEnvironment.unknown:
      break;
  }

  final windowsProfile = RegExp(
    r'^[A-Za-z]:\\Users\\[^\\]+',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (windowsProfile != null) {
    return '<user-profile>${normalized.substring(windowsProfile.end)}';
  }

  final slashPath = normalized.replaceAll(r'\', '/');
  final unixProfile = RegExp(
    r'^/(Users|home)/[^/]+',
    caseSensitive: false,
  ).firstMatch(slashPath);
  if (unixProfile != null) {
    return '<user-profile>${slashPath.substring(unixProfile.end)}';
  }

  final parts = normalized
      .split(r'\')
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return '<redacted>';
  final start = parts.length > 5 ? parts.length - 5 : 0;
  return '<redacted>\\${parts.sublist(start).join(r'\')}';
}

String _normalizeWindowsPath(String? value) =>
    (value ?? '').trim().replaceAll('/', r'\');
