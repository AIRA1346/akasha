import '../archiving/record_link.dart';
import '../../models/akasha_item.dart';
import 'user_catalog_port.dart';

/// Wave 5 — vault link index read/write.
abstract interface class RecordLinkPort {
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  });

  Future<List<RecordLink>> outgoingLinks(String sourcePath);

  Future<List<String>> incomingRecordPaths(String entityId);

  /// Entity ids with at least one incoming record link in the index.
  Future<Iterable<String>> incomingEntityIds();
}
