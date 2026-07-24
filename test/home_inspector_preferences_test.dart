import 'package:akasha/screens/home/home_inspector_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('inspector defaults open and persists the user toggle', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await HomeInspectorPreferences.loadOpen(), isTrue);

    await HomeInspectorPreferences.saveOpen(false);
    expect(await HomeInspectorPreferences.loadOpen(), isFalse);

    await HomeInspectorPreferences.saveOpen(true);
    expect(await HomeInspectorPreferences.loadOpen(), isTrue);
  });
}
