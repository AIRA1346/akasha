import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/data/adapters/markdown_vault_adapter.dart';
import 'package:akasha/screens/home/coordinators/home_membership_coordinator.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/personal_library_membership_service.dart';
import 'package:akasha/utils/helpers.dart';

import '../fakes/fake_registry_port.dart';

/// `home_screen._addWorkToLibrary` Presentation 레이어 미러 (W1-3 smoke).
class CuratedAddWorkSmokeHarness extends StatefulWidget {
  const CuratedAddWorkSmokeHarness({
    super.key,
    required this.coordinator,
    required this.libraryId,
    required this.item,
  });

  final HomeMembershipCoordinator coordinator;
  final String libraryId;
  final AkashaItem item;

  @override
  State<CuratedAddWorkSmokeHarness> createState() =>
      _CuratedAddWorkSmokeHarnessState();
}

class _CuratedAddWorkSmokeHarnessState extends State<CuratedAddWorkSmokeHarness> {
  Future<void> addWork() async {
    if (AkashaFileService().vaultPath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('볼트 연결 후 서재에 담을 수 있습니다.')),
      );
      return;
    }

    final outcome = await widget.coordinator.addWorkToLibrary(
      libraryId: widget.libraryId,
      item: widget.item,
    );

    if (outcome.vaultMdError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('기록 생성 실패: ${outcome.vaultMdError}')),
      );
      return;
    }
    if (outcome.skipped || outcome.libraryName == null) return;
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.alreadyInLibrary
              ? '이미 「${outcome.libraryName}」에 담긴 작품입니다.'
              : '「${outcome.libraryName}」에 담았습니다.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: addWork,
          child: const Text('서재에 담기'),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('curated membership smoke (W1-3)', () {
    const favoritesLibraryId = 'lib_favorites';

    late Directory vaultDir;
    late HomePersonalLibraryController libraryController;
    late PersonalLibraryMembershipService membership;
    late HomeMembershipCoordinator coordinator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      vaultDir =
          await Directory.systemTemp.createTemp('akasha_curated_smoke_test');
      await AkashaFileService().setVaultPath(vaultDir.path);

      libraryController = HomePersonalLibraryController();
      libraryController.libraries = PersonalLibraryConfig.normalizeLibraries([
        PersonalLibraryConfig.masterArchive(),
        PersonalLibraryConfig(
          id: favoritesLibraryId,
          name: '즐겨찾기',
          mode: PersonalLibraryMode.curated,
        ),
      ]);
      membership = PersonalLibraryMembershipService(libraryController, FakeRegistryPort());
      coordinator = HomeMembershipCoordinator(
        vault: MarkdownVaultAdapter(),
        personalLibraryController: libraryController,
        membership: membership,
        resolveItemForOpen: (item) => item,
        reloadItems: () async {},
      );
    });

    tearDown(() async {
      await AkashaFileService().setVaultPath('');
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    });

    testWidgets(
      'HomeMembershipCoordinator add shows snackbar and updates memberOrder',
      (tester) async {
        final item = createItem(
          workId: 'wk_smoke_favorites',
          title: '스모크 담기',
          category: MediaCategory.manga,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CuratedAddWorkSmokeHarness(
              coordinator: coordinator,
              libraryId: favoritesLibraryId,
              item: item,
            ),
          ),
        );
        await tester.pump();

        final harness = tester.state<_CuratedAddWorkSmokeHarnessState>(
          find.byType(CuratedAddWorkSmokeHarness),
        );
        // testWidgets fake-async — 볼트 I/O는 runAsync 안에서 coordinator를 호출해야 완료됨
        await tester.runAsync(harness.addWork);
        await tester.pump();

        expect(find.text('「즐겨찾기」에 담았습니다.'), findsOneWidget);
        expect(find.text('서재에 담기'), findsOneWidget);

        final library = libraryController.libraries
            .singleWhere((l) => l.id == favoritesLibraryId);
        expect(library.memberOrder, hasLength(1));
        expect(
          membership.librariesContaining(item.workId),
          {favoritesLibraryId},
        );
      },
    );
  });
}
