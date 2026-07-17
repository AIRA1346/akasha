import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  if (!Platform.isWindows) {
    test('Windows Steam runtime scripts are Windows-only', () {}, skip: true);
    return;
  }

  final repoRoot = Directory.current.absolute.path;
  final modulePath = p.join(repoRoot, 'tool', 'steam_runtime_contract.psm1');
  final verifierPath = p.join(
    repoRoot,
    'tool',
    'verify_steam_release_payload.ps1',
  );

  test('PowerShell contract classifies and sanitizes paths', () async {
    final module = _psLiteral(modulePath);
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      "Import-Module '$module' -Force; "
          "Get-AkashaExecutionEnvironment -ExecutablePath 'C:\\repo\\build\\windows\\x64\\runner\\Debug\\akasha.exe'; "
          "ConvertTo-AkashaSupportPath -Path 'C:\\Users\\Alice\\src\\akasha'",
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final output = '${result.stdout}';
    expect(output, contains('local_debug'));
    expect(output, contains(r'<user-profile>\src\akasha'));
    expect(output, isNot(contains('Alice')));
  });

  test('PowerShell contract rejects an App ID mismatch', () async {
    final temp = await Directory.systemTemp.createTemp('akasha-appid-test-');
    addTearDown(() => temp.delete(recursive: true));
    final appId = File(p.join(temp.path, 'steam_appid.txt'))
      ..writeAsStringSync('123\n');
    final module = _psLiteral(modulePath);
    final file = _psLiteral(appId.path);

    final result = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      "Import-Module '$module' -Force; "
          "Test-AkashaSteamAppIdFile -Path '$file' -ExpectedAppId '4677560'",
    ]);

    expect(result.exitCode, isNot(0));
    expect('${result.stdout}${result.stderr}', contains('App ID mismatch'));
  });

  test(
    'release payload verifier covers clean and forbidden fixtures',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'akasha-payload-test-',
      );
      addTearDown(() => temp.delete(recursive: true));
      File(p.join(temp.path, 'akasha.exe')).createSync(recursive: true);
      File(p.join(temp.path, 'steam_api64.dll')).createSync(recursive: true);
      Directory(
        p.join(temp.path, 'data', 'flutter_assets'),
      ).createSync(recursive: true);

      var result = await _runVerifier(verifierPath, temp.path);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect('${result.stdout}', contains('verification passed'));

      final appId = File(p.join(temp.path, 'STEAM_APPID.TXT'))
        ..writeAsStringSync('4677560\n');
      result = await _runVerifier(verifierPath, temp.path);
      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}${result.stderr}'.toLowerCase(),
        contains(appId.path.toLowerCase()),
      );
      appId.deleteSync();

      final pdb = File(p.join(temp.path, 'native', 'AKASHA.PDB'))
        ..createSync(recursive: true);
      result = await _runVerifier(verifierPath, temp.path);
      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}${result.stderr}'.toLowerCase(),
        contains(pdb.path.toLowerCase()),
      );
      pdb.deleteSync();

      File(
        p.join(temp.path, 'settings.json'),
      ).writeAsStringSync(r'{"sdk":"C:\Users\Alice\sdk"}');
      result = await _runVerifier(verifierPath, temp.path);
      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}${result.stderr}',
        contains('personal_path_content'),
      );
    },
  );

  test('build and launcher scripts preserve the Debug/Release boundary', () {
    final runnerCmake = File(
      p.join(repoRoot, 'windows', 'runner', 'CMakeLists.txt'),
    ).readAsStringSync();
    final windowsCmake = File(
      p.join(repoRoot, 'windows', 'CMakeLists.txt'),
    ).readAsStringSync();
    final launcher = File(
      p.join(repoRoot, 'tool', 'run_windows_steam_dev.ps1'),
    ).readAsStringSync();
    final releaseBuild = File(
      p.join(repoRoot, 'scripts', 'build_release.ps1'),
    ).readAsStringSync();
    final sandboxBuild = File(
      p.join(repoRoot, 'scripts', 'build_steam_inventory_sandbox.ps1'),
    ).readAsStringSync();

    expect(runnerCmake, isNot(contains('steam_appid.txt')));
    expect(windowsCmake, contains('CONFIGURATIONS Debug'));
    expect(windowsCmake, contains('runner/steam_appid.txt'));
    expect(launcher, contains(r"'build\windows\x64\runner\Debug'"));
    expect(launcher, contains(r'-WorkingDirectory $debugDir'));
    expect(launcher, contains('Get-AkashaExecutionEnvironment'));
    expect(launcher, contains('EnableSandboxCommerce'));
    expect(releaseBuild, contains('verify_steam_release_payload.ps1'));
    expect(sandboxBuild, contains('Release contract violation'));
    expect(sandboxBuild, contains('verify_steam_release_payload.ps1'));
    expect(sandboxBuild, isNot(contains('raw Release directory; it contains')));
  });
}

Future<ProcessResult> _runVerifier(String script, String payload) =>
    Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script,
      '-PayloadPath',
      payload,
      '-PayloadKind',
      'Fixture',
    ]);

String _psLiteral(String value) => value.replaceAll("'", "''");
