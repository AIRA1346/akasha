import 'package:akasha/models/enums.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/models/work_drag_payload.dart';
import 'package:akasha/screens/home/app_destination.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/dashboard_sidebar.dart';
import 'package:akasha/widgets/personal_library_drop_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashboardSidebar shows personal libraries section with add', (
    tester,
  ) async {
    var addTapped = false;
    String? selectedId;

    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: Scaffold(
          body: DashboardSidebar(
            isOpen: true,
            width: 256,
            selectedDestination: AppDestination.home,
            onSelectDestination: (_) {},
            selectionMode: SidebarSelectionMode.dashboard,
            personalLibraries: const [],
            onSelectCollectibleCollection: (_) {},
            onAddPersonalLibrary: () => addTapped = true,
            onSelectPersonalLibrary: (id) => selectedId = id,
          ),
        ),
      ),
    );

    expect(find.text('나만의 서재'), findsOneWidget);
    expect(find.text('나만의 서재를 만들어 보세요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    expect(addTapped, isTrue);
    expect(selectedId, isNull);
  });

  testWidgets('DashboardSidebar personal library rows select and highlight', (
    tester,
  ) async {
    var selectedId = '';
    PersonalLibraryConfig? editedLibrary;
    String? deletedId;

    final libraries = [
      PersonalLibraryConfig(
        id: PersonalLibraryConfig.masterArchiveId,
        name: '전체 아카이브',
      ),
      PersonalLibraryConfig(
        id: 'curated_demo',
        name: '인생 명작',
        mode: PersonalLibraryMode.curated,
        memberOrder: const ['wk_demo'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: Scaffold(
          body: DashboardSidebar(
            isOpen: true,
            width: 256,
            selectedDestination: AppDestination.library,
            onSelectDestination: (_) {},
            selectionMode: SidebarSelectionMode.personalLibrary,
            personalLibraries: libraries,
            activePersonalLibraryId: 'curated_demo',
            onSelectCollectibleCollection: (_) {},
            onAddPersonalLibrary: () {},
            onSelectPersonalLibrary: (id) => selectedId = id,
            onEditPersonalLibrary: (library) => editedLibrary = library,
            onDeletePersonalLibrary: (id) => deletedId = id,
          ),
        ),
      ),
    );

    expect(find.text('인생 명작'), findsOneWidget);
    expect(find.text('1 작품'), findsOneWidget);

    await tester.tap(find.text('인생 명작'));
    expect(selectedId, 'curated_demo');

    await tester.tap(find.text('전체 아카이브').first);
    expect(selectedId, PersonalLibraryConfig.masterArchiveId);

    final activeTitle = tester.widget<Text>(find.text('인생 명작'));
    expect(activeTitle.style?.fontWeight, FontWeight.w600);

    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await tester.pumpAndSettle();

    expect(find.text('편집'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);

    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();
    expect(editedLibrary?.id, 'curated_demo');

    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(deletedId, 'curated_demo');
  });

  testWidgets('DashboardSidebar curated library rows accept work drops', (
    tester,
  ) async {
    String? droppedLibraryId;
    String? droppedWorkId;

    final libraries = [
      PersonalLibraryConfig(
        id: PersonalLibraryConfig.masterArchiveId,
        name: 'master_archive',
      ),
      PersonalLibraryConfig(
        id: 'curated_demo',
        name: '러브코미디',
        mode: PersonalLibraryMode.curated,
      ),
      PersonalLibraryConfig(id: 'filter_demo', name: '필터 서재'),
    ];
    final item = createItem(
      workId: 'wk_drag_demo',
      title: '드래그 테스트',
      category: MediaCategory.manga,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AkashaTheme.dark(),
        home: Scaffold(
          body: DashboardSidebar(
            isOpen: true,
            width: 256,
            selectedDestination: AppDestination.library,
            onSelectDestination: (_) {},
            selectionMode: SidebarSelectionMode.personalLibrary,
            personalLibraries: libraries,
            activePersonalLibraryId: PersonalLibraryConfig.masterArchiveId,
            onSelectCollectibleCollection: (_) {},
            onAddPersonalLibrary: () {},
            onSelectPersonalLibrary: (_) {},
            onDropWorkToLibrary: (libraryId, payload) async {
              droppedLibraryId = libraryId;
              droppedWorkId = payload.workId;
            },
          ),
        ),
      ),
    );

    expect(find.byType(PersonalLibraryDropTarget), findsOneWidget);

    final target = tester.widget<PersonalLibraryDropTarget>(
      find.byType(PersonalLibraryDropTarget),
    );
    target.onAccept(WorkDragPayload(workId: item.workId, item: item));

    expect(droppedLibraryId, 'curated_demo');
    expect(droppedWorkId, 'wk_drag_demo');
  });
}
