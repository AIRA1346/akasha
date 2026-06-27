import '../../core/ports/vault_port.dart';
import '../../models/akasha_item.dart';
import '../../services/file_service.dart';

class MarkdownVaultAdapter implements VaultPort {
  static final MarkdownVaultAdapter _instance = MarkdownVaultAdapter._internal();
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
  bool isArchivedInVault(AkashaItem item) => _fileService.isArchivedInVault(item);

  @override
  Future<List<AkashaItem>> loadAllItems() => _fileService.loadAllItems();

  @override
  Future<int> countMarkdownFiles() => _fileService.countMarkdownFiles();

  @override
  Future<void> saveItem(AkashaItem item, {String? oldTitle}) =>
      _fileService.saveItem(item, oldTitle: oldTitle);

  @override
  Future<void> deleteItem(AkashaItem item) async {
    await _fileService.deleteAkashaItem(item);
  }

  @override
  Future<String?> importPosterImage(String sourceFilePath) =>
      _fileService.importPosterImage(sourceFilePath);

  @override
  Stream<void> get onVaultUpdated => _fileService.onVaultUpdated;

  @override
  Map<String, AkashaItem> get inMemoryCache => _fileService.inMemoryCache;
}
