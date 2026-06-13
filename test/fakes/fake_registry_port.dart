import 'package:akasha/core/ports/registry_port.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/works_registry.dart';

class FakeRegistryPort implements RegistryPort {
  final List<RegistryWork> _works = [];

  void addWork(RegistryWork work) {
    _works.add(work);
  }

  @override
  Future<void> init() async {}

  @override
  RegistryWork? getWorkById(String workId) {
    for (final w in _works) {
      if (w.workId == workId) return w;
    }
    return null;
  }

  @override
  List<RegistryWork> get allWorks => _works;

  @override
  Future<List<RegistryWork>> searchAsync(String query) async {
    return _works
        .where((w) => w.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<RegistryWork>> getFilteredWorks({
    AppDomain? domain,
    MediaCategory? category,
  }) async {
    return _works.where((w) {
      if (domain != null && w.domain != domain) return false;
      if (category != null && w.category != category) return false;
      return true;
    }).toList();
  }

  @override
  List<RegistryWork> getFilteredWorksSync({
    AppDomain? domain,
    MediaCategory? category,
  }) {
    return _works.where((w) {
      if (domain != null && w.domain != domain) return false;
      if (category != null && w.category != category) return false;
      return true;
    }).toList();
  }

  @override
  String resolveWorkId(String workId) => workId;

  @override
  bool setContainsWorkId(Set<String> ids, String workId) {
    return ids.contains(workId);
  }
}
