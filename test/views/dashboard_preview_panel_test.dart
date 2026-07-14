import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/views/dashboard_preview_panel.dart';
import 'package:akasha/screens/home/views/preview_panel_layout.dart';
import 'package:akasha/screens/home/views/preview_work_panel_content.dart';
import 'package:akasha/screens/home/shell_layout_spec.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserCatalog implements UserCatalogPort {
  @override
  List<UserCatalogEntity> get all => const [];

  @override
  Stream<void> get onChanged => const Stream.empty();

  @override
  UserCatalogEntity? getById(String entityId) => null;

  @override
  Future<void> load() async {}

  @override
  Future<void> remove(String entityId) async {}

  @override
  List<UserCatalogEntity> search(
    String query, {
    MediaCategory? subtype,
    EntityAnchorType? entityType,
  }) => const [];

  @override
  Future<void> upsert(UserCatalogEntity entity) async {}
}

class _FakeLinkIndex implements RecordLinkPort {
  @override
  Future<RecordLinkSummary> loadSummary() async => RecordLinkSummary.empty;

  @override
  Future<Iterable<String>> incomingEntityIds() async => const [];

  @override
  Future<List<String>> incomingRecordPaths(String entityId) async => const [];

  @override
  Future<List<RecordLink>> outgoingLinks(String sourcePath) async => const [];

  @override
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {}
}

ContentItem _work() => ContentItem(
  workId: 'wk_u_preview_contract',
  title: '프리뷰 계약 작품',
  category: MediaCategory.manga,
  domain: AppDomain.subculture,
  creator: '기록자',
  releaseYear: 2026,
  rating: 4.5,
  myStatus: ContentMyStatus.finished,
  tags: const ['아카이브', '연결'],
  review: '개인 평점과 감상은 이 영역에만 표시됩니다.',
);

