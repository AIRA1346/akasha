import 'dart:typed_data';

import '../../core/ports/vault_change.dart';
import '../../core/ports/vault_port.dart';
import '../../models/akasha_item.dart';
import '../../services/file_service.dart';

class MarkdownVaultAdapter implements VaultPort {
  static final MarkdownVaultAdapter _instance =
      MarkdownVaultAdapter._internal();
  factory MarkdownVaultAdapter() => _instance;
  MarkdownVaultAdapter._internal();

  final AkashaFileService _fileService = AkashaFileService();

  @override
  Future<void> init() => _fileService.init();

  @override
  String? get vaultPath => _fileService.vaultPath;

  @override
  Future<void> setVaultPath(String path) => _fileService.setVaultPath(path);

  @override
  Future<bool> isVaultPathValid() => _fileService.isVaultPathValid();

  @override
  bool isArchivedInVault(AkashaItem item) =>
      _fileService.isArchivedInVault(item);

  @override
  Future<List<AkashaItem>> loadAllItems() => _fileService.loadAllItems();

  @override
  Future<int> countMarkdownFiles() => _fileService.countMarkdownFiles();

  @override
  Future<void> saveItem(AkashaItem item, {String? oldTitle}) =>
      _fileService.saveItem(item, oldTitle: oldTitle);

  @override
  Future<bool> deleteItem(AkashaItem item) =>
      _fileService.deleteAkashaItem(item);

  @override
  Future<String?> importPosterImage(String sourceFilePath) =>
      _fileService.importPosterImage(sourceFilePath);

  @override
  Future<String?> importPosterImageFromBytes(
    Uint8List bytes, {
    String extension = 'png',
  }) => _fileService.importPosterImageFromBytes(bytes, extension: extension);

  @override
  Future<String?> importPosterImageBytesDeduped(
    Uint8List bytes, {
    required String extension,
  }) => _fileService.importPosterImageBytesDeduped(bytes, extension: extension);

  @override
  Future<void> signalVaultChanged() => _fileService.signalVaultChanged();

  @override
  Future<void> signalVaultChange(VaultChangeBatch change) =>
      _fileService.signalVaultChange(change);

  @override
  Stream<void> get onVaultUpdated => _fileService.onVaultUpdated;

  @override
  Stream<VaultChangeBatch> get onVaultChanges => _fileService.onVaultChanges;

  @override
  Map<String, AkashaItem> get inMemoryCache => _fileService.inMemoryCache;
}
