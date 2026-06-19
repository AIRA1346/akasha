import '../archiving/record_link.dart';

/// Wave 5 — vault link index read/write.
abstract interface class RecordLinkPort {
  Future<void> rebuildIndex({String? changedPath});

  Future<List<RecordLink>> outgoingLinks(String sourcePath);

  Future<List<String>> incomingRecordPaths(String entityId);
}
