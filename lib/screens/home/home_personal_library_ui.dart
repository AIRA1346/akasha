import 'package:flutter/material.dart';

import '../../models/akasha_item.dart';
import '../../models/personal_library_config.dart';
import 'coordinators/home_filter_coordinator.dart';
import 'dialogs/delete_personal_library_confirm_dialog.dart';
import 'dialogs/personal_library_edit_dialog.dart';
import 'home_personal_library_controller.dart';
import 'home_section_preferences.dart';

/// 나만의 서재 편집·삭제 Presentation glue.
class HomePersonalLibraryUi {
  const HomePersonalLibraryUi({
    required this.personalLibCtrl,
    required this.filterCoordinator,
    required this.sectionPrefs,
  });

  final HomePersonalLibraryController personalLibCtrl;
  final HomeFilterCoordinator filterCoordinator;
  final HomeSectionPreferences sectionPrefs;

  Future<void> confirmDelete(
    BuildContext context, {
    required String id,
    required void Function(void Function()) setState,
  }) async {
    if (id == PersonalLibraryConfig.masterArchiveId) return;
    PersonalLibraryConfig? library;
    for (final lib in personalLibCtrl.libraries) {
      if (lib.id == id) {
        library = lib;
        break;
      }
    }
    final confirmed = await showDeletePersonalLibraryConfirmDialog(
      context,
      libraryName: library?.name ?? id,
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => personalLibCtrl.remove(id));
    await personalLibCtrl.save();
  }

  Future<void> showEditDialog(
    BuildContext context, {
    required PersonalLibraryConfig config,
    required List<AkashaItem> vaultItems,
    required bool canAddToLibrary,
    required Future<void> Function() onAddWorks,
    required void Function(void Function()) setState,
  }) async {
    final memberOrderBefore = config.isCurated
        ? List<String>.from(config.memberOrder)
        : const <String>[];
    final updated = await showPersonalLibraryEditDialog(
      context,
      config: config,
      vaultItems: vaultItems,
      onAddWorks: config.isCurated && canAddToLibrary ? onAddWorks : null,
    );
    if (updated == null || !context.mounted) return;
    setState(() {
      if (personalLibCtrl.activeLibraryId == updated.id) {
        filterCoordinator.applyPersonalLibraryFilterSnapshot(updated);
      }
    });
    await personalLibCtrl.save();

    final memberOrderChanged =
        memberOrderBefore.length != updated.memberOrder.length ||
        !_memberOrderListsEqual(memberOrderBefore, updated.memberOrder);
    if (updated.isCurated &&
        !sectionPrefs.librarySort.isManualOrder &&
        memberOrderChanged) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('멤버 구성이 바뀌었습니다. 정렬을 수동 순서로 바꿀 수 있습니다.')),
      );
    }
  }

  bool _memberOrderListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
