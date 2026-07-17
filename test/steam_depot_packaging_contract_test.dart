import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SteamPipe uploads only the verified staged depot', () {
    final upload = File(
      'scripts/steam/upload_steam_build.ps1',
    ).readAsStringSync();
    final prepare = File(
      'scripts/steam/prepare_steam_depot.ps1',
    ).readAsStringSync();
    final validate = File(
      'scripts/steam/validate_steam_pipe_config.ps1',
    ).readAsStringSync();
    final config = File(
      'scripts/steam/steam_upload_config.ps1',
    ).readAsStringSync();
    final appVdf = File(
      'scripts/steam/app_build_4677560_commerce_sandbox.vdf',
    ).readAsStringSync();
    final depotVdf = File(
      'scripts/steam/depot_build_4677561.vdf',
    ).readAsStringSync();

    expect(upload, contains('prepare_steam_depot.ps1'));
    expect(upload, contains('validate_steam_pipe_config.ps1'));
    expect(upload, contains(r'$DepotStageDir'));
    expect(upload, contains(r'+run_app_build $AppBuildVdf'));
    expect(upload, isNot(contains(r'Content:  $ReleaseDir')));
    expect(upload, contains(r'build\steam\upload_receipts'));
    expect(upload, contains('gitSha'));
    expect(upload, contains('buildId'));

    expect(prepare, contains('/XF steam_appid.txt *.pdb'));
    expect(prepare, contains("'steam_appid.txt'"));
    expect(prepare, contains("'steam_api64.dll'"));
    expect(prepare, contains(r"'data\flutter_assets'"));
    expect(prepare, contains('Get-FileHash'));
    expect(prepare, contains('gitSha'));
    expect(prepare, contains(r'git -C $AkashaRoot rev-parse HEAD'));
    expect(prepare, contains('Depot stage must stay under'));

    expect(config, contains(r"build\steam\depot_windows"));
    expect(config, contains(r"build\steam\manifests\depot_windows.json"));
    expect(config, contains('AKASHA_STEAM_CONTENT_BUILDER'));
    expect(config, contains('steam_content_builder.path'));
    expect(config, contains(r"build\steam\steamcmd_output"));
    expect(config, contains(r"$SteamBranchName = 'commerce-sandbox'"));
    expect(config, contains('app_build_4677560_commerce_sandbox.vdf'));
    expect(config, contains('depot_build_4677561.vdf'));
    expect(config, isNot(contains(RegExp(r'[A-Za-z]:\\'))));

    expect(appVdf, contains('"AppID" "4677560"'));
    expect(appVdf, contains('"SetLive" "commerce-sandbox"'));
    expect(
      appVdf,
      contains(r'"ContentRoot" "..\..\build\steam\depot_windows"'),
    );
    expect(
      appVdf,
      contains(r'"BuildOutput" "..\..\build\steam\steamcmd_output"'),
    );
    expect(appVdf, contains('"4677561" "depot_build_4677561.vdf"'));
    expect(appVdf, isNot(contains(RegExp(r'[A-Za-z]:\\'))));

    expect(depotVdf, contains('"DepotID" "4677561"'));
    expect(depotVdf, contains('"FileExclusion" "*.pdb"'));
    expect(depotVdf, contains('"FileExclusion" "steam_appid.txt"'));
    expect(
      depotVdf,
      contains(r'"ContentRoot" "..\..\build\steam\depot_windows"'),
    );
    expect(depotVdf, isNot(contains(RegExp(r'[A-Za-z]:\\'))));

    expect(validate, contains('ConvertFrom-Json'));
    expect(validate, contains('Stage hash mismatch'));
    expect(validate, contains('Manifest Git SHA is missing or invalid'));
    expect(validate, contains('App VDF ContentRoot mismatch'));
    expect(validate, contains('must map the entire staged ContentRoot'));
    expect(validate, contains('SteamCMD upload command (NOT executed)'));
    expect(validate, isNot(contains(r'& $SteamCmd +login')));
  });
}
