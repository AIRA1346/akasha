import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_log.dart';
import 'registry_cache_contract.dart';

typedef RegistryDocumentsDirectoryProvider = Future<Directory> Function();
typedef RegistryPreferencesProvider = Future<SharedPreferences> Function();

class RegistryBundleOnlyMigrationResult {
  const RegistryBundleOnlyMigrationResult({
    required this.completed,
    required this.alreadyCompleted,
    required this.removedPaths,
  });

  final bool completed;
  final bool alreadyCompleted;
  final List<String> removedPaths;
}

/// One-time invalidation of registry-owned remote state.
///
/// The migration accepts only the application documents directory and never
/// receives or resolves a user Vault path.
class RegistryBundleOnlyMigration {
  RegistryBundleOnlyMigration({
    RegistryDocumentsDirectoryProvider? documentsDirectoryProvider,
    RegistryPreferencesProvider? preferencesProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ??
           (() => getApplicationDocumentsDirectory()),
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  final RegistryDocumentsDirectoryProvider _documentsDirectoryProvider;
  final RegistryPreferencesProvider _preferencesProvider;

  Future<RegistryBundleOnlyMigrationResult> run() async {
    final removedPaths = <String>[];
    try {
      final preferences = await _preferencesProvider();
      if (preferences.getBool(
            RegistryCacheContract.bundleOnlyMigrationPreferenceKey,
          ) ==
          true) {
        return const RegistryBundleOnlyMigrationResult(
          completed: true,
          alreadyCompleted: true,
          removedPaths: [],
        );
      }
      final documents = await _documentsDirectoryProvider();
      final cacheDirectory = Directory(
        p.join(documents.path, RegistryCacheContract.cacheDirectoryName),
      );
      final legacyRegistry = File(
        p.join(documents.path, RegistryCacheContract.legacyRegistryFileName),
      );

      if (await cacheDirectory.exists()) {
        await cacheDirectory.delete(recursive: true);
        removedPaths.add(cacheDirectory.path);
      }
      if (await legacyRegistry.exists()) {
        await legacyRegistry.delete();
        removedPaths.add(legacyRegistry.path);
      }

      await preferences.remove(RegistryCacheContract.lastSyncPreferenceKey);
      await preferences.remove(RegistryCacheContract.customDbUrlPreferenceKey);
      final saved = await preferences.setBool(
        RegistryCacheContract.bundleOnlyMigrationPreferenceKey,
        true,
      );
      if (!saved) {
        throw StateError('failed to persist bundle-only migration flag');
      }

      return RegistryBundleOnlyMigrationResult(
        completed: true,
        alreadyCompleted: false,
        removedPaths: List.unmodifiable(removedPaths),
      );
    } catch (error) {
      appLog('[RegistryBundleOnlyMigration] retry on next start: $error');
      return RegistryBundleOnlyMigrationResult(
        completed: false,
        alreadyCompleted: false,
        removedPaths: List.unmodifiable(removedPaths),
      );
    }
  }
}
