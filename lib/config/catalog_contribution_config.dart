/// 글로벌 사전(akasha-db) 기여 — GitHub·export 설정
class CatalogContributionConfig {
  static const String dbRepoOwner = 'AIRA1346';
  static const String dbRepoName = 'akasha-db';
  static const String dbRepoFull = '$dbRepoOwner/$dbRepoName';

  static const String newIssueUrl =
      'https://github.com/$dbRepoFull/issues/new';

  /// v2: per-contribution `status` 필드 필수
  static const int bundleVersion = 2;

  /// CDN — 앱이 제안 상태를 읽을 때 (GitHub raw → Cloudflare)
  static const String statusIndexPath = 'contributions/status.json';

  /// 제안은 akasha-db에 자동 반영되지 않음 (검수 후 merge)
  static const String disclaimerKo =
      '제안은 로컬에 저장됩니다. 글로벌 사전 반영은 운영자 검수·akasha-db merge 후 '
      '앱 동기화로 이루어집니다.';
}
