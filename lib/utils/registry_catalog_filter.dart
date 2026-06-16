import '../models/registry_work.dart';

/// A5 Scale maintainer probe — 사용자 카탈로그·검색에서 제외.
bool isMaintainerCatalogProbe(RegistryWork work) {
  final id = work.workId;
  if (id.contains('scale-supply') || id.contains('scale-exp')) {
    return true;
  }
  final tags = work.tags;
  return tags.contains('scale') && tags.contains('expansion');
}
