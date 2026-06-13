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

  Stream<void> get onVaultUpdated;
  Map<String, AkashaItem> get inMemoryCache;
}
