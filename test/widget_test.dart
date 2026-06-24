import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AkashaApp smoke builds home dashboard hero', (tester) async {
    await tester.pumpWidget(const AkashaApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('기록하고, 연결하고, 발견하세요'), findsOneWidget);
  });
}
