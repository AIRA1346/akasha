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

  @override
  int get browsePrefetchWindowSize => WorksRegistry.browsePrefetchWindowSize;

  @override
  int get browseFullCatalogThreshold => WorksRegistry.browseFullCatalogThreshold;

  @override
  Future<void> loadCachedRegistry() => WorksRegistry.loadCachedRegistry();

  @override
  Future<void> prefetchBrowseWindow({
    AppDomain? domain,
    MediaCategory? category,
    int offset = 0,
    int? limit,
    bool fetchRemote = false,
  }) =>
      WorksRegistry.prefetchBrowseWindow(
        domain: domain,
        category: category,
        offset: offset,
        limit: limit ?? WorksRegistry.browsePrefetchWindowSize,
        fetchRemote: fetchRemote,
      );

  @override
  Future<void> prefetchForFilters({
    AppDomain? domain,
    Set<MediaCategory>? categories,
  }) =>
      WorksRegistry.prefetchForFilters(domain: domain, categories: categories);

  @override
  int catalogIndexEntryCount({
    AppDomain? domain,
    MediaCategory? category,
  }) =>
      WorksRegistry.catalogIndexEntryCount(domain: domain, category: category);

  @override
  Future<void> clearDiskCacheAndReloadBundle() =>
      WorksRegistry.clearDiskCacheAndReloadBundle();
}
