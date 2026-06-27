import '../../models/akasha_item.dart';

abstract class VaultPort {
  Future<void> init();

  String? get vaultPath;
  Future<void> setVaultPath(String path);
  Future<bool> isVaultPathValid();

  bool isArchivedInVault(AkashaItem item);
  Future<List<AkashaItem>> loadAllItems();
  Future<int> countMarkdownFiles();

  Future<void> saveItem(AkashaItem item, {String? oldTitle});
  Future<void> deleteItem(AkashaItem item);

  /// Copies a local image into the vault assets tree; returns vault-relative path.
  Future<String?> importPosterImage(String sourceFilePath);

  Stream<void> get onVaultUpdated;
  Map<String, AkashaItem> get inMemoryCache;
}
