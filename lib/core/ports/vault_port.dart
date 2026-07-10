import 'dart:typed_data';

import '../../models/akasha_item.dart';
import 'vault_change.dart';

abstract class VaultPort {
  Future<void> init();

  String? get vaultPath;
  Future<void> setVaultPath(String path);
  Future<bool> isVaultPathValid();

  bool isArchivedInVault(AkashaItem item);
  Future<List<AkashaItem>> loadAllItems();
  Future<int> countMarkdownFiles();

  Future<void> saveItem(AkashaItem item, {String? oldTitle});
  Future<bool> deleteItem(AkashaItem item);

  /// Copies a local image into the vault assets tree; returns vault-relative path.
  Future<String?> importPosterImage(String sourceFilePath);

  /// Copies in-memory image bytes into the vault assets tree.
  Future<String?> importPosterImageFromBytes(
    Uint8List bytes, {
    String extension = 'png',
  });

  /// Saves image bytes under posters/ using a content hash filename (dedupe).
  Future<String?> importPosterImageBytesDeduped(
    Uint8List bytes, {
    required String extension,
  });

  /// Notifies listeners that vault contents changed outside [saveItem]/[deleteItem].
  Future<void> signalVaultChanged();

  /// Publishes a precise source-path change when the writer knows it.
  ///
  /// The existing [onVaultUpdated] stream remains available for UI consumers
  /// that only need a broad refresh. New index/query consumers should prefer
  /// [onVaultChanges] so they can avoid a whole-Vault reload.
  Future<void> signalVaultChange(VaultChangeBatch change);

  Stream<void> get onVaultUpdated;
  Stream<VaultChangeBatch> get onVaultChanges;
  Map<String, AkashaItem> get inMemoryCache;
}
