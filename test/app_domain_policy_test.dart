import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';

void main() {
  group('AppDomain.fromStorage', () {
    test('maps generalCulture and unknown to subculture', () {
      expect(AppDomain.fromStorage(null), AppDomain.subculture);
      expect(AppDomain.fromStorage(''), AppDomain.subculture);
      expect(AppDomain.fromStorage('generalCulture'), AppDomain.subculture);
      expect(AppDomain.fromStorage('subculture'), AppDomain.subculture);
      expect(AppDomain.fromStorage('invalid'), AppDomain.subculture);
    });
  });
}
