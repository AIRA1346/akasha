import '../../models/enums.dart';
import '../../services/works_registry.dart'; // RegistryWork 임포트

abstract class RegistryPort {
  Future<void> init();
  RegistryWork? getWorkById(String workId);
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
}
