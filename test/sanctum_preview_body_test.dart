import 'package:akasha/widgets/sanctum/sanctum_preview_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SanctumPreviewBody agent slice', () {
    testWidgets('renders memo section as card for agent-style body', (tester) async {
      const body = '''
# 📝 메모

Agent A1 create — 최소 기록.

2화부터 몰입됐다. 엔딩 크레딧까지 울컥.
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SanctumPreviewBody(data: body, slotAware: true),
            ),
          ),
        ),
      );

      expect(find.textContaining('2화부터 몰입'), findsOneWidget);
      expect(find.textContaining('📝'), findsOneWidget);
    });

    testWidgets('shows muted hint for empty memo slot', (tester) async {
      const body = '''
# 📝 메모

''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SanctumPreviewBody(data: body, slotAware: true),
          ),
        ),
      );

      expect(find.text('메모가 비어 있습니다.'), findsOneWidget);
    });
  });
}
