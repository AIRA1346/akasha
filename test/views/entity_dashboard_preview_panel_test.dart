import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/generated/l10n/app_localizations.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/views/entity_dashboard_preview_panel.dart';
import 'package:akasha/screens/home/views/preview_panel_layout.dart';
import 'package:akasha/screens/home/views/preview_work_panel_content.dart';
import 'package:akasha/screens/home/shell_layout_spec.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';

class _FakeUserCatalog implements UserCatalogPort {
  @override
  List<UserCatalogEntity> get all => const [];

  @override
  Stream<void> get onChanged => const Stream.empty();

  @override
  Future<void> load() async {}

  @override
  UserCatalogEntity? getById(String entityId) => null;

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
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {}

  @override
  Future<List<RecordLink>> outgoingLinks(String sourcePath) async => const [];

  @override
  Future<List<String>> incomingRecordPaths(String entityId) async => const [];

  @override
  Future<Iterable<String>> incomingEntityIds() async => const [];
}

void main() {
  testWidgets('EntityDashboardPreviewPanel shows record CTA', (tester) async {
    final entity = UserCatalogEntity.userLocal(
      entityId: 'ent_test',
      type: EntityAnchorType.person,
      title: '에밀리아',
      subtype: MediaCategory.animation,
      addedAt: DateTime(2024),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: Scaffold(
          body: EntityDashboardPreviewPanel(
            entity: entity,
            userCatalog: _FakeUserCatalog(),
            linkIndex: _FakeLinkIndex(),
            vaultItems: const [],
            onClose: () {},
            onOpenDetail: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('에밀리아'), findsWidgets);
    expect(find.text('인물'), findsWidgets);
    expect(find.text('상세 정보'), findsOneWidget);
    expect(find.text('핵심 정보'), findsOneWidget);
    expect(find.text('아직 연결이 없습니다'), findsOneWidget);
    expect(find.textContaining('작품이나 다른 엔티티'), findsOneWidget);
  });

  testWidgets('Entity Preview geometry is theme invariant at 125% text', (
    tester,
  ) async {
    final entity = UserCatalogEntity.userLocal(
      entityId: 'ent_geometry',
      type: EntityAnchorType.person,
      title: '테마 불변 인물',
      subtype: MediaCategory.animation,
      aliases: const ['Theme invariant entity'],
      addedAt: DateTime(2026),
    );
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<Map<String, Rect>> geometry(AkashaThemePreset preset) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AkashaTheme.forPreset(preset),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.25)),
            child: child!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: EntityDashboardPreviewPanel(
                entity: entity,
                width: 288,
                userCatalog: _FakeUserCatalog(),
                linkIndex: _FakeLinkIndex(),
                vaultItems: const [],
                onClose: () {},
                onOpenDetail: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      return {
        'panel': tester.getRect(find.byType(EntityDashboardPreviewPanel)),
        'hero': tester.getRect(find.byType(PreviewRecordHero)),
        'action': tester.getRect(find.byType(PreviewRecordActionBar)),
        'core': tester.getRect(find.byType(PreviewRecordCoreInfoSection)),
      };
    }

    final classic = await geometry(AkashaThemePreset.classicDark);
    final midnight = await geometry(AkashaThemePreset.midnightBlue);

    expect(midnight, classic);
  });

  testWidgets('Entity compact sheet shares the capped Preview geometry', (
    tester,
  ) async {
    final entity = UserCatalogEntity.userLocal(
      entityId: 'ent_sheet_geometry',
      type: EntityAnchorType.person,
      title: '컴팩트 시트 인물',
      subtype: MediaCategory.animation,
      addedAt: DateTime(2026),
    );
    await tester.binding.setSurfaceSize(const Size(1024, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.forPreset(AkashaThemePreset.classicDark),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.25)),
          child: child!,
        ),
        home: Scaffold(
          body: EntityDashboardPreviewPanel(
            entity: entity,
            width: double.infinity,
            previewPresentation: ShellPreviewPresentation.sheet,
            userCatalog: _FakeUserCatalog(),
            linkIndex: _FakeLinkIndex(),
            vaultItems: const [],
            onClose: () {},
            onOpenDetail: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(PreviewPanelScrollBody.contentKey)).width,
      PreviewPanelLayoutSpec.sheetContentMaxWidth,
    );
    expect(
      tester.getSize(find.byType(PreviewRecordHero)).height,
      PreviewPanelLayoutSpec.sheetHeroMaxHeight,
    );
  });
}
