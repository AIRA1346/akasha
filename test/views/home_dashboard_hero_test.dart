import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/views/home_dashboard/home_dashboard_hero.dart';
import 'package:akasha/screens/home/views/home_dashboard/home_dashboard_summary.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _summary = HomeDashboardSummary(
  archiveRecordCount: 3246,
  entityCount: 128,
  collectionCount: 42,
  tagCount: 1156,
);

Future<Map<String, Rect>> _pumpHero(
  WidgetTester tester, {
  required Size size,
  required AkashaThemePreset preset,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AkashaTheme.forPreset(preset),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(32),
            child: HomeDashboardHero(
              summary: _summary,
              onStartRecording: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  expect(tester.takeException(), isNull);
  return {
    'panel': tester.getRect(find.byKey(HomeDashboardHero.panelKey)),
    'stats': tester.getRect(find.byKey(HomeDashboardHero.statsKey)),
    'artwork': tester.getRect(find.byKey(HomeDashboardHero.artworkKey)),
  };
}

void main() {
  for (final size in const [
    Size(1600, 900),
    Size(1366, 768),
    Size(1024, 720),
  ]) {
    testWidgets(
      'Hero has no overflow at ${size.width}x${size.height} with 125% text',
      (tester) async {
        await _pumpHero(
          tester,
          size: size,
          preset: AkashaThemePreset.classicDark,
          textScale: 1.25,
        );

        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Classic Dark and Midnight Blue keep identical Hero geometry', (
    tester,
  ) async {
    final classic = await _pumpHero(
      tester,
      size: const Size(1366, 768),
      preset: AkashaThemePreset.classicDark,
    );
    final midnight = await _pumpHero(
      tester,
      size: const Size(1366, 768),
      preset: AkashaThemePreset.midnightBlue,
    );

    expect(midnight, classic);
  });

  test('summary factory counts actual records and normalizes tags', () {
    final summary = HomeDashboardSummary.fromArchive(
      vaultItems: [
        ContentItem(
          workId: 'work-1',
          title: 'Work',
          category: MediaCategory.manga,
          domain: AppDomain.subculture,
          tags: const ['Fantasy', ' favorite ', ''],
        ),
      ],
      catalogEntities: [
        UserCatalogEntity.userLocal(
          entityId: 'person-1',
          type: EntityAnchorType.person,
          title: 'Person',
          tags: const ['fantasy', 'Character'],
        ),
        UserCatalogEntity(
          entityId: 'work-entity-1',
          subtype: MediaCategory.manga,
          title: 'Catalog work',
          tags: const ['Favorite'],
          addedAt: DateTime.utc(2026),
        ),
      ],
      collectionCount: 2,
    );

    expect(summary.archiveRecordCount, 1);
    expect(summary.entityCount, 1);
    expect(summary.collectionCount, 2);
    expect(summary.tagCount, 3);
    expect(summary.isEmpty, isFalse);
    expect(
      const HomeDashboardSummary(
        archiveRecordCount: 0,
        entityCount: 0,
        collectionCount: 0,
        tagCount: 0,
      ).isEmpty,
      isTrue,
    );
  });
}
