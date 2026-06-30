import 'package:akasha/config/feature_flags.dart';
import 'package:akasha/screens/home/home_app_bar.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeAppBar always exposes app theme, vault, and overflow menu',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: Scaffold(
          appBar: HomeAppBar(
            isSidebarOpen: true,
            isSyncing: false,
            vaultLinked: false,
            onToggleSidebar: () {},
            onClipboardImport: () {},
            onSync: () {},
            onSyncSettings: () {},
            onPromptTemplates: () {},
            onVaultSettings: () {},
            onClearRegistryCache: () {},
            onCatalogInbox: () {},
            catalogContributionCount: 2,
            onAppTheme: () {},
            appThemeAccent: Colors.tealAccent,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.search), findsNothing);
    expect(find.byTooltip('앱 테마'), findsOneWidget);
    expect(find.byTooltip('도구 더보기'), findsOneWidget);
    expect(find.byTooltip('카탈로그 제안함'), findsOneWidget);
    expect(find.byTooltip('로컬 폴더(Vault) 설정'), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
    expect(find.byIcon(Icons.sync), findsNothing);
    expect(find.byIcon(Icons.copy_all), findsNothing);
    expect(find.byIcon(Icons.delete_sweep_outlined), findsNothing);
  });

  testWidgets('HomeAppBar overflow menu lists grouped tools', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: Scaffold(
          appBar: HomeAppBar(
            isSidebarOpen: true,
            isSyncing: false,
            vaultLinked: true,
            onToggleSidebar: () {},
            onClipboardImport: () {},
            onTimelineCapture: () {},
            onSync: () {},
            onSyncSettings: () {},
            onPromptTemplates: () {},
            onVaultSettings: () {},
            onClearRegistryCache: () {},
            onAppTheme: () {},
            appThemeAccent: Colors.tealAccent,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('도구 더보기'));
    await tester.pumpAndSettle();

    expect(find.text('글로벌 작품 사전 동기화'), findsOneWidget);
    expect(find.text('AI 마크다운 가져오기'), findsOneWidget);
    expect(find.text('AI 프롬프트 템플릿 복사'), findsOneWidget);
    if (FeatureFlags.showTimeline) {
      expect(find.text('타임라인 기록'), findsOneWidget);
    } else {
      expect(find.text('타임라인 기록'), findsNothing);
    }
  });
}
