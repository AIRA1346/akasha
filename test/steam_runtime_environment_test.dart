import 'package:akasha/core/commerce/commerce.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies local build and Steam install executable paths', () {
    expect(
      classifySteamRuntimeExecution(
        r'C:\src\akasha\build\windows\x64\runner\Debug\akasha.exe',
      ),
      SteamRuntimeExecutionEnvironment.localDebug,
    );
    expect(
      classifySteamRuntimeExecution(
        r'D:\SteamLibrary\steamapps\common\Akasha\akasha.exe',
      ),
      SteamRuntimeExecutionEnvironment.steamInstall,
    );
    expect(
      classifySteamRuntimeExecution(r'C:\unrelated\akasha.exe'),
      SteamRuntimeExecutionEnvironment.unknown,
    );
  });

  test('sanitizes user profiles and preserves useful execution signatures', () {
    expect(
      sanitizeSteamRuntimePath(
        r'C:\Users\Alice\src\akasha\build\windows\x64\runner\Debug\akasha.exe',
      ),
      r'<repo>\build\windows\x64\runner\Debug\akasha.exe',
    );
    expect(
      sanitizeSteamRuntimePath(r'C:\Users\Alice\src\akasha'),
      r'<user-profile>\src\akasha',
    );
    expect(
      sanitizeSteamRuntimePath(
        r'D:\SteamLibrary\steamapps\common\Akasha\akasha.exe',
      ),
      r'<steam-library>\steamapps\common\Akasha\akasha.exe',
    );
  });
}
