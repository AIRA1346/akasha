import 'user_catalog_entity.dart';

/// Wave 4 — catalog Entity 추가 결과 (optional entity journal).
class CatalogEntityAddResult {
  const CatalogEntityAddResult({
    required this.entity,
    this.createJournal = false,
    this.journalBody = '',
  });

  final UserCatalogEntity entity;
  final bool createJournal;
  final String journalBody;
}
