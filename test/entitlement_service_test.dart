import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/library_theme.dart';
import 'package:akasha/services/entitlement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EntitlementService', () {
    test('free themes are always usable', () async {
      final svc = EntitlementService.instance;
      await svc.load();
      expect(svc.canUseTheme(LibraryTheme.classic), isTrue);
      expect(svc.canUseTheme(LibraryTheme.midnight), isTrue);
    });

    test('IAP themes locked until entitlement granted', () async {
      final svc = EntitlementService.instance;
      await svc.load();
      expect(svc.canUseTheme(LibraryTheme.sakura), isFalse);

      await svc.grantEntitlement(EntitlementService.libraryThemePackId);
      expect(svc.canUseTheme(LibraryTheme.sakura), isTrue);
      expect(svc.canUseTheme(LibraryTheme.obsidian), isTrue);
    });

    test('purchase stub returns false before Steam integration', () async {
      final svc = EntitlementService.instance;
      await svc.load();
      expect(
        await svc.purchase(EntitlementService.libraryThemePackId),
        isFalse,
      );
    });
  });
}
