import '../../models/enums.dart';
import '../../models/registry_work.dart';

abstract class RegistryPort {
  Future<void> init();
  RegistryWork? getWorkById(String workId);
  Future<RegistryWork?> getWorkByIdAsync(String workId);
  List<RegistryWork> get allWorks;
  Future<List<RegistryWork>> searchAsync(String query);
  Future<List<RegistryWork>> getFilteredWorks({
    AppDomain? domain,
    MediaCategory? category,
  });
  List<RegistryWork> getFilteredWorksSync({
    AppDomain? domain,
    MediaCategory? category,
  });
  String resolveWorkId(String workId);
  bool setContainsWorkId(Set<String> ids, String workId);

  int get browsePrefetchWindowSize;
  int get browseFullCatalogThreshold;

  Future<void> prefetchBrowseWindow({
    AppDomain? domain,
    MediaCategory? category,
    int offset = 0,
    int? limit,
  });

  Future<void> prefetchForFilters({
    AppDomain? domain,
    Set<MediaCategory>? categories,
  });

  int catalogIndexEntryCount({AppDomain? domain, MediaCategory? category});
}
