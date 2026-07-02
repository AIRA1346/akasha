import 'package:akasha/models/library_theme.dart';
import 'package:akasha/widgets/library_theme_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('library theme picker uses app theme copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showLibraryThemePicker(
                context,
                current: LibraryTheme.classic,
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('앱 테마'), findsOneWidget);
    expect(find.text('서재 테마'), findsNothing);
    expect(find.text('현재 제공되는 앱 테마는 모두 무료입니다.'), findsOneWidget);
    expect(find.text('Steam에서 구매'), findsNothing);
  });
}
