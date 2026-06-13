import '../core/ports/registry_port.dart';
import '../models/personal_library_config.dart';
import '../models/membership_apply_result.dart';
import '../screens/home/home_personal_library_controller.dart';

/// curated 서재 멤버십 (`memberOrder`) 변경
class PersonalLibraryMembershipService {
  PersonalLibraryMembershipService(this._controller, this._registryPort);

  final HomePersonalLibraryController _controller;
  final RegistryPort _registryPort;

  List<PersonalLibraryConfig> get curatedLibraries => _controller.libraries
      .where((l) => l.isCurated && l.id != PersonalLibraryConfig.masterArchiveId)
      .toList();

  bool containsWork(PersonalLibraryConfig library, String workId) {
    if (!library.isCurated || workId.isEmpty) return false;
    return _registryPort.setContainsWorkId(library.memberWorkIds, workId);
  }

  Set<String> librariesContaining(String workId) {
    final ids = <String>{};
    for (final lib in curatedLibraries) {
      if (containsWork(lib, workId)) ids.add(lib.id);
    }
    return ids;
  }

  Future<void> addWork(String libraryId, String workId) async {
    final lib = _libraryById(libraryId);
    if (lib == null || !lib.isCurated || workId.isEmpty) return;
    if (containsWork(lib, workId)) return;

    final resolved = _registryPort.resolveWorkId(workId);
    final stored = resolved.isNotEmpty ? resolved : workId;
    lib.memberOrder = [...lib.memberOrder, stored];
    await _controller.save();
  }

  /// 보이는 카드 순서 변경 — 필터로 숨긴 id는 `memberOrder`에 유지
  List<String> reorderVisibleInOrder({
    required List<String> fullOrder,
    required List<String> visibleWorkIds,
    required int oldIndex,
    required int newIndex,
  }) {
    if (visibleWorkIds.isEmpty) return fullOrder;
    final reordered = List<String>.from(visibleWorkIds);
    final moved = reordered.removeAt(oldIndex);
    final insertAt = newIndex.clamp(0, reordered.length);
    reordered.insert(insertAt, moved);

    final visibleSet = visibleWorkIds.toSet();
    final result = <String>[];
    var vi = 0;
    for (final id in fullOrder) {
      if (_registryPort.setContainsWorkId(visibleSet, id)) {
        if (vi < reordered.length) {
          result.add(reordered[vi++]);
        }
      } else {
        result.add(id);
      }
    }
    return PersonalLibraryConfig.normalizeMemberOrder(result);
  }

  Future<void> setMemberOrder(String libraryId, List<String> order) async {
    final lib = _libraryById(libraryId);
    if (lib == null || !lib.isCurated) return;
    lib.memberOrder = PersonalLibraryConfig.normalizeMemberOrder(order);
    await _controller.save();
  }

  Future<void> removeWork(String libraryId, String workId) async {
    final lib = _libraryById(libraryId);
    if (lib == null || !lib.isCurated || workId.isEmpty) return;

    lib.memberOrder = lib.memberOrder
        .where((id) => !_registryPort.setContainsWorkId({workId}, id))
        .toList();
    await _controller.save();
  }

  Future<void> addWorks(String libraryId, Iterable<String> workIds) async {
    for (final workId in workIds) {
      await addWork(libraryId, workId);
    }
  }

  Set<String> librariesContainingAll(List<String> workIds) {
    if (workIds.isEmpty) return {};
    var result = librariesContaining(workIds.first);
    for (var i = 1; i < workIds.length; i++) {
      result = result.intersection(librariesContaining(workIds[i]));
    }
    return result;
  }

  int countLibrariesContainingAny(Iterable<String> workIds) {
    final ids = <String>{};
    for (final workId in workIds) {
      ids.addAll(librariesContaining(workId));
    }
    return ids.length;
  }

  int countContainedWorkIds(PersonalLibraryConfig library, List<String> workIds) {
    var n = 0;
    for (final id in workIds) {
      if (containsWork(library, id)) n++;
    }
    return n;
  }

  /// 체크리스트 diff — ON=담기 · OFF=제거 (Case D `workIds` 일괄)
  /// `initialChecked`/`desiredChecked`의 `null` = IP 부분 담김(indeterminate)
  Future<MembershipApplyResult> applyCheckboxDiff({
    required List<String> workIds,
    required Map<String, bool?> desiredChecked,
    required Map<String, bool?> initialChecked,
  }) async {
    if (workIds.isEmpty) {
      return const MembershipApplyResult();
    }

    final addedNames = <String>[];
    final removedNames = <String>[];

    for (final lib in curatedLibraries) {
      final want = desiredChecked[lib.id];
      final had = initialChecked[lib.id];
      if (want == had) continue;

      if (want == true) {
        final missing =
            workIds.where((w) => !containsWork(lib, w)).toList(growable: false);
        if (missing.isNotEmpty) {
          await addWorks(lib.id, missing);
          addedNames.add(lib.name);
        }
      } else if (want == false && (had == true || had == null)) {
        var removedAny = false;
        for (final w in workIds) {
          if (containsWork(lib, w)) {
            await removeWork(lib.id, w);
            removedAny = true;
          }
        }
        if (removedAny) removedNames.add(lib.name);
      }
    }

    return MembershipApplyResult(
      addedLibraryCount: addedNames.length,
      removedLibraryCount: removedNames.length,
      addedLibraryNames: addedNames,
      removedLibraryNames: removedNames,
    );
  }

  Future<void> applyMembershipChanges({
    required String workId,
    required Set<String> addToLibraryIds,
    required Set<String> removeFromLibraryIds,
  }) async {
    for (final id in addToLibraryIds) {
      await addWork(id, workId);
    }
    for (final id in removeFromLibraryIds) {
      await removeWork(id, workId);
    }
  }

  Future<void> applyMembershipChangesForWorks({
    required List<String> workIds,
    required Set<String> addToLibraryIds,
    required Set<String> removeFromLibraryIds,
  }) async {
    for (final workId in workIds) {
      await applyMembershipChanges(
        workId: workId,
        addToLibraryIds: addToLibraryIds,
        removeFromLibraryIds: removeFromLibraryIds,
      );
    }
  }

  Future<int> pruneOrphans(
    PersonalLibraryConfig library,
    Set<String> archivedWorkIds,
  ) async {
    if (!library.isCurated) return 0;
    final before = library.memberOrder.length;
    library.memberOrder = library.memberOrder
        .where((id) => _registryPort.setContainsWorkId(archivedWorkIds, id))
        .toList();
    final removed = before - library.memberOrder.length;
    if (removed > 0) await _controller.save();
    return removed;
  }

  PersonalLibraryConfig? _libraryById(String libraryId) {
    for (final lib in _controller.libraries) {
      if (lib.id == libraryId) return lib;
    }
    return null;
  }
}
