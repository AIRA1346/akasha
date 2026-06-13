import 'package:akasha/models/personal_library_config.dart';

/// Coordinator 테스트용 in-memory personal library 저장소.
class FakeStorageService {
  FakeStorageService([List<PersonalLibraryConfig>? seed])
      : libraries = List<PersonalLibraryConfig>.from(
          seed ?? PersonalLibraryConfig.defaultLibraries(),
        );

  List<PersonalLibraryConfig> libraries;

  Future<List<PersonalLibraryConfig>> load() async {
    return PersonalLibraryConfig.normalizeLibraries(libraries);
  }

  Future<void> save(List<PersonalLibraryConfig> configs) async {
    libraries = PersonalLibraryConfig.normalizeLibraries(configs);
  }
}
