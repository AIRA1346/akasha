import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/models/theme_catalog.dart';
import 'package:akasha/widgets/akasha_theme_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('theme gallery exposes all official themes without fake store', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showAkashaThemePicker(
                context,
                currentThemeId: AkashaThemeRegistry.classicDark.id,
                accessByPresetId: {
                  for (final definition in AkashaThemeRegistry.all)
                    definition.id: definition.catalog.isBundled
                        ? ThemeAccessState.free
                        : ThemeAccessState.unavailable,
                },
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

    expect(find.text('테마 갤러리'), findsOneWidget);
    expect(find.text('서재 테마'), findsNothing);
    expect(find.text('전체 5개 중 2개 사용 가능'), findsOneWidget);
    expect(find.text('Classic Dark'), findsOneWidget);
    expect(find.text('Midnight Blue'), findsOneWidget);
    expect(find.text('Sakura'), findsOneWidget);
    expect(find.text('Amethyst'), findsOneWidget);
    expect(find.text('Nocturne'), findsOneWidget);
    expect(find.text('유료 · 출시 예정'), findsNWidgets(3));
    expect(find.text('500 Astra 또는 500 Echo'), findsNWidgets(3));
    expect(find.text('Steam에서 구매'), findsNothing);
    expect(find.text('Astra 0'), findsNothing);
  });
}
