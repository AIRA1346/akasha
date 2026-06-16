import '../config/catalog_locale.dart';
import '../models/akasha_item.dart';
import '../services/works_registry.dart';

/// 카탈로그·그리드용 표시 제목.
///
/// `workId`가 사전에 있으면 [CatalogLocaleScope] 기준 registry 제목을 쓰고,
/// 없거나 미로드 shard면 [AkashaItem.title](사용자 볼트 편집명)으로 fallback.
String resolveCatalogDisplayTitle(
  AkashaItem item, {
  CatalogLocale? locale,
}) {
  final workId = item.workId.trim();
  if (workId.isEmpty) return item.title;

  final work = WorksRegistry.getWorkById(workId);
  if (work == null) return item.title;

  return work.displayTitle(locale);
}
