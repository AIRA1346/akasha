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

  Future<void> removeWork(String libraryId, String workId) async {
    final lib = _libraryById(libraryId);
    if (lib == null || !lib.isCurated || workId.isEmpty) return;

    lib.memberOrder = lib.memberOrder
        .where((id) => !WorksRegistry.setContainsWorkId({workId}, id))
        .toList();
    await _controller.save();
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
