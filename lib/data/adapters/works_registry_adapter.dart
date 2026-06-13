import '../../core/ports/registry_port.dart';
import '../../models/enums.dart';
import '../../services/works_registry.dart';

class WorksRegistryAdapter implements RegistryPort {
  static final WorksRegistryAdapter _instance = WorksRegistryAdapter._internal();
  factory WorksRegistryAdapter() => _instance;
  WorksRegistryAdapter._internal();

  @override
  Future<void> init() => WorksRegistry.init();

  @override
  RegistryWork? getWorkById(String workId) => WorksRegistry.getWorkById(workId);

  @override
  List<RegistryWork> get allWorks => WorksRegistry.allWorks;

  @override
  Future<List<RegistryWork>> searchAsync(String query) => WorksRegistry.searchAsync(query);

  @override
  Future<List<RegistryWork>> getFilteredWorks({
    AppDomain? domain,
    MediaCategory? category,
  }) => WorksRegistry.getFilteredWorks(domain: domain, category: category);

  @override
  List<RegistryWork> getFilteredWorksSync({
    AppDomain? domain,
    MediaCategory? category,
  }) => WorksRegistry.getFilteredWorksSync(domain: domain, category: category);

  @override
  String resolveWorkId(String workId) => WorksRegistry.resolveWorkId(workId);

  @override
  bool setContainsWorkId(Set<String> ids, String workId) =>
      WorksRegistry.setContainsWorkId(ids, workId);
}
