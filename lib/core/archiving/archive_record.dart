import 'entity_anchor.dart';
import 'record_kind.dart';
import 'record_link.dart';
import 'vault_file_revision.dart';

/// 사용자 소유 축적 단위 — ultimate archiving §6 ([ADR-008]).
///
/// [AkashaItem] 및 (Phase 4) Timeline entry의 공통 표현.
class ArchiveRecord {
  ArchiveRecord({
    required this.recordId,
    required this.kind,
    this.entity,
    this.timeAnchor,
    this.storagePath,
    this.title,
    this.links = const [],
    this.openedRevision,
  });

  final String recordId;
  final RecordKind kind;
  final EntityAnchor? entity;
  final DateTime? timeAnchor;
  final String? storagePath;
  final String? title;
  final List<RecordLink> links;
  final VaultFileRevision? openedRevision;

  bool get hasEntityAnchor => entity != null && entity!.entityId.isNotEmpty;

  bool get isWorkJournal => kind == RecordKind.workJournal;

  bool get isTimelineEntry => kind == RecordKind.timelineEntry;
}
