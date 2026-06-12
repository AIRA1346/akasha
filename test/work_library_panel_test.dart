import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/membership_apply_result.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/screens/home/dialogs/work_library_menu.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/services/library_membership_apply.dart';
import 'package:akasha/services/personal_library_membership_service.dart';
import 'package:akasha/widgets/work_library_panel.dart';

WorkLibraryPanelApplyCallback _diffOnlyApply(
  PersonalLibraryMembershipService membership,
  List<String> singleIds, {
  List<String>? entireIpIds,
}) {
  return (input) {
    final ids = input.useEntireIp ? (entireIpIds ?? singleIds) : singleIds;
    return membership.applyCheckboxDiff(
      workIds: ids,
      desiredChecked: input.desiredChecked,
      initialChecked: input.initialChecked,
    );
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HomePersonalLibraryController controller;
  late PersonalLibraryMembershipService membership;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    controller = HomePersonalLibraryController();
    controller.libraries = [
      PersonalLibraryConfig.masterArchive(),
      PersonalLibraryConfig(
        id: 'active',
        name: '현재 큐레이션',
        mode: PersonalLibraryMode.curated,
      ),
      PersonalLibraryConfig(
        id: 'other',
        name: '두 번째',
        mode: PersonalLibraryMode.curated,
      ),
    ];
    membership = PersonalLibraryMembershipService(controller);
  });

  Widget _wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('T22 remove from active library', () {
    testWidgets('uncheck active library and apply removes work', (tester) async {
      await membership.addWork('active', 'wk_remove');
      MembershipApplyResult? applied;

      await tester.pumpWidget(
        _wrap(
          WorkLibraryPanel(
            displayTitle: '테스트 작품',
            singleWorkIds: const ['wk_remove'],
            entireIpWorkIds: const ['wk_remove'],
            showIpScopeOption: false,
            membership: membership,
            activeLibraryId: 'active',
            onApply: _diffOnlyApply(membership, const ['wk_remove']),
            onApplied: (r) => applied = r,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('현재 서재'), findsOneWidget);

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();

      expect(applied?.removedLibraryCount, 1);
      expect(membership.librariesContaining('wk_remove'), isEmpty);
    });
  });

  group('T23 add to two libraries', () {
    testWidgets('check two libraries and apply', (tester) async {
      MembershipApplyResult? applied;

      await tester.pumpWidget(
        _wrap(
          WorkLibraryPanel(
            displayTitle: '멀티 담기',
            singleWorkIds: const ['wk_multi'],
            entireIpWorkIds: const ['wk_multi'],
            showIpScopeOption: false,
            membership: membership,
            onApply: _diffOnlyApply(membership, const ['wk_multi']),
            onApplied: (r) => applied = r,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boxes = find.byType(CheckboxListTile);
      await tester.tap(boxes.at(0));
      await tester.tap(boxes.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();

      expect(applied?.addedLibraryCount, 2);
      expect(membership.librariesContaining('wk_multi'), {'active', 'other'});
    });
  });

  group('T24 Case D IP scope', () {
    testWidgets('IP 전체 mode adds all work ids', (tester) async {
      MembershipApplyResult? applied;

      await tester.pumpWidget(
        _wrap(
          WorkLibraryPanel(
            displayTitle: 'IP 묶음',
            singleWorkIds: const ['wk_a'],
            entireIpWorkIds: const ['wk_a', 'wk_b'],
            showIpScopeOption: true,
            membership: membership,
            onApply: _diffOnlyApply(
              membership,
              const ['wk_a'],
              entireIpIds: const ['wk_a', 'wk_b'],
            ),
            onApplied: (r) => applied = r,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('IP 전체 (2)'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckboxListTile, '현재 큐레이션'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();

      expect(applied?.addedLibraryCount, 1);
      expect(membership.librariesContaining('wk_a'), {'active'});
      expect(membership.librariesContaining('wk_b'), {'active'});
    });
  });

  group('C1 partial IP subtitle', () {
    testWidgets('shows 1/2 매체 for partial membership', (tester) async {
      await membership.addWork('active', 'wk_only_a');

      await tester.pumpWidget(
        _wrap(
          WorkLibraryPanel(
            displayTitle: 'IP 부분',
            singleWorkIds: const ['wk_only_a'],
            entireIpWorkIds: const ['wk_only_a', 'wk_only_b'],
            showIpScopeOption: true,
            membership: membership,
            activeLibraryId: 'active',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('IP 전체 (2)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1/2 매체'), findsOneWidget);
    });
  });

  group('T27 title editor', () {
    testWidgets('showTitleEditor shows inline title field', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WorkLibraryPanel(
            displayTitle: '사전 작품',
            showTitleEditor: true,
            initialTitle: '기본 제목',
            draftMetaLine: '볼 예정 · 만화',
            singleWorkIds: const ['wk_new'],
            entireIpWorkIds: const ['wk_new'],
            showIpScopeOption: false,
            membership: membership,
            onApply: _diffOnlyApply(membership, const ['wk_new']),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('기본 제목'), findsOneWidget);
      expect(find.text('볼 예정 · 만화'), findsOneWidget);
      expect(find.text('기록 만들고 담기'), findsNothing);
    });
  });

  group('B2 menu open flag', () {
    test('isWorkLibraryMenuOpen false when no menu shown', () {
      expect(isWorkLibraryMenuOpen, isFalse);
    });
  });

  group('T26 no remove drop zone', () {
    test('lib has no LibraryRemoveDropZone references', () {
      final libRoot = Directory('lib');
      for (final entity in libRoot.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        expect(
          entity.readAsStringSync(),
          isNot(contains('LibraryRemoveDropZone')),
        );
      }
    });
  });
}
