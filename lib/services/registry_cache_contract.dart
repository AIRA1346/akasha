abstract final class RegistryCacheContract {
  static const cacheDirectoryName = 'registry_cache';
  static const legacyRegistryFileName = 'local_works_registry.json';
  static const lastSyncPreferenceKey = 'akasha_last_sync_time';
  static const customDbUrlPreferenceKey = 'akasha_custom_db_url';
  static const bundleOnlyMigrationPreferenceKey =
      'registry_bundle_only_migration_v1';
}
