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
  String get appPreferencesCommerceTitle => '상점 및 인벤토리';

  @override
  String get appPreferencesCommerceSubtitle => '테마 패키지를 살펴보고 재화와 소유권을 확인합니다.';

  @override
  String get appPreferencesVaultTitle => '볼트 설정';

  @override
  String get appPreferencesVaultSubtitle => '저장 폴더, 백업, 휴지통을 관리합니다.';

  @override
  String get appPreferencesQuit => '종료';

  @override
  String get appPreferencesClose => '닫기';

  @override
  String get appBarToggleSidebar => '사이드바 토글 (Ctrl+B)';

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
  String get destinationExploreDescription => '사전과 아카이브에서 다음 기록 대상을 찾습니다.';

  @override
  String get destinationLibraryDescription => '볼트에 보관한 기록과 나만의 서재를 살펴봅니다.';

  @override
  String get destinationCollectionsDescription => '작품과 엔티티를 의도적으로 묶은 컬렉션입니다.';

  @override
  String get destinationGraphDescription =>
      '직접 만든 지식 지도와 기록에서 파생된 연결을 함께 살펴봅니다.';

  @override
  String get destinationTimelineDescription =>
      '시간순 기록과 메모, 엔티티 기록, 연결 후보를 한곳에서 관리합니다.';

  @override
  String browseEntityDiscoveryCount(int count) {
    return '엔티티 둘러보기 · $count';
  }

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
  String get previewCatalogWorkTitle => '사전 작품';

  @override
  String get previewCatalogWorkDescription =>
      '아직 내 볼트에 없습니다. 아카이브하면 기록과 연결을 시작할 수 있습니다.';

  @override
  String get previewNoConnectionsTitle => '아직 연결이 없습니다';

  @override
  String get previewWorkNoConnectionsDescription =>
      '작품 기록에 링크를 추가하면 아카이브의 연결로 표시됩니다.';

  @override
  String get previewEntityNoConnectionsDescription =>
      '이 기록에 작품이나 다른 엔티티를 연결할 수 있습니다.';

  @override
  String get previewSuggestedConnections => '추천 연결';

  @override
  String get previewAddConnection => '연결 추가';

  @override
  String previewConnectType(String type) {
    return '$type 연결';
  }

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
  String get entityTypeObject => '물건';

  @override
  String get entityTypeCustom => '사용자';

  @override
  String get entityTypeUnknown => '미지';

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
  String get homeVaultBannerExploringCatalog =>
      '카탈로그로 탐험 중입니다. 기록을 저장하려면 로컬 폴더를 연결하세요.';

  @override
  String get homeVaultBannerConnectExisting => '기존 폴더 연결';

  @override
  String get homeVaultBannerCreateDefault => '기본 아카이브 만들기';

  @override
  String homeVaultCreateFailed(String error) {
    return '기본 아카이브 생성을 완료하지 못했습니다: $error';
  }

  @override
  String get homeVaultCreateDoneTitle => '아카이브 생성 완료';

  @override
  String get homeVaultCreateDoneBody =>
      '이 폴더가 AKASHA의 본체입니다. 앱이 아니라, 이 파일들이 당신의 아카이브입니다.';

  @override
  String homeVaultCreateDonePath(String path) {
    return '생성된 경로:\n$path';
  }

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

  @override
  String get mediaCategoryManga => '만화';

  @override
  String get mediaCategoryWebtoon => '웹툰';

  @override
  String get mediaCategoryAnimation => '애니메이션';

  @override
  String get mediaCategoryGame => '게임';

  @override
  String get mediaCategoryBook => '책/소설/라노벨';

  @override
  String get mediaCategoryMovie => '영화';

  @override
  String get mediaCategoryDrama => '드라마';

  @override
  String get statusContentWorkSerializing => '연재중';

  @override
  String get statusContentWorkHiatus => '휴재중';

  @override
  String get statusContentWorkCompleted => '완결';

  @override
  String get statusContentMyNotStarted => '볼 예정';

  @override
  String get statusContentMyWatching => '보는 중';

  @override
  String get statusContentMyFinished => '전부 봄';

  @override
  String get statusContentMyDropped => '하차함';

  @override
  String get statusGameWorkReleased => '출시됨';

  @override
  String get statusGameWorkEarlyAccess => '얼리액세스';

  @override
  String get statusGameWorkUpcoming => '출시예정';

  @override
  String get statusGameMyBacklog => '볼 예정';

  @override
  String get statusGameMyPlaying => '플레이 중';

  @override
  String get statusGameMyCleared => '클리어(완결)';

  @override
  String get statusGameMyAbandoned => '중도포기(하차)';

  @override
  String get sortCriteriaManual => '직접 배치 순';

  @override
  String get sortCriteriaTitle => '작품/제목명 순';

  @override
  String get sortCriteriaRating => '별점 높은 순';

  @override
  String get sortCriteriaRecentlyAdded => '최근 추가 순';

  @override
  String get sortCriteriaYear => '출시 연도 순';

  @override
  String get addWorkDialogTitle => '새 작품 등록 (아카이브 추가)';

  @override
  String get registryWorkSearch => '공통 작품 사전 검색';

  @override
  String get labelTitle => '제목';

  @override
  String get labelCreator => '작가 / 제작사';

  @override
  String get labelReleaseYear => '출시 연도';

  @override
  String get posterImageLabel => '포스터 이미지 (웹 URL 또는 로컬 파일)';

  @override
  String get posterUrlHint => 'https://... 또는 로컬 경로 입력';

  @override
  String get tooltipPickLocalImage => '로컬 이미지 파일 선택';

  @override
  String get tooltipWebImageSearch => '인터넷 이미지 검색';

  @override
  String get myRating => '나의 별점';

  @override
  String get labelCategory => '카테고리';

  @override
  String get labelWorkStatus => '작품 상태';

  @override
  String get labelMyStatus => '나의 상태';

  @override
  String get actionRegister => '등록';

  @override
  String get validationEnterTitle => '제목을 입력해 주세요.';

  @override
  String get catalogAddContributionTitle => '글로벌 사전 — 작품 추가 제안';

  @override
  String get labelTitleRequired => '제목 *';

  @override
  String get labelPosterUrl => '포스터 URL (https)';

  @override
  String get tooltipImageSearch => '이미지 검색';

  @override
  String get labelDescriptionBrief => '설명 (직접 작성, 짧게)';

  @override
  String get labelAnilistId => 'AniList ID (선택, 숫자만)';

  @override
  String get labelProposalNote => '제안 메모 (선택)';

  @override
  String get actionSaveProposal => '제안 저장';

  @override
  String get validationPosterHttpsOnly => '포스터는 https URL만 제안할 수 있습니다.';

  @override
  String get catalogContributionDisclaimer =>
      '제안은 로컬에 저장됩니다. 글로벌 사전 반영은 운영자 검수·akasha-db merge 후 앱 동기화로 이루어집니다.';

  @override
  String get catalogFixContributionTitle => '글로벌 사전 — 정보 수정 제안';

  @override
  String get labelWhatIsWrong => '무엇이 틀렸나요? *';

  @override
  String get hintWhatIsWrong => '예: 포스터가 다른 작품 이미지입니다';

  @override
  String get fixPosterUrl => '포스터 URL 수정';

  @override
  String get labelProposedPosterUrl => '제안 포스터 URL';

  @override
  String get fixReleaseYear => '출시 연도 수정';

  @override
  String get labelProposedYear => '제안 연도';

  @override
  String get fixTitle => '제목 수정';

  @override
  String get labelProposedTitle => '제안 제목';

  @override
  String get fixCreator => '작가/제작사 수정';

  @override
  String get labelProposedCreator => '제안 작가/제작사';

  @override
  String get labelAdditionalNote => '추가 메모';

  @override
  String get validationEnterIssue => '문제 설명을 입력해 주세요.';

  @override
  String get validationSelectFixField => '수정할 항목을 선택해 주세요.';

  @override
  String get validationPosterHttpsRequired => '포스터는 https URL만 가능합니다.';

  @override
  String get validationEnterYearNumber => '연도를 숫자로 입력해 주세요.';

  @override
  String get clipboardImportTitle => '🤖 AI 마크다운 가져오기';

  @override
  String get clipboardImportDescription =>
      'AI가 생성한 마크다운 텍스트를 여기에 붙여넣으세요. 파싱하여 작품 목록에 추가합니다.';

  @override
  String get untitledWork => '이름 없는 작품';

  @override
  String clipboardImportAlreadyExists(String title) {
    return '\"$title\"은(는) 이미 아카이브에 있습니다.';
  }

  @override
  String clipboardImportAdded(String title, String workId) {
    return '\"$title\" 추가됨 (work_id: $workId)';
  }

  @override
  String clipboardImportParseFailed(String error) {
    return '파싱에 실패했습니다: $error';
  }

  @override
  String get actionParseAndImport => '파싱 및 가져오기';

  @override
  String get noWorksInCatalogVault => '카탈로그·볼트에 Work가 없습니다.';

  @override
  String get labelSelectWork => '작품 선택';

  @override
  String get optionNone => '선택 안 함';

  @override
  String get createCastFromWork => '선택한 작품으로 Cast 만들기';

  @override
  String get labelCollectionName => '컬렉션 이름';

  @override
  String get labelMode => '모드';

  @override
  String get modeFilter => '필터 (태그·작품·kind)';

  @override
  String get modeCurated => '큐레이션 (직접 선택)';

  @override
  String get collectionAddTitle => '컬렉션 추가';

  @override
  String get collectionEditTitle => '컬렉션 설정';

  @override
  String get noEntitiesInCatalog => '카탈로그에 Person·Concept 등 Entity가 없습니다.';

  @override
  String selectedCountReorderHint(int count) {
    return '선택 $count개 · 갤러리에서 순서 변경';
  }

  @override
  String get deleteCollectionTitle => '컬렉션 삭제';

  @override
  String get deleteCollectionConfirm => '이 컬렉션을 삭제할까요? Entity 데이터는 유지됩니다.';

  @override
  String get actionDelete => '삭제';

  @override
  String get presetAvailabilityNote => '볼트·카탈로그에 해당 Work가 있을 때만 활성화됩니다.';

  @override
  String get customCreate => '직접 만들기';

  @override
  String get customCreateDescription => '태그 기반 · 작품 기반 · 혼합 — 아래에서 설정 후 「추가」';

  @override
  String get tabExistingLink => '기존 연결';

  @override
  String get tabCreateNew => '새로 만들기';

  @override
  String get hintSearchNameAlias => '이름 · 별칭 검색';

  @override
  String get noEntitiesAvailable => '연결할 Entity가 없습니다.';

  @override
  String noMatchingEntity(String query) {
    return '「$query」과(와) 일치하는 항목이 없습니다.';
  }

  @override
  String get sectionRelatedToWork => '이 작품과 관련';

  @override
  String get sectionSearchResults => '검색 결과';

  @override
  String createEntityAndLink(String typeLabel) {
    return '카탈로그에 없는 $typeLabel을(를) 새로 등록하고, 이 작품 본문에 바로 연결합니다.';
  }

  @override
  String get useSearchQueryAsName => '검색어를 이름으로 사용';

  @override
  String createNewEntityType(String typeLabel) {
    return '$typeLabel 새로 만들기';
  }

  @override
  String get subtitleRecommendations =>
      '추천 후보 · Person · Event · Concept · Place · Org';

  @override
  String get subtitleSeedAvailable => '내 카탈로그에 없습니다 · 사전 인물에서 연결할 수 있습니다';

  @override
  String get subtitleCatalog => '카탈로그 · Person · Event · Concept · Place · Org';

  @override
  String get journalQuickCaptureTitle => '메모 기록';

  @override
  String get labelBody => '본문';

  @override
  String get hintJournalBody => '아이디어, 메모, 생각…';

  @override
  String get labelTitleOptional => '제목 (선택)';

  @override
  String get hintTitleAutoFill => '비우면 본문 앞부분을 사용합니다';

  @override
  String get personalLibraryAddTitle => '나만의 서재 추가';

  @override
  String get labelLibraryName => '서재 이름';

  @override
  String get hintLibraryName => '예: 인생 명작, 읽을 예정 2026…';

  @override
  String get helperLibraryCreate => '만든 뒤 작품을 담아 채웁니다. 필터는 설정에서 조정할 수 있습니다.';

  @override
  String get personalLibraryEditTitle => '나만의 서재 설정';

  @override
  String get personalLibraryDeleteTitle => '나만의 서재 삭제';

  @override
  String personalLibraryDeleteMessage(String libraryName) {
    return '「$libraryName」 서재를 삭제할까요?\n아카이브된 작품과 md 파일은 삭제되지 않습니다.';
  }

  @override
  String get hintLibraryNameEdit => '예: 인생 명작, 감상 완료 목록…';

  @override
  String get helperMasterArchiveReadonly => 'master_archive 이름은 변경할 수 없습니다.';

  @override
  String get helperCuratedMode => '담긴 작품만 표시됩니다. 필터는 2차로 좁힙니다.';

  @override
  String get helperFilterMode => '볼트에 아카이브된 작품만 필터로 표시됩니다.';

  @override
  String get addWorkSearch => '작품 추가 (검색)';

  @override
  String includedWorksCount(int count) {
    return '담긴 작품 ($count)';
  }

  @override
  String get noIncludedWorks => '아직 담긴 작품이 없습니다.';

  @override
  String cleanOrphanIds(int count) {
    return '고아 ID 정리 ($count건)';
  }

  @override
  String get labelCategoryFilter => '소분류 (카테고리) 필터 (다중 선택 가능)';

  @override
  String get labelWorkStatusFilter => '작품 상태 조건 필터 (다중 선택 가능)';

  @override
  String get labelMyStatusFilter => '나의 상태 조건 필터 (다중 선택 가능)';

  @override
  String get promptTemplateTitle => 'AI 프롬프트 템플릿';

  @override
  String get promptTemplateDescription =>
      '이 템플릿을 AI에게 제공하면, 규격에 맞는 마크다운을 쉽게 받아올 수 있습니다.';

  @override
  String get templateCopiedToClipboard => '템플릿이 클립보드에 복사되었습니다.';

  @override
  String get registrySyncTitle => '글로벌 사전 동기화';

  @override
  String lastSyncTime(String time) {
    return '마지막 동기화: $time';
  }

  @override
  String get actionSyncNow => '지금 동기화';

  @override
  String get labelCustomDbUrl => '커스텀 사전 DB Base URL';

  @override
  String get customDbUrlDescription =>
      'manifest.json, search_index.json, shards/ 파일을 이 주소에서 내려받습니다.';

  @override
  String get syncUrlChanged => '동기화 주소가 변경되었습니다.';

  @override
  String get actionSaveUrl => 'URL 저장';

  @override
  String get timelineQuickCaptureTitle => '타임라인 기록';

  @override
  String get hintTimelineBody => '오늘의 생각, 일기, 아이디어…';

  @override
  String get labelWorkLinkOptional => '작품 연결 (선택)';

  @override
  String get optionNoLink => '연결 없음';

  @override
  String get timelineSaveLocationInfo => 'vault/timeline/ 에 저장됩니다.';

  @override
  String get workLinkPickerTitle => '작품 추가';

  @override
  String get hintSearchTitleCreatorId => '제목 · 작가 · work_id 검색';

  @override
  String get workLinkPickerDescription => '서재에 저장된 작품을 본문에 [[링크]]로 연결합니다.';

  @override
  String get noOtherWorksToLink => '연결할 다른 작품이 없습니다.';

  @override
  String noMatchingWork(String query) {
    return '「$query」과(와) 일치하는 작품이 없습니다.';
  }

  @override
  String catalogContributionsTitle(int count) {
    return '카탈로그 제안 ($count)';
  }

  @override
  String get noSavedProposals => '저장된 제안이 없습니다.';

  @override
  String get suggestNewWork => '작품 추가 제안';

  @override
  String get actionCopyJson => 'JSON 복사';

  @override
  String get actionOpenGithubIssue => 'GitHub Issue 열기';

  @override
  String get actionCopyAllJson => '전체 JSON 복사';

  @override
  String get proposalJsonCopied => '제안 JSON이 클립보드에 복사되었습니다.';

  @override
  String jsonCopiedWithFile(String path) {
    return 'JSON 복사됨 · 파일: $path';
  }

  @override
  String jsonCopiedFileFailed(String error) {
    return 'JSON 복사됨 (파일 저장 실패: $error)';
  }

  @override
  String get deleteUnsavedWarning => '저장하지 않은 편집 내용도 함께 사라집니다.';

  @override
  String get detailDeleteTitle => '작품 삭제';

  @override
  String detailDeleteConfirmVault(String title, String unsavedNote) {
    return '\"$title\" 작품을 아카이브에서 삭제할까요?\n로컬 볼트의 .md 파일이 영구 삭제됩니다.$unsavedNote\n탐색·사전 목록에서는 사라지지 않으며, 자동 아카이빙 설정 시 .md가 다시 생성될 수 있습니다.';
  }

  @override
  String detailDeleteConfirmNoVault(String title, String unsavedNote) {
    return '\"$title\" 작품을 목록에서 제거할까요?\n(데모 모드 — 볼트 연동 시 .md 파일이 삭제됩니다)$unsavedNote';
  }

  @override
  String get workbenchCloseTabDialogTitle => '미저장 변경';

  @override
  String get workbenchCloseTabDialogMessage =>
      '미저장 변경사항이 있습니다. 저장하지 않고 닫으시겠습니까?';

  @override
  String get workbenchCloseTabDialogSaveAndClose => '저장 후 닫기';

  @override
  String get workbenchCloseTabDialogDiscard => '저장 안 함';

  @override
  String get workbenchIncomingLinksRefresh => 'Incoming Links 새로고침';

  @override
  String get workbenchBreadcrumbLibrary => '서재';

  @override
  String get workbenchBreadcrumbWork => '작품';

  @override
  String get workbenchTabConnections => '연결';

  @override
  String get workbenchTabDetails => '정보';

  @override
  String get workbenchTabType => '유형';

  @override
  String get workbenchTabConnectionCount => '연결 수';

  @override
  String get workbenchTabAliases => '별칭';

  @override
  String get workbenchTabStoragePath => '저장 경로';

  @override
  String get helpWorkbenchConnectionExplain =>
      '섹션의 「추가」로 Entity를 연결합니다. 인물은 출연 슬롯, 그 외는 감상 본문에 [[링크]]가 삽입됩니다.';

  @override
  String get helpEntityConnectionExplain =>
      '섹션의 「추가」로 연결하면 기록 본문에 [[링크]]가 삽입됩니다.';

  @override
  String get workbenchCastSectionTitle => '👥 출연';

  @override
  String get workbenchQuotesSectionTitle => '🎬 명장면 & 명대사';

  @override
  String get workbenchSynopsisSectionTitle => '📋 시놉시스';

  @override
  String get workbenchGallerySectionTitle => '🖼 갤러리';

  @override
  String get workbenchMemoSectionTitle => '📝 메모';

  @override
  String get workbenchEditorAddSection => '섹션 삽입';

  @override
  String get workbenchEditorAddSectionTitle => '섹션 추가';

  @override
  String get workbenchEditorFind => '찾기';

  @override
  String get workbenchEditorReplace => '바꿀 텍스트';

  @override
  String get workbenchEditorNext => '다음';

  @override
  String get workbenchEditorPrev => '이전';

  @override
  String get sidebarRecent => '최근 탐색';

  @override
  String get labelDashboardSearchWorks => '작품 검색';

  @override
  String get labelDashboardExploreEntities => '인물 탐색';

  @override
  String get labelDashboardConnectionMap => '연결 맵';

  @override
  String get labelDashboardAllBrowse => '전체 탐색';

  @override
  String get labelDashboardWrite => '기록';

  @override
  String get akashaPromptTemplate =>
      '당신은 서브컬처(만화, 게임, 애니메이션, 책) 아카이빙 전문가입니다.\n사용자가 요청한 작품의 정보를 아래 YAML Front-Matter 형식을 포함한 마크다운 문서로 작성해 주세요.\n\n---\nwork_id: \"\" (비워두면 AKASHA가 사전 매칭 또는 custom ID를 부여)\ntitle: \"작품의 정확한 제목\"\ncategory: manga | game | animation | book | movie | drama (하나만)\ncreator: \"원작자 / 제작사 / 감독 등\"\nrelease_year: 출시 또는 연재 시작 연도 (숫자만, 예: 2011)\nrating: 5.0 (0.0~5.0 범위의 실수)\nwork_status: \"serializing\" | \"hiatus\" | \"completed\" (game 카테고리인 경우: \"released\" | \"earlyAccess\" | \"upcoming\")\nmy_status: \"notStarted\" | \"watching\" | \"finished\" | \"dropped\" (game 카테고리인 경우: \"backlog\" | \"playing\" | \"cleared\" | \"abandoned\")\nis_hall_of_fame: true | false (인생 명작 여부)\ntags: [태그1, 태그2] (예: [청춘, 감동, 음악])\nposter: \"\" (비워둠)\nadded_at: \"현재 날짜 및 시간 (ISO 8601 형식, 예: 2026-06-05T19:00:00)\"\n---\n\n# 👥 출연\n\n# 🎬 명장면 & 명대사\n> \"명대사 내용 1\" — 캐릭터 이름 / 상황 설명 (화수 등)\n\n# 📋 시놉시스\n\n# 🖼 갤러리\n\n# 📝 메모\n';

  @override
  String get labelTags => '태그';

  @override
  String get recordKindTimeline => '타임라인';

  @override
  String get recordKindJournal => '메모';

  @override
  String get recordKindWorkJournal => '작품 저널';

  @override
  String get recordKindEntityJournal => '엔티티 저널';

  @override
  String get recordKindFreeformJournal => '자유 저널';

  @override
  String connectedRecordsCount(int count) {
    return '연결된 Record $count개';
  }

  @override
  String titleUpdateNeededCount(int count) {
    return '제목 갱신 필요 $count개';
  }

  @override
  String sameDayRecordsCount(String date, int count) {
    return '같은 날 기록 · $date ($count)';
  }

  @override
  String get actionCreateMd => 'md 생성';

  @override
  String get actionSaveAndAddToLibrary => '저장하고 서재에 담기';

  @override
  String workbenchCloseTabMessageWithTitle(String title) {
    return '\"$title\"에 저장하지 않은 변경이 있습니다.';
  }

  @override
  String workbenchCloseTabMessageWithTitleNoSave(String title) {
    return '\"$title\"에 저장하지 않은 변경이 있습니다.\n다른 탭이므로 저장하려면 먼저 해당 작품을 선택하세요.';
  }

  @override
  String entityJournalDeleteConfirm(String title) {
    return '「$title」 entity journal을 삭제할까요?';
  }

  @override
  String get entityJournalPlaceholderBody => '(기록 대기중)';

  @override
  String entityJournalSaveSuccess(String title) {
    return '\"$title\" entity journal을 저장했습니다.';
  }

  @override
  String get errorVaultRequired => '볼트를 먼저 연결해 주세요.';

  @override
  String get errorEmptyBody => '본문을 입력해 주세요.';

  @override
  String errorSaveFailed(String error) {
    return '저장 실패: $error';
  }

  @override
  String get errorNoMdFileToDelete => '삭제할 md 파일이 없습니다.';

  @override
  String get errorCatalogRequired => 'catalog 연결이 필요합니다.';

  @override
  String get helpWorkbenchCastEditorEmpty =>
      '우측 「인물 추가」로 출연진을 넣으면 미리보기 상단에 카드로 표시됩니다.';

  @override
  String get hintCastRole => '역할 (예: 주인공)';

  @override
  String get actionPaste => '붙여넣기';

  @override
  String get actionAddImage => '이미지 추가';

  @override
  String get helpWorkbenchGalleryEditorEmpty =>
      '이미지를 끌어다 놓거나, 붙여넣기·추가로 스크린샷·콜라주를 넣을 수 있습니다.';

  @override
  String get hintQuotesEditor => '한 줄에 한 문장씩 입력하세요.';

  @override
  String get errorAddImageVaultRequired =>
      '이미지 추가는 Sanctum 볼트 연결 후 사용할 수 있습니다.';

  @override
  String get errorPasteVaultRequired => '붙여넣기는 Sanctum 볼트 연결 후 사용할 수 있습니다.';

  @override
  String get errorNoImageInClipboard => '클립보드에 이미지가 없습니다.';

  @override
  String get hintSynopsisEditor => '줄거리·세계관·배경을 적어 보세요.';

  @override
  String get hintMemoEditor => '기록·평가·느낀 점. 우측 「추가」로 [[링크]]를 넣을 수 있습니다.';

  @override
  String get navHome => '홈';

  @override
  String get navExplore => '탐색';

  @override
  String get navSearch => '검색';

  @override
  String get navLibrary => '라이브러리';

  @override
  String get navCollections => '컬렉션';

  @override
  String get errorVaultRequiredToAddToLibrary => '볼트를 먼저 연결해야 서재에 담을 수 있습니다.';

  @override
  String alreadyInLibrary(String name) {
    return '이미 「$name」 서재에 있습니다.';
  }

  @override
  String addedToLibrary(String name) {
    return '「$name」 서재에 담았습니다.';
  }

  @override
  String get actionView => '보기';

  @override
  String errorArchiveFailed(String error) {
    return '아카이브 실패: $error';
  }

  @override
  String get successRegistryCacheCleared => '사전 캐시를 삭제하고 번들 사전으로 복원했습니다.';

  @override
  String errorClearCacheFailed(String error) {
    return '캐시 삭제 실패: $error';
  }

  @override
  String get labelDashboardContinueExplore => '계속 탐험하기';

  @override
  String dashboardContinueItemCount(int count) {
    return '$count개';
  }

  @override
  String get helpDashboardContinueExploreColdStart =>
      '탐험을 시작하면 최근에 본 작품과 인물이 여기에 표시됩니다.';

  @override
  String get helpDashboardContinueExploreEmpty =>
      '아직 탐색 기록이 없습니다. 작품이나 인물을 열면 여기에 표시됩니다.';

  @override
  String get helpDashboardContinueExploreFallback => '최근 추가한 작품부터 탐험해 보세요.';

  @override
  String get actionPrev => '이전';

  @override
  String get actionNext => '다음';

  @override
  String get labelHasRecord => '기록 있음';

  @override
  String get tooltipVaultSettings => '볼트 설정';

  @override
  String get labelDashboardQuickActions => '빠른 액션';

  @override
  String get dashboardConnectionInsightTitle => '연결 인사이트';

  @override
  String dashboardConnectionCount(int count) {
    return '$count개의 연결';
  }

  @override
  String get dashboardConnectionDescription => '아카이브 기록 사이에 실제로 저장된 연결입니다.';

  @override
  String dashboardLinkedRecordsCount(int count) {
    return '연결된 기록 $count개';
  }

  @override
  String dashboardConnectedEntitiesCount(int count) {
    return '연결된 엔티티 $count개';
  }

  @override
  String get dashboardConnectionEmpty => '아직 저장된 기록 연결이 없습니다.';

  @override
  String get dashboardConnectionError => '연결 요약을 잠시 불러올 수 없습니다.';

  @override
  String get dashboardExploreGraph => '그래프 탐색';

  @override
  String get dashboardTodayTitle => '오늘의 기록';

  @override
  String dashboardTodayCount(int count) {
    return '변경 $count개';
  }

  @override
  String get dashboardTodayEmpty => '오늘 추가되거나 수정된 기록이 없습니다.';

  @override
  String get dashboardTodayUnavailable => '볼트를 연결하면 오늘의 기록 활동을 볼 수 있습니다.';

  @override
  String get dashboardTodayError => '오늘의 기록 활동을 잠시 불러올 수 없습니다.';

  @override
  String get dashboardActivityAdded => '새 기록 추가';

  @override
  String get dashboardActivityUpdated => '기록 수정';

  @override
  String get descDashboardSearchWorks => '볼트·카탈로그에서 작품과 인물을 찾습니다.';

  @override
  String get descDashboardExploreEntities => '등록된 인물 엔티티를 갤러리로 봅니다.';

  @override
  String get descDashboardConnectionMap =>
      '볼트의 [[wiki]] 링크로 이어진 작품·인물 관계를 봅니다.';

  @override
  String get descDashboardAllBrowse => '라이브러리 작품을 그리드로 탐색합니다.';

  @override
  String get descDashboardWrite => '타임라인과 일지에서 시간순 기록을 확인합니다.';

  @override
  String get appThemePickerFreeNotice =>
      'Classic Dark와 Midnight Blue는 기본 무료 테마입니다.';

  @override
  String get appThemeGalleryTitle => '테마 갤러리';

  @override
  String get appThemeGallerySubtitle =>
      '공식 테마를 한곳에서 살펴보세요. 유료 테마도 판매 전부터 확인할 수 있습니다.';

  @override
  String appThemeGalleryAvailableCount(int available, int total) {
    return '전체 $total개 중 $available개 사용 가능';
  }

  @override
  String get themeStatusIncluded => '무료 포함';

  @override
  String get themeStatusOwned => '보유 중';

  @override
  String get themeStatusPlannedPremium => '유료 · 출시 예정';

  @override
  String themePriceChooseOne(int astra, int echo) {
    return '$astra Astra 또는 $echo Echo';
  }

  @override
  String get commerceCenterTitle => '상점 및 인벤토리';

  @override
  String get commerceCenterSubtitle => '테마 패키지와 재화, 소유권을 한곳에서 확인합니다.';

  @override
  String get commerceStoreTab => '상점';

  @override
  String get commerceInventoryTab => '인벤토리';

  @override
  String get commerceStorePreviewNotice =>
      '구매 기능은 아직 비활성 상태입니다. 확정된 상품과 가격만 미리 보여줍니다.';

  @override
  String get commerceAstraPackSection => '아스트라 충전';

  @override
  String get commerceAstraPackSectionBody =>
      'Steam Wallet을 통해 구매할 예정인 출시 상품입니다.';

  @override
  String commerceAstraPackGrant(int amount) {
    return '$amount Astra';
  }

  @override
  String get commerceThemePackageSection => '테마 패키지';

  @override
  String commerceSteamPriceReady(String price) {
    return 'Steam 가격 · $price';
  }

  @override
  String get commerceSteamPricePending => 'Steam 연결 후 현지 가격 확인';

  @override
  String get commerceAccountLoading => 'Steam 인벤토리를 확인하는 중입니다.';

  @override
  String get commerceAccountReadyReadOnly =>
      'Steam 계정이 연결되었습니다. 구매 기능은 아직 비활성입니다.';

  @override
  String get commerceAccountReadyTransactions =>
      'Steam 거래가 활성화되어 있습니다. 완료 후 인벤토리에서 결과를 확인합니다.';

  @override
  String get commerceAccountOfflineCache => '오프라인 상태입니다. 마지막으로 확인한 정보를 표시합니다.';

  @override
  String get commerceAccountUnavailable => 'Steam 인벤토리를 확인할 수 없습니다.';

  @override
  String get commerceRetry => '다시 시도';

  @override
  String get commerceCurrencySection => '재화';

  @override
  String get commerceOwnedThemeSection => '보유 테마';

  @override
  String get commerceAstraLabel => '아스트라';

  @override
  String get commerceEchoLabel => '에코';

  @override
  String get commerceBalanceUnavailable => 'Steam 연결 후 표시';

  @override
  String get commerceIncluded => '기본 포함';

  @override
  String get commerceOwned => '보유 중';

  @override
  String get commerceOwnershipUnavailable => '소유권 확인 불가';

  @override
  String get commerceThemePackageLabel => '테마 패키지';

  @override
  String get commerceThemePackageContents => '색상·아트·배경·테마 전용 효과 전체를 포함합니다.';

  @override
  String get commerceComingSoon => '출시 준비 중';

  @override
  String get commerceBuyOnSteam => 'Steam에서 구매';

  @override
  String get commerceChooseCurrency => '재화 선택';

  @override
  String get commerceOperationInProgress => '거래 확인 중';

  @override
  String commercePurchaseConfirmTitle(String product) {
    return '$product 구매';
  }

  @override
  String get commercePurchaseConfirmBody =>
      'Steam 오버레이에서 현지 가격과 결제 수단을 최종 확인합니다. 완료 후 Steam Inventory를 다시 조회합니다.';

  @override
  String commerceExchangeConfirmTitle(String product) {
    return '$product 교환';
  }

  @override
  String get commerceChooseCurrencyBody =>
      '선택한 재화는 즉시 소비되며 이 테마가 영구 잠금 해제됩니다. 아스트라 또는 에코 중 하나만 선택할 수 있으며 혼합 결제는 지원하지 않습니다.';

  @override
  String commerceCurrencyOption(String currency, int cost, int balance) {
    return '$currency $cost개 · 보유 $balance개';
  }

  @override
  String get commerceInsufficientCurrency => '잔액 부족';

  @override
  String get commerceCancel => '취소';

  @override
  String get commerceContinue => '계속';

  @override
  String get commerceResultPurchaseConfirmed =>
      '아스트라 지급을 Steam Inventory에서 확인했습니다.';

  @override
  String get commerceResultExchangeConfirmed =>
      '테마 소유권을 Steam Inventory에서 확인했습니다.';

  @override
  String get commerceResultNoChange => 'Steam에서 인벤토리 변경 없음으로 확인했습니다.';

  @override
  String get commerceResultCancelled => 'Steam 거래를 취소했습니다.';

  @override
  String get commerceResultRejected => '거래 조건을 충족하지 못했습니다. 잔액과 소유 상태를 확인해 주세요.';

  @override
  String get commerceResultFailed => 'Steam 거래를 완료하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get commerceResultIndeterminate =>
      '거래 결과 확인이 지연되고 있습니다. 중복 거래를 시도하지 말고 인벤토리를 다시 확인해 주세요.';

  @override
  String get commerceAuthorityNotice =>
      'Astra, Echo와 유료 소유권의 기준은 Steam Inventory입니다. Vault에는 결제 권한을 저장하지 않습니다.';

  @override
  String get themeStatusChecking => '소유권 확인 중';

  @override
  String get themeStatusPurchaseRequired => '구매 필요';

  @override
  String get themeStatusOfferPaused => '일시 판매 중지';

  @override
  String get themeStatusUnavailable => '소유권 확인 불가';

  @override
  String get themeStatusCurrent => '사용 중';

  @override
  String get windowMinimize => '최소화';

  @override
  String get windowMaximize => '최대화';

  @override
  String get windowRestore => '이전 크기로 복원';

  @override
  String get windowClose => '닫기';

  @override
  String get themeClassicDarkName => '클래식 다크';

  @override
  String get themeMidnightBlueName => '미드나이트 블루';

  @override
  String get themeSakuraName => '벚꽃';

  @override
  String get themeAmethystName => '자수정';

  @override
  String get themeNocturneName => '녹턴';

  @override
  String get dashboardHeroTitle => '기록하고, 연결하고, 발견하세요';

  @override
  String get dashboardHeroSubtitle =>
      '작품, 사람, 사건, 개념을 기록하면 연결이 생기고 새로운 발견으로 이어집니다.';

  @override
  String get dashboardHeroArchiveRecords => '아카이브 기록';

  @override
  String get dashboardHeroEntities => '엔티티';

  @override
  String get dashboardHeroCollections => '컬렉션';

  @override
  String get dashboardHeroTags => '태그';

  @override
  String get dashboardHeroStartAction => '첫 기록 시작';

  @override
  String get dashboardDiscoveryTitle => '발견의 여정';

  @override
  String get dashboardDiscoveryTabConnections => '추천 연결';

  @override
  String get dashboardDiscoveryTabNewWorks => '새로운 작품';

  @override
  String get dashboardDiscoveryTabPeople => '주목할 인물';

  @override
  String get dashboardDiscoveryEmptyConnections =>
      '기록에 [[링크]]를 추가하면 추천 연결이 여기에 표시됩니다.';

  @override
  String get dashboardDiscoveryMoreConnections => '더 많은 연결 보기';

  @override
  String get dashboardDiscoveryEmptyVault => '볼트에 작품을 추가하면 발견의 여정이 시작됩니다.';

  @override
  String get dashboardDiscoveryNoRecentWorks => '최근 추가한 작품이 없습니다.';

  @override
  String get dashboardDiscoveryNoPeople =>
      '등록된 인물이 없습니다. 인물을 추가하고 작품과 연결해 보세요.';

  @override
  String get dashboardThemeClustersTitle => '반복되는 주제';

  @override
  String get dashboardRecentDiscoveryTitle => '최근 발견';

  @override
  String get dashboardRecentDiscoveryEmpty => '탐험을 시작하면 최근에 본 작품이 여기에 모입니다.';

  @override
  String get dashboardRecentRecordsTitle => '최근 기록';

  @override
  String get dashboardRecentRecordsEmpty => '작품을 열어 감상을 기록하면 여기에 표시됩니다.';

  @override
  String get dashboardRecentRecordsArchived => '아카이브됨 · 기록 있음';

  @override
  String get dashboardRegistryBridgeTitle => '사전에서 발견';

  @override
  String dashboardRegistryRecommendation(String bridge) {
    return '$bridge → 사전 추천';
  }

  @override
  String get dashboardUniverseTitle => '지식 우주 현황';

  @override
  String get dashboardUniverseRecentWorks => '최근 추가된 작품';

  @override
  String get dashboardUniverseViewAll => '모두 보기';

  @override
  String get dashboardUniverseNoRecentWorks => '최근 추가한 작품이 없습니다.';

  @override
  String get dashboardTodaysLinksTitle => '오늘의 연결';

  @override
  String get dashboardTodaysLinksEmpty => '기록에서 연결한 작품·인물이 여기에 표시됩니다.';

  @override
  String get dashboardTodaysLinksConnectedWork => '연결 작품';

  @override
  String get dashboardTodaysLinksSuggestion => '연결 제안';

  @override
  String get registryDiscoveryMoreFromCatalog => '사전에서 더 보기';

  @override
  String get knowledgeGraphTitle => '지식 지도와 연결';

  @override
  String get knowledgeGraphSubtitle => '직접 만든 지식 지도와 기록에서 파생된 연결을 함께 살펴봅니다.';

  @override
  String get knowledgeGraphEmptyVault => '아카이브된 작품이 없습니다.';

  @override
  String get knowledgeGraphEmptyVaultBody =>
      '작품을 아카이브하면 기록에서 파생된 연결을 여기서 탐색할 수 있습니다.';

  @override
  String get knowledgeGraphConnectEntity => '엔티티 연결하기';

  @override
  String knowledgeGraphConnectionCount(int count) {
    return '연결 $count개';
  }

  @override
  String get knowledgeGraphNoConnections => '연결 없음 · 기록에서 링크 추가';

  @override
  String get knowledgeGraphOpen => '열기';

  @override
  String get knowledgeGraphExpandToLoad => '펼쳐서 연결을 불러오세요.';

  @override
  String get knowledgeGraphEmptyTitle => '기록에서 파생된 연결이 없습니다.';

  @override
  String get knowledgeGraphEmptyBody => '작품이나 엔티티 기록에 링크를 추가하면 연결 목록에 표시됩니다.';

  @override
  String get knowledgeGraphOpenRecord => '기록 열기';

  @override
  String get actionClose => '닫기';

  @override
  String get labelNowViewing => '지금 보는 항목';

  @override
  String get actionWrite => '기록하기';

  @override
  String get hintMemoBar => '메모를 추가하세요…';

  @override
  String get actionEditMemo => '메모 편집';

  @override
  String get actionEdit => '편집';

  @override
  String get confirmDeleteMemo => '이 메모를 삭제할까요?';

  @override
  String get helpJournalConnectVault => '볼트를 연결하면 메모를 볼 수 있습니다.';

  @override
  String get helpJournalEmpty => '아직 메모가 없습니다.';

  @override
  String get actionWriteFirstMemo => '첫 메모 작성';

  @override
  String countMemos(int count) {
    return '메모 ($count)';
  }

  @override
  String get tooltipNewMemo => '새 메모';

  @override
  String get tooltipRefresh => '새로고침';

  @override
  String get actionEditTimeline => '타임라인 편집';

  @override
  String get confirmDeleteTimeline => '이 타임라인 기록을 삭제할까요?';

  @override
  String get helpTimelineConnectVault => '볼트를 먼저 연결하세요.';

  @override
  String get timelineConnectVaultBody => '타임라인과 기록 허브는 로컬 볼트에 저장된 기록을 사용합니다.';

  @override
  String get helpTimelineEmpty => '아직 시간순 기록이 없습니다.';

  @override
  String get timelineEmptyBody => '첫 기록을 남기면 날짜와 시간 순서로 이곳에 모입니다.';

  @override
  String get actionWriteFirstRecord => '첫 기록 작성';

  @override
  String countTimelineRecords(int count) {
    return '타임라인 ($count)';
  }

  @override
  String get tooltipNewRecord => '새 기록';

  @override
  String get helpEntityJournalConnectVault =>
      '볼트를 연결하면 entity journal을 볼 수 있습니다.';

  @override
  String get helpEntityJournalEmpty => '아직 entity journal이 없습니다.';

  @override
  String get helpEntityJournalTip =>
      'Fusion → 직접 추가로 Person · Concept · Event를 아카이브하세요.';

  @override
  String countEntityJournalEntries(int count) {
    return 'Entity journal ($count)';
  }

  @override
  String get errorConnectVaultFirst => '볼트를 먼저 연결해 주세요.';

  @override
  String errorEntityNotFound(String id) {
    return '「$id」을(를) 찾을 수 없습니다.';
  }

  @override
  String errorVaultConnectionFailed(String error) {
    return '볼트 연결에 실패했습니다: $error';
  }

  @override
  String successEntityArchived(String badge, String title) {
    return '$badge 「$title」 아카이브에 추가됨 · 기록 → Entity에서 확인';
  }

  @override
  String successEntityRegisteredOnly(String badge, String title) {
    return '$badge 「$title」 이름만 등록됨 · Fusion에서 아카이브 가능';
  }

  @override
  String successArchivedWork(String title) {
    return '\"$title\"을(를) 아카이브했습니다.';
  }

  @override
  String get actionAddCustomSection => '직접 섹션 추가';

  @override
  String get actionAddCustomWithType => '직접 추가 (유형 선택)';

  @override
  String get actionAddToLibrary => '서재에 담기';

  @override
  String get actionApplyManual => '수동 적용';

  @override
  String get actionApplyThisImage => '이 이미지 적용';

  @override
  String get actionArchive => '아카이브';

  @override
  String get actionCopy => '복사하기';

  @override
  String get actionCreate => '만들기';

  @override
  String get actionKeep => '유지';

  @override
  String get actionOpenGoogleImageSearch => 'Google 이미지 검색 열기';

  @override
  String get actionOpenPinterestSearch => 'Pinterest 검색 열기';

  @override
  String get actionPrevious => '이전';

  @override
  String get actionProposeToGlobalRegistry => '글로벌 사전에 추가 제안';

  @override
  String get actionRedo => '다시 실행';

  @override
  String get actionReload => '다시 불러오기';

  @override
  String get actionReplace => '바꾸기';

  @override
  String get actionReplaceAll => '모두 바꾸기';

  @override
  String get actionSelectLocalImage => '로컬 이미지 선택';

  @override
  String get actionUndo => '실행 취소';

  @override
  String get addConcept => '개념 추가';

  @override
  String get addEvent => '사건 추가';

  @override
  String get addOrganization => '조직 추가';

  @override
  String get addPerson => '인물 추가';

  @override
  String get addPlace => '장소 추가';

  @override
  String get linkEntity => 'Entity 연결';

  @override
  String get addWork => '작품 추가';

  @override
  String get breadcrumbLibrary => '서재';

  @override
  String get breadcrumbWork => '작품';

  @override
  String get clipboardImageDetected => '클립보드 이미지 감지됨';

  @override
  String errorBrowserLaunchFailed(String error) {
    return '브라우저를 열지 못했습니다: $error';
  }

  @override
  String get errorCannotOpenBrowser => '브라우저를 열 수 없습니다.';

  @override
  String get externalFileChanged => '외부 파일이 변경되었습니다';

  @override
  String get globalRegistryLabel => '글로벌 사전';

  @override
  String get helpFullFileEdit => '전체 마크다운 파일을 편집합니다.';

  @override
  String get helpMarkdownBodyEdit => '마크다운 본문을 편집합니다.';

  @override
  String get helpSectionEdit => '이 섹션을 편집합니다.';

  @override
  String get hintEnterDirectImageUrl => '직접 이미지 URL을 입력하세요';

  @override
  String get hintEnterPosterSearchQuery => '포스터 검색어를 입력하세요';

  @override
  String get hintFind => '찾기';

  @override
  String get hintHidden => '숨김';

  @override
  String get hintNotArchived => '아카이브 안 됨';

  @override
  String get hintReplaceText => '바꿀 텍스트';

  @override
  String get hintSearchEverything => '작품, 인물, 사건, 장소, 개념을 검색하세요...';

  @override
  String get hintSearchExplain => '내 아카이브와 스타터 카탈로그를 검색합니다.';

  @override
  String get hintSearchWorkFromRegistry => '사전에서 작품 검색';

  @override
  String get hintSiblingTracked => '관련 항목이 이미 기록되어 있습니다';

  @override
  String get hintWorkTitle => '작품 제목';

  @override
  String get imageCorrectionGuideSteps => '이미지를 복사하거나 URL을 붙여넣거나 로컬 파일을 선택하세요.';

  @override
  String get imageCorrectionGuideTitle => '이미지 교정 가이드';

  @override
  String incomingLinkCount(int count) {
    return '이 엔티티를 가리키는 기록 $count건';
  }

  @override
  String get invalidImageUrl => '올바른 이미지 URL이 아닙니다';

  @override
  String get labelRegistry => '사전';

  @override
  String get labelWarning => '주의';

  @override
  String get myArchiveLabel => '내 아카이브';

  @override
  String get myRegistrationLabel => '내 등록';

  @override
  String noLinksYet(String title) {
    return '아직 $title 연결이 없습니다.';
  }

  @override
  String get noSearchResults => '검색 결과가 없습니다';

  @override
  String get posterSearchQuery => '포스터 검색어';

  @override
  String get posterSuffix => '포스터';

  @override
  String get recordBody => '기록 본문';

  @override
  String get searchTitle => '검색';

  @override
  String get sectionCast => '출연진';

  @override
  String get sectionConnectedConcepts => '연결된 개념';

  @override
  String get sectionConnectedEvents => '연결된 사건';

  @override
  String get sectionConnectedOrganizations => '연결된 조직';

  @override
  String get sectionConnectedPersons => '연결된 인물';

  @override
  String get sectionConnectedPlaces => '연결된 장소';

  @override
  String get sectionConnectedWorks => '연결된 작품';

  @override
  String get sectionGallery => '갤러리';

  @override
  String get sectionGlobalRegistryEntity => '글로벌 사전 엔티티';

  @override
  String get sectionGlobalRegistryWork => '글로벌 사전 작품';

  @override
  String get sectionMainCharacters => '주요 인물';

  @override
  String get sectionMemo => '메모';

  @override
  String get sectionMyArchiveEntity => '내 아카이브 엔티티';

  @override
  String get sectionMyArchiveWork => '내 아카이브 작품';

  @override
  String get sectionMyArchiveWorkRegisteredOnly => '등록만 된 작품';

  @override
  String get sectionNotArchived => '아카이브 안 됨';

  @override
  String get sectionQuotes => '인용';

  @override
  String get sectionSynopsis => '시놉시스';

  @override
  String get tabBody => '본문';

  @override
  String get tabConnection => '연결';

  @override
  String get tabInfo => '정보';

  @override
  String get tabRecord => '기록';

  @override
  String get tabView => '보기';

  @override
  String get tooltipBlockquote => '인용문';

  @override
  String get tooltipBold => '굵게 (Ctrl+B)';

  @override
  String get tooltipBulletedList => '글머리 목록';

  @override
  String get tooltipFind => '찾기';

  @override
  String get tooltipH1 => '제목 1';

  @override
  String get tooltipH2 => '제목 2';

  @override
  String get tooltipH3 => '제목 3';

  @override
  String get tooltipImageVaultRequired => '이미지를 삽입하려면 볼트를 연결하세요';

  @override
  String get tooltipInlineCode => '인라인 코드';

  @override
  String get tooltipInsertImage => '이미지 삽입';

  @override
  String get tooltipInsertSection => '섹션 삽입';

  @override
  String get tooltipItalic => '기울임 (Ctrl+I)';

  @override
  String get tooltipLink => '링크';

  @override
  String get tooltipLinkEntity => '엔티티 링크';

  @override
  String get tooltipNumberedList => '번호 목록';

  @override
  String get tooltipSmartPaste => '스마트 붙여넣기';

  @override
  String get tooltipStrikethrough => '취소선';

  @override
  String get tooltipTableOfContents => '목차';

  @override
  String get waitingForClipboardImage => '클립보드 이미지를 기다리는 중...';

  @override
  String get webImageSearchTitle => '아카이브 포스터 이미지 교정';

  @override
  String get sectionHofTitle => 'S-Tier 인생 명작 컬렉션 (Hall of Fame)';

  @override
  String get catalogTitle => '작품 카탈로그 (사전 + 아카이브)';

  @override
  String personalLibraryCountDesc(int count) {
    return '$count개 아카이브 작품';
  }

  @override
  String catalogMediaSortDesc(int count) {
    return '$count개 표시 · 매체별 정렬 · 아카이브한 작품은 카드로 표시됩니다';
  }

  @override
  String catalogGeneralDesc(int count) {
    return '$count개 표시 · 아카이브 우선 항목은 사이드바의 나만의 서재를 이용하세요';
  }

  @override
  String worksCountSuffix(int count) {
    return '($count개 작품)';
  }

  @override
  String get watchlistTitle => '감상 예정 보관함';

  @override
  String watchlistDescription(String displayName) {
    return '$displayName님이 나중에 감상하려고 표시한 작품입니다.';
  }

  @override
  String get watchlistEmptyTitle => '아직 감상 예정 작품이 없습니다.';

  @override
  String get watchlistEmptyHelp => '새 작품을 추가하거나 작품 편집에서 나의 상태를 감상 예정으로 설정하세요.';

  @override
  String get yearlyLibraryTitle => '연도별 라이브러리';

  @override
  String get yearlyLibraryDescription => '출시 연도별로 라이브러리를 둘러봅니다.';

  @override
  String yearlyHeader(int year) {
    return '$year년';
  }

  @override
  String get yearlyNoYear => '연도 미상';

  @override
  String get canvasBtnFitToContent => '전체 노드 보기';

  @override
  String get canvasBtnConnectRelations => '관계 연결';

  @override
  String get canvasBtnAddArchive => '아카이브 추가';

  @override
  String get canvasBtnAddMemo => '메모 추가';

  @override
  String get canvasErrorLoadFailed => '캔버스 데이터를 불러올 수 없습니다.';

  @override
  String get canvasTooltipCloseTab => '탭 닫기';

  @override
  String get vocabRelated => '단순 관련성';

  @override
  String get vocabAbout => '주제 / 논함';

  @override
  String get vocabAppearsIn => '등장인물 / 등장장소';

  @override
  String get vocabCreatedBy => '창작자 / 제작자';

  @override
  String get vocabPartOf => '하위 부분 / 소속';

  @override
  String get vocabMemberOf => '구성원 / 멤버';

  @override
  String get vocabLocatedIn => '위치함';

  @override
  String get vocabInspiredBy => '영감을 받음';

  @override
  String get vocabRivalOf => '대립 / 라이벌';

  @override
  String get vocabAllyOf => '동맹 / 협력';

  @override
  String get vocabFriendOf => '친구 / 동료';

  @override
  String get vocabFamilyOf => '가족 / 친족';

  @override
  String get vocabMentorOf => '스승 / 멘토';

  @override
  String get vocabSubordinateOf => '부하 / 종속';

  @override
  String get vocabSuccessorOf => '계승 / 후계';

  @override
  String get vocabProtects => '보호함';

  @override
  String get vocabLoves => '애정 / 호감';

  @override
  String get vocabEnemyOf => '적대';

  @override
  String get vocabAdaptedFrom => '각색 / 원작 기반';

  @override
  String get vocabSymbolizes => '상징함';

  @override
  String get canvasRelationConnectTitle => '관계 선 연결';

  @override
  String get canvasRelationSelectPrompt => '노드 간의 관계 유형을 선택해 주세요:';

  @override
  String get canvasRelationCustomInputHelp =>
      '사용자 정의 관계 토큰 입력 (예: u:likes, u:teacher_of)';

  @override
  String get canvasRelationCustomError =>
      '올바르지 않은 사용자 관계 토큰 형식입니다. 소문자, 숫자, 언더바만 가능합니다 (예: u:rival_of).';

  @override
  String get canvasRelationConnectButton => '연결';

  @override
  String get actionCustomInput => '직접 입력...';

  @override
  String get canvasMemoEditTitle => '메모 수정';

  @override
  String get canvasMemoEditPlaceholder => '메모 내용을 입력하세요...';

  @override
  String get canvasMemoDeleteTitle => '메모 삭제';

  @override
  String get canvasMemoDeleteConfirm =>
      '이 메모를 삭제하시겠습니까?\n이 작업은 캔버스에서 제거할 뿐, 원본 파일은 삭제되지 않습니다.';

  @override
  String get canvasArchiveNodeDeleteTitle => '아카이브 노드 삭제';

  @override
  String get canvasArchiveNodeDeleteConfirm =>
      '이 노드를 삭제하시겠습니까?\n이 작업은 캔버스에서 제거할 뿐, 실제 작품/엔티티 원본 파일은 절대 삭제되지 않습니다.';

  @override
  String get canvasEdgeEditTitle => '관계 편집';

  @override
  String get canvasEdgeDeleteTitle => '관계선 삭제';

  @override
  String get canvasEdgeDeleteConfirm =>
      '이 관계선을 삭제할까요?\n이 작업은 캔버스에서 제거할 뿐, 원본 파일은 변경되지 않습니다.';

  @override
  String get canvasEdgeOfficialEditError => '공식 수립된 관계선은 캔버스에서 직접 수정할 수 없습니다.';

  @override
  String get canvasArchiveNodeMissingError => '아카이브에서 해당 항목을 찾을 수 없습니다.';

  @override
  String get canvasBannerSelectSource => '관계의 출발지가 될 노드를 마우스로 클릭해 주세요.';

  @override
  String canvasBannerSelectTarget(String name) {
    return '[$name]에서 연결할 도착 노드를 선택해 주세요.';
  }

  @override
  String get canvasBannerFallbackWork => '작품';

  @override
  String get canvasBannerFallbackEntity => '엔티티';

  @override
  String get canvasBannerFallbackMemo => '메모';

  @override
  String get tabTimeline => '타임라인';

  @override
  String get tabMemo => '메모';

  @override
  String get tabEntity => 'Entity';

  @override
  String get tabCandidates => '후보';

  @override
  String get libraryFallbackName => '나만의 서재';

  @override
  String get libraryEmptyVaultTitle => '볼트를 연동하면 나만의 서재가 열립니다';

  @override
  String get libraryEmptyCuratedTitle => '작품을 담아 서재를 채워 보세요';

  @override
  String get libraryEmptyFilterTitle => '필터 조건에 맞는 작품이 없습니다';

  @override
  String libraryEmptyArchiveDesc(String libName) {
    return '$libName에 표시할 아카이브 작품이 없습니다';
  }

  @override
  String libraryEmptyNoWorksDesc(String libName) {
    return '$libName에 표시할 작품이 없습니다';
  }

  @override
  String get libraryEmptyVaultHelp => '홈 상단에서 Sanctum 볼트 폴더를 연동해 주세요.';

  @override
  String get libraryEmptyCuratedHelp =>
      '검색으로 작품을 추가하거나, 카드 ⠿ 핸들을 서재로 끌어다 놓으세요.';

  @override
  String get libraryEmptyFilterHelp => '상단 필터를 조정해 보세요.';

  @override
  String get libraryEmptyGeneralHelp => '검색으로 작품을 추가해 보세요.';

  @override
  String get libraryBtnSearch => '작품 검색';

  @override
  String graphConnectionsCountDesc(int count) {
    return '연결 $count개';
  }

  @override
  String get graphNoConnectionsDesc => '연결 없음 · 기록에서 링크 추가';

  @override
  String get graphTabMyKnowledgeMap => '지식 지도';

  @override
  String get graphTabAutoConnections => '연결 목록';

  @override
  String graphCanvasesListHeader(int count) {
    return '지식 지도 목록 ($count)';
  }

  @override
  String get graphEmptyCanvases => '아직 지식 지도가 없습니다.';

  @override
  String get graphEmptyCanvasBody => '캔버스에 작품과 엔티티를 직접 배치해 나만의 관계를 정리해 보세요.';

  @override
  String get graphVaultRequiredTitle => '볼트를 먼저 연결하세요.';

  @override
  String get graphVaultRequiredBody => '지식 지도와 연결 목록은 로컬 볼트에 저장된 기록을 사용합니다.';

  @override
  String get graphBtnCreateFirstCanvas => '첫 지식 지도 만들기';

  @override
  String graphLastModified(String date) {
    return '수정일: $date';
  }

  @override
  String get graphDialogCreateCanvasTitle => '새 지식 지도 만들기';

  @override
  String get graphDialogCreateCanvasLabelTitle => '지도 제목 (예: 리제로 인물 관계도)';

  @override
  String get graphDialogCreateCanvasLabelSlug => 'URL 슬러그 (예: re-zero)';

  @override
  String get graphDialogCreateCanvasBtnCreate => '생성';

  @override
  String get filterScopeAll => '전체';

  @override
  String get filterAddArchive => '아카이브';

  @override
  String get filterAllMedia => '매체 전체';

  @override
  String get filterStatusHelp =>
      '💡  매체(만화, 게임 등)를 선택하시면 세부 상태(완결여부, 플레이/감상 상태) 필터가 활성화됩니다.';

  @override
  String filterEntityGalleryTitle(String scopeLabel) {
    return '📂  $scopeLabel 아카이브 갤러리';
  }

  @override
  String get filterLabelWorkStatus => '작품 상태';

  @override
  String get filterLabelMyStatus => '나의 상태';

  @override
  String get workInfoEditTitle => '작품 정보 편집';

  @override
  String get archiveCompletionTitle => '기록 완성도';

  @override
  String get labelMetadata => '메타데이터';

  @override
  String get previewNoTags => '설정된 태그가 없습니다';

  @override
  String get helpMemoEditInBody => '메모 · 본문에서 편집';

  @override
  String get helpMemoWriteInBody => '상세 기록은 우측 기록 본문에서 작성하세요';

  @override
  String get slotCast => '출연';

  @override
  String get slotGallery => '갤러리';

  @override
  String get slotSynopsis => '시놉시스';

  @override
  String get slotQuotes => '명장면';

  @override
  String get slotMemo => '감상';

  @override
  String get toolbarTemplates => '템플릿';

  @override
  String get toolbarExportHtml => 'HTML 보내기';

  @override
  String get toolbarDialogTemplateTitle => '기록 템플릿';

  @override
  String get actionReset => '기본값';

  @override
  String get actionDeleteMd => 'md 삭제';

  @override
  String get yearSuffix => '년';

  @override
  String get ratingPending => '⏳ 평가 대기';

  @override
  String get libApplyNoChanges => '변경 사항이 없습니다.';

  @override
  String libApplyAdded(String names) {
    return '「$names」에 담았습니다';
  }

  @override
  String libApplyRemoved(String names) {
    return '「$names」에서 제거했습니다 (볼트 기록 유지)';
  }

  @override
  String get templateApplyWarnTitle => '템플릿 적용';

  @override
  String get templateApplyWarnContent => '현재 기록 본문을 템플릿으로 바꿉니다. 계속할까요?';

  @override
  String get templateApplyConfirm => '적용';

  @override
  String templateAppliedSnack(String name) {
    return '「$name」 템플릿을 적용했습니다.';
  }

  @override
  String get htmlExportCannotCreate => 'HTML 파일을 만들 수 없습니다.';

  @override
  String get htmlExportFailed => 'HTML 내보내기 실패';

  @override
  String get htmlExportSuccessOpened => 'HTML을 저장하고 열었습니다.';

  @override
  String htmlExportSuccessSaved(String path) {
    return 'HTML을 저장했습니다: $path';
  }

  @override
  String get resetToDefaultsSuccess => '사전 기본값으로 되돌렸습니다. (work_id는 유지)';

  @override
  String get htmlExportSaveFirst => 'HTML보내기 전에 md를 저장해 주세요.';
}
