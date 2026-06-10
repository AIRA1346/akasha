/// 글로벌 사전(Tier 1) vs 유저 볼트(Tier 2) 포스터 정책.
///
/// v1 Steam: AKASHA는 Tier 1에 이미지 URL을 제공·표시하지 않는다.
/// 포스터는 유저 Sanctum vault (`posters/` 또는 YAML `poster:`)만.
class CatalogPosterPolicy {
  CatalogPosterPolicy._();

  /// false — [WorksRegistry.resolvePosterPath]는 항상 null.
  static const bool tier1RegistryPostersEnabled = false;
}
