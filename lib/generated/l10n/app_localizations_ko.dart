// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get browseLoadingCatalog => '글로벌 작품 사전 불러오는 중…';

  @override
  String get browseNoResults => '조건에 맞는 작품이 없습니다.';

  @override
  String browseCatalogIndexed(int loaded, int total) {
    return '글로벌 사전 $loaded / $total 작품 색인 로드됨';
  }

  @override
  String browseLoadMore(int count) {
    return '더 불러오기 (+$count)';
  }

  @override
  String get settingsDisplayLanguage => '표시 언어';

  @override
  String get localeKo => '한국어';

  @override
  String get localeEn => 'English';

  @override
  String get appPreferencesTitle => '환경설정';

  @override
  String get appPreferencesDisplayScale => '표시 배율';

  @override
  String get appPreferencesResetScale => '100%로 재설정';

  @override
  String get appPreferencesScaleHelp => '앱 전체 글자와 주요 컨트롤 크기를 조정합니다.';

  @override
  String get appPreferencesThemeTitle => '앱 테마';

  @override
  String get appPreferencesThemeSubtitle => '색상 팔레트를 바꿉니다.';

  @override
  String get appPreferencesVaultTitle => '볼트 설정';

  @override
  String get appPreferencesVaultSubtitle => '저장 폴더, 백업, 휴지통을 관리합니다.';

  @override
  String get appPreferencesQuit => '종료';

  @override
  String get appPreferencesClose => '닫기';

  @override
  String get appBarToggleSidebar => '사이드바 토글 (Tab)';

  @override
  String get appBarLibraryTheme => '앱 테마';

  @override
  String get appBarSearch => '검색';

  @override
  String get appBarTimelineCapture => '타임라인 기록';

  @override
  String get appBarCatalogInbox => '카탈로그 제안함';

  @override
  String get appBarClipboardImport => 'AI 마크다운 가져오기';

  @override
  String get appBarSyncRegistry => '글로벌 작품 사전 동기화 (길게 눌러 설정)';

  @override
  String get appBarPromptTemplates => 'AI 프롬프트 템플릿 복사';

  @override
  String get appBarClearRegistryCache => '글로벌 사전 JSON 캐시 삭제 (이미지 파일 아님)';

  @override
  String get appBarVaultSettings => '로컬 폴더(Vault) 설정';

  @override
  String get sidebarHome => '홈';

  @override
  String get sidebarExplore => '탐색';

  @override
  String get sidebarLibrary => '라이브러리';

  @override
  String get sidebarCollections => '컬렉션';

  @override
  String get sidebarGraph => '그래프';

  @override
  String get sidebarTimeline => '타임라인';

  @override
  String get sidebarMyLibraries => '나만의 서재';

  @override
  String get sidebarCreateMyLibraryPrompt => '나만의 서재를 만들어 보세요';

  @override
  String get libraryMasterArchive => '전체 아카이브';

  @override
  String get libraryCurated => '큐레이션 서재';

  @override
  String get libraryFiltered => '필터 서재';

  @override
  String libraryWorkCount(int count) {
    return '$count 작품';
  }

  @override
  String get itemKindWork => '작품';

  @override
  String get sidebarRecentExplore => '최근 탐색';

  @override
  String get sidebarMyCollections => '내 컬렉션';

  @override
  String get sidebarViewAll => '모두 보기';

  @override
  String get sidebarNoCollections => '컬렉션이 없습니다';

  @override
  String get searchPlaceholder => '작품, 인물, 시간, 장소, 개념을 검색하세요...';

  @override
  String get filterTooltip => '필터';

  @override
  String get filterCloseTooltip => '필터 닫기';

  @override
  String get appBarSyncUrlSettings => '사전 동기화 URL 설정';

  @override
  String get appBarMoreToolsTooltip => '도구 더보기';

  @override
  String get previewDetails => '상세 정보';

  @override
  String get previewCoreInfo => '핵심 정보';

  @override
  String get previewMyNotes => '내 감상';

  @override
  String get previewMainCast => '주요 인물';

  @override
  String get previewRelatedConcepts => '관련 개념';

  @override
  String get previewExploreNext => '다음으로 탐험할 연결';

  @override
  String get previewViewInCatalog => '사전에서 더 보기';

  @override
  String get previewAddPerson => '인물 추가';

  @override
  String get previewAddConcept => '개념 추가';

  @override
  String get previewNoRating => '평가 없음';

  @override
  String get previewInfoNone => '정보 없음';

  @override
  String get previewGenre => '장르';

  @override
  String get previewAuthor => '원작';

  @override
  String get previewStudio => '제작사';

  @override
  String get previewType => '유형';

  @override
  String get previewAliases => '별칭';

  @override
  String get previewDomain => '도메인';

  @override
  String get previewTags => '태그';

  @override
  String get previewRating => '평점';

  @override
  String get previewViewInGraph => '그래프에서 보기';

  @override
  String catalogPrefix(String category) {
    return '사전 · $category';
  }

  @override
  String relatedRegistryWorks(String title) {
    return '$title 관련 사전 작품';
  }

  @override
  String creatorWorks(String creator) {
    return '$creator 작품';
  }

  @override
  String bridgeRelated(String bridge) {
    return '$bridge 관련';
  }

  @override
  String get entityTypeWork => '작품';

  @override
  String get entityTypePerson => '인물';

  @override
  String get entityTypeConcept => '개념';

  @override
  String get entityTypeEvent => '사건';

  @override
  String get entityTypePlace => '장소';

  @override
  String get entityTypeOrganization => '조직';

  @override
  String get entityTypeCustom => '사용자';

  @override
  String get entityTypePhenomenon => '레거시';

  @override
  String get actionRecord => '기록하기';

  @override
  String get vaultSettingsTitle => '로컬 볼트(Vault) 설정';

  @override
  String vaultPathLinked(String path) {
    return '현재 연동된 폴더:\n$path';
  }

  @override
  String get vaultPathNotLinked =>
      '연동된 폴더가 없습니다. 마크다운 파일로 영속적으로 기록하려면 Sanctum Vault 폴더를 연동해 주세요.';

  @override
  String vaultStatusLinked(int count) {
    return '상태: 연동됨 · 아카이브 .md $count개';
  }

  @override
  String get vaultStatusPathNotFound => '상태: 경로를 찾을 수 없음 (다시 연동해 주세요)';

  @override
  String vaultBackupSuccess(String archiveName, int fileCount) {
    return '볼트 백업을 저장했습니다: $archiveName ($fileCount files)';
  }

  @override
  String vaultBackupFailed(String error) {
    return '볼트 백업 실패: $error';
  }

  @override
  String get vaultBackupExport => '볼트 ZIP 백업 내보내기';

  @override
  String get vaultViewTrash => 'Vault 휴지통 보기';

  @override
  String get vaultArchivingNotice =>
      '※ manga, game, animation 등 카테고리 폴더에 .md가 생성됩니다. work_id는 YAML에 기록됩니다.';

  @override
  String get vaultAutoArchiveRegistry => '사전 작품 자동 아카이빙';

  @override
  String get vaultAutoArchiveRegistryHelp =>
      '켜면 현재 필터 범위의 사전 작품을 .md로 자동 생성합니다. (기본: 끔)';

  @override
  String get vaultAutoArchiveRegistryRunNow => '지금 사전 작품 아카이빙 실행';

  @override
  String vaultHiddenRegistryManage(int count) {
    return '숨긴 사전 항목 관리 ($count)';
  }

  @override
  String get vaultDisplayNameLabel => '표시 이름 (워치리스트 등)';

  @override
  String get vaultDisplayNameDefault => '사용자';

  @override
  String get vaultDisconnect => '연동 해제';

  @override
  String get vaultSaveName => '이름 저장';

  @override
  String get vaultChangeFolder => '폴더 변경';

  @override
  String get vaultLinkFolder => '폴더 연동';

  @override
  String get trashRestoredSuccess => '휴지통에서 복구했습니다.';

  @override
  String get trashRestoredFailedFileExists => '원래 위치에 파일이 있어 복구하지 못했습니다.';

  @override
  String get trashRestore => '복구';

  @override
  String get trashDeletePermanently => '영구 삭제';

  @override
  String trashDeleteConfirm(String fileName) {
    return '「$fileName」을(를) 휴지통에서도 삭제할까요?\n이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get actionCancel => '취소';

  @override
  String get trashDeletedSuccess => '휴지통에서 영구 삭제했습니다.';

  @override
  String get trashDeleteFailedNotFound => '삭제할 파일을 찾지 못했습니다.';

  @override
  String get vaultTrashTitle => 'Vault 휴지통';

  @override
  String get trashEmpty => '휴지통이 비어 있습니다.';

  @override
  String get trashRefresh => '새로고침';

  @override
  String trashDeletedTime(String time) {
    return '삭제됨 $time';
  }

  @override
  String get validationInputName => '이름을 입력해 주세요.';

  @override
  String archiveTitle(String type) {
    return '$type 아카이브';
  }

  @override
  String archiveNameLabel(String type) {
    return '$type 이름';
  }

  @override
  String get archiveAliasesLabel => '별칭 (쉼표로 구분, 선택)';

  @override
  String get archiveAliasesHint => '호랑이, 백호';

  @override
  String get archiveTagsLabel => '태그 (감상 축 · semantic)';

  @override
  String get archiveMemoLabel => '메모 (선택)';

  @override
  String get archiveNameOnly => '이름만 등록 (고급)';

  @override
  String get archiveNameOnlyHelp => 'journal 없이 링크용 ID만 — 기본 아카이브 flow 아님';

  @override
  String get archiveAdd => '아카이브에 추가';

  @override
  String get actionAdd => '추가';

  @override
  String get archiveChooseType => '추가할 대상 유형';

  @override
  String get archiveDescWork => '볼트에 .md 아카이브';

  @override
  String archiveDescEntity(String type) {
    return 'entities/$type/*.md 아카이브';
  }

  @override
  String get validationSpecifyTagOrWork => '태그 또는 작품을 하나 이상 지정해 주세요.';

  @override
  String get actionSave => '저장';

  @override
  String get proposalSaved => '글로벌 사전 추가 제안이 저장되었습니다. (제안함에서 export)';

  @override
  String get validationLinkVaultFirst => '볼트를 먼저 연결해 주세요.';

  @override
  String get draftRecoveryAvailable => '임시 저장본이 있습니다.';

  @override
  String journalDeleted(String title) {
    return '「$title」 journal을 삭제했습니다.';
  }

  @override
  String get journalSaveBeforeHtml => 'HTML보내기 전에 journal을 저장해 주세요.';

  @override
  String vaultFileDeleted(String title) {
    return '\"$title\" md 파일을 삭제했습니다.';
  }

  @override
  String get statusSaving => '저장 중…';

  @override
  String get statusUnsaved => '● 미저장';

  @override
  String statusSavedText(String time) {
    return '저장됨 $time';
  }

  @override
  String statusDirtyHint(String saveLabel) {
    return '변경됨 · 자동 저장은 편집 화면에 유지 · 탐험 복귀는 「$saveLabel」';
  }

  @override
  String statusSavedHint(String time, String saveLabel) {
    return '저장됨 $time · 자동 저장 · 탐험 복귀는 「$saveLabel」';
  }

  @override
  String statusReturnHint(String saveLabel) {
    return '「$saveLabel」하면 탐험 화면(Preview)으로 돌아갑니다';
  }

  @override
  String get actionSaveMd => 'md 저장';
}
