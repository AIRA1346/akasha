import '../models/personal_library_config.dart';
import '../screens/home/home_personal_library_controller.dart';
import 'works_registry.dart';

/// curated 서재 멤버십 (`memberOrder`) 변경
class PersonalLibraryMembershipService {
  PersonalLibraryMembershipService(this._controller);

  final HomePersonalLibraryController _controller;

  List<PersonalLibraryConfig> get curatedLibraries => _controller.libraries
      .where((l) => l.isCurated && l.id != PersonalLibraryConfig.masterArchiveId)
      .toList();

  bool containsWork(PersonalLibraryConfig library, String workId) {
    if (!library.isCurated || workId.isEmpty) return false;
    return WorksRegistry.setContainsWorkId(library.memberWorkIds, workId);
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

    final resolved = WorksRegistry.resolveWorkId(workId);
    final stored = resolved.isNotEmpty ? resolved : workId;
    lib.memberOrder = [...lib.memberOrder, stored];
    await _controller.save();
  }

  /// 보이는 카드 순서 변경 — 필터로 숨긴 id는 `memberOrder`에 유지
  static List<String> reorderVisibleInOrder({
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
      if (WorksRegistry.setContainsWorkId(visibleSet, id)) {
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
        .where((id) => !WorksRegistry.setContainsWorkId({workId}, id))
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
        .where((id) => WorksRegistry.setContainsWorkId(archivedWorkIds, id))
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
