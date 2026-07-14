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

  /// Lightweight aggregate facts for read-only dashboard surfaces.
  ///
  /// Implementations must use the existing derived index and must not trigger
  /// a vault-wide repair scan from this read path.
  Future<RecordLinkSummary> loadSummary();
}

class RecordLinkSummary {
  const RecordLinkSummary({
    required this.totalLinkCount,
    required this.linkedRecordCount,
    required this.connectedEntityCount,
  });

  static const empty = RecordLinkSummary(
    totalLinkCount: 0,
    linkedRecordCount: 0,
    connectedEntityCount: 0,
  );

  final int totalLinkCount;
  final int linkedRecordCount;
  final int connectedEntityCount;

  bool get isEmpty => totalLinkCount == 0;
}