Future<void> _pumpPanel(
  WidgetTester tester, {
  required AkashaItem item,
  required List<AkashaItem> vaultItems,
  AkashaThemePreset preset = AkashaThemePreset.classicDark,
  double textScale = 1,
  Size surfaceSize = const Size(360, 900),
  ShellPreviewPresentation previewPresentation =
      ShellPreviewPresentation.inline,
  bool canGoBack = false,
  VoidCallback? onBack,
  VoidCallback? onOpenDetail,
  Future<void> Function()? onArchive,
  void Function(EntityAnchorType type)? onConnectEntityType,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: AkashaTheme.forPreset(preset),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.centerRight,
          child: DashboardPreviewPanel(
            item: item,
            width: previewPresentation == ShellPreviewPresentation.sheet
                ? double.infinity
                : 288,
            previewPresentation: previewPresentation,
            userCatalog: _FakeUserCatalog(),
            linkIndex: _FakeLinkIndex(),
            vaultItems: vaultItems,
            canGoBack: canGoBack,
            onBack: onBack,
            onClose: () {},
            onOpenDetail: onOpenDetail ?? () {},
            onArchiveRegistryWork: onArchive,
            onConnectEntityType: onConnectEntityType,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('primary Preview action is keyboard activatable', (tester) async {
    var actionCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.forPreset(AkashaThemePreset.classicDark),
        home: Scaffold(
          body: PreviewRecordActionBar(onPressed: () => actionCount++),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(actionCount, 1);
  });

  testWidgets('catalog work exposes one honest archive primary action', (
    tester,
  ) async {
    final item = _work();
    var archiveCount = 0;
    var detailCount = 0;

    await _pumpPanel(
      tester,
      item: item,
      vaultItems: const [],
      onOpenDetail: () => detailCount++,
      onArchive: () async => archiveCount++,
    );

    expect(find.text('아카이브'), findsOneWidget);
    expect(find.text('상세 정보'), findsNothing);
    expect(find.text('볼트에 아카이브'), findsNothing);

    await tester.tap(find.text('아카이브'));
    await tester.pumpAndSettle();

    expect(archiveCount, 1);
    expect(detailCount, 0);
  });

  testWidgets('archived work separates Preview back from detail action', (
    tester,
  ) async {
    final item = _work();
    var backCount = 0;
    var detailCount = 0;

    await _pumpPanel(
      tester,
      item: item,
      vaultItems: [item],
      canGoBack: true,
      onBack: () => backCount++,
      onOpenDetail: () => detailCount++,
    );

    expect(find.text('상세 정보'), findsOneWidget);
    expect(find.text('아카이브'), findsNothing);
    expect(find.text('평점'), findsNothing);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.tap(find.text('상세 정보'));

    expect(backCount, 1);
    expect(detailCount, 1);
  });

  testWidgets('empty connections preserve type actions behind one menu', (
    tester,
  ) async {
    final item = _work();
    EntityAnchorType? selectedType;

    await _pumpPanel(
      tester,
      item: item,
      vaultItems: [item],
      onConnectEntityType: (type) => selectedType = type,
    );

    expect(find.text('연결 추가'), findsOneWidget);
    expect(find.text('인물 연결'), findsNothing);

    await tester.ensureVisible(find.text('연결 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('연결 추가'));
    await tester.pumpAndSettle();
    expect(find.text('인물 연결'), findsOneWidget);

    await tester.tap(find.text('인물 연결'));
    await tester.pumpAndSettle();
    expect(selectedType, EntityAnchorType.person);
  });

  testWidgets('Preview geometry is theme invariant at 125% text', (
    tester,
  ) async {
    final item = _work();

    Future<Map<String, Rect>> geometry(AkashaThemePreset preset) async {
      await _pumpPanel(
        tester,
        item: item,
        vaultItems: [item],
        preset: preset,
        textScale: 1.25,
      );
      return {
        'panel': tester.getRect(find.byType(DashboardPreviewPanel)),
        'hero': tester.getRect(find.byType(PreviewRecordHero)),
        'action': tester.getRect(find.byType(PreviewRecordActionBar)),
        'core': tester.getRect(find.byType(PreviewRecordCoreInfoSection)),
      };
    }

    final classic = await geometry(AkashaThemePreset.classicDark);
    final midnight = await geometry(AkashaThemePreset.midnightBlue);

    expect(midnight, classic);
  });

  testWidgets('inline and overlay Preview share the 288px rail contract', (
    tester,
  ) async {
    final item = _work();

    for (final presentation in const [
      ShellPreviewPresentation.inline,
      ShellPreviewPresentation.overlay,
    ]) {
      await _pumpPanel(
        tester,
        item: item,
        vaultItems: [item],
        textScale: 1.25,
        surfaceSize: const Size(360, 768),
        previewPresentation: presentation,
      );

      expect(tester.getSize(find.byType(DashboardPreviewPanel)).width, 288);
      expect(
        tester.getSize(find.byKey(PreviewPanelScrollBody.contentKey)).width,
        259,
      );
      expect(
        tester.getSize(find.byType(PreviewRecordHero)).height,
        PreviewPanelLayoutSpec.railHeroMaxHeight,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('compact Preview sheet caps readable width and hero height', (
    tester,
  ) async {
    final item = _work();

    Future<Map<String, Rect>> geometry(AkashaThemePreset preset) async {
      await _pumpPanel(
        tester,
        item: item,
        vaultItems: [item],
        preset: preset,
        textScale: 1.25,
        surfaceSize: const Size(1024, 520),
        previewPresentation: ShellPreviewPresentation.sheet,
      );
      return {
        'panel': tester.getRect(find.byType(DashboardPreviewPanel)),
        'content': tester.getRect(
          find.byKey(PreviewPanelScrollBody.contentKey),
        ),
        'hero': tester.getRect(find.byType(PreviewRecordHero)),
      };
    }

    final classic = await geometry(AkashaThemePreset.classicDark);
    final midnight = await geometry(AkashaThemePreset.midnightBlue);

    expect(classic['panel']!.width, 1024);
    expect(
      classic['content']!.width,
      PreviewPanelLayoutSpec.sheetContentMaxWidth,
    );
    expect(classic['hero']!.height, PreviewPanelLayoutSpec.sheetHeroMaxHeight);
    expect(midnight, classic);
  });
}
