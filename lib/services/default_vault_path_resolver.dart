import 'package:path_provider/path_provider.dart';

/// Vault Quick Start path resolver helper.
///
/// Encapsulates platform path provider calls to allow mocking in tests.
class DefaultVaultPathResolver {
  const DefaultVaultPathResolver();

  /// Resolves the preferred path for the default vault (usually documents).
  Future<String> resolvePreferredPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Resolves the fallback path for the default vault if the preferred path is unwriteable.
  Future<String> resolveFallbackPath() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }
}
