import '../core/archiving/entity_anchor.dart';
import '../services/entity_archive_service.dart';
import 'user_catalog_entity.dart';

/// Entity 추가 결과 — Archive-First R1 (journal 기본 · nameOnly 예외).
class CatalogEntityAddResult {
  const CatalogEntityAddResult({
    required this.entity,
    this.nameOnly = false,
    this.journalBody = '',
  });

  final UserCatalogEntity entity;
  /// 고급: catalog-only (journal 없음) — 기본 flow ❌.
  final bool nameOnly;
  final String journalBody;

  bool get createsJournal =>
      !nameOnly && EntityArchiveService.usesArchiveFirstFlow(entity.anchorType);
}
