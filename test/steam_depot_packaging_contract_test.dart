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
    final config = File(
      'scripts/steam/steam_upload_config.ps1',
    ).readAsStringSync();

    expect(upload, contains('prepare_steam_depot.ps1'));
    expect(upload, contains(r'$DepotStageDir'));
    expect(upload, contains('"FileExclusion" "steam_appid.txt"'));
    expect(upload, isNot(contains(r'Content:  $ReleaseDir')));

    expect(prepare, contains('/XF steam_appid.txt *.pdb'));
    expect(prepare, contains("'steam_appid.txt'"));
    expect(prepare, contains("'steam_api64.dll'"));
    expect(prepare, contains(r"'data\flutter_assets'"));
    expect(prepare, contains('Get-FileHash'));
    expect(prepare, contains('Depot stage must stay under'));

    expect(config, contains(r"build\steam\depot_windows"));
    expect(config, contains(r"build\steam\manifests\depot_windows.json"));
  });
}
