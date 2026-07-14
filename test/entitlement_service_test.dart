import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/services/entitlement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EntitlementService', () {
    test('purchase stub remains dormant before Steam integration', () async {
      final svc = EntitlementService.instance;
      await svc.load();
      expect(
        await svc.purchaseCosmetic(EntitlementService.themePackProductId),
        isFalse,
      );
    });

    test('content entitlements are separate from cosmetic', () async {
      final svc = EntitlementService.instance;
      await svc.load();
      expect(svc.ownsContent('partner:bookwalker:bn_1'), isFalse);

      await svc.grantContentEntitlement('partner:bookwalker:bn_1');
      expect(svc.ownsContent('partner:bookwalker:bn_1'), isTrue);
      expect(svc.owns('partner:bookwalker:bn_1'), isFalse);
    });
  });
}
