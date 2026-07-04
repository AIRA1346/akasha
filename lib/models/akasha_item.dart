import '../core/archiving/archive_record_contract.dart';
import '../core/archiving/entity_anchor.dart';
import 'category_descriptor.dart';
import 'enums.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 다형성 데이터 모델 (확장 버전)
// ════════════════════════════════════════════════════════════════

/// 아카이브 아이템의 추상 베이스 클래스.
///
/// 모든 아이템은 공통 메타데이터(제목, 카테고리, 작가, 평점 등)를 가지며,
/// 작품 상태/나의 상태는 서브클래스에서 카테고리별로 타입-세이프하게 관리한다.
abstract class AkashaItem {
  String workId; // 공통 사전 DB 조인용 식별값
  String title;
  final MediaCategory category;
  AppDomain domain; // 대분류 속성 필드 추가
  String? filePath; // 로컬 볼트 내 마크다운 파일 절대 경로

  // ── 확장 메타데이터 (공통 레지스트리에서 융합되는 항목들이나 마크다운 파싱 시 임시 저장 가능) ──
  String creator;
  int? releaseYear;
  double rating;
  String? posterPath;
  String description;
  List<String> memorableQuotes;
  String review;
  bool isHallOfFame;
  List<String> tags;
  DateTime addedAt;

  /// frontmatter 이후 마크다운 원문 (커스텀 섹션 round-trip)
  String bodyRaw;

  /// Additive v3 frontmatter metadata that should survive app rewrites.
  ArchiveRecordMetadata recordMetadata;

  AkashaItem({
    required this.workId,
    required this.title,
    required this.category,
    required this.domain,
    this.creator = '',
    this.releaseYear,
    this.rating = 0.0,
    this.posterPath,
    this.description = '',
    List<String>? memorableQuotes,
    this.review = '',
    this.isHallOfFame = false,
    List<String>? tags,
    DateTime? addedAt,
    this.bodyRaw = '',
    ArchiveRecordMetadata? recordMetadata,
  }) : memorableQuotes = memorableQuotes ?? [],
       tags = tags ?? [],
       addedAt = addedAt ?? DateTime.now(),
       recordMetadata = recordMetadata ?? ArchiveRecordMetadata.empty;

  // ── 상태 접근 (서브클래스에서 구현) ──

  /// 현재 작품 상태 라벨
  String get workStatusLabel;

  /// 현재 나의 상태 라벨
  String get myStatusLabel;

  /// 이 카테고리에서 선택 가능한 작품 상태 라벨 목록
  List<String> get workStatusOptions;

  /// 이 카테고리에서 선택 가능한 나의 상태 라벨 목록
  List<String> get myStatusOptions;

  /// 라벨 문자열로 작품 상태를 변경
  void setWorkStatus(String label);

  /// 라벨 문자열로 나의 상태를 변경
  void setMyStatus(String label);

  // ── 편의 getter ──

  /// 카드에 표시할 복합 상태 텍스트 (예: "전부 봄 (완결)")
  String get combinedStatusLabel => '$myStatusLabel ($workStatusLabel)';
}

// ────────────────────────────────────────────
//  콘텐츠 계열 아이템 (만화, 책, 애니메이션)
// ────────────────────────────────────────────

class ContentItem extends AkashaItem {
  ContentWorkStatus workStatus;
  ContentMyStatus myStatus;

  ContentItem({
    required super.workId,
    required super.title,
    required super.category,
    required super.domain,
    this.workStatus = ContentWorkStatus.serializing,
    this.myStatus = ContentMyStatus.notStarted,
    super.creator,
    super.releaseYear,
    super.rating,
    super.posterPath,
    super.description,
    super.memorableQuotes,
    super.review,
    super.isHallOfFame,
    super.tags,
    super.addedAt,
    super.bodyRaw,
    super.recordMetadata,
  }) : assert(
         CategoryRegistry.isContentType(category),
         'Cannot assign game category to a content item.',
       );

  @override
  String get workStatusLabel => workStatus.label;
  @override
  String get myStatusLabel => myStatus.label;

  @override
  List<String> get workStatusOptions =>
      ContentWorkStatus.values.map((e) => e.label).toList();
  @override
  List<String> get myStatusOptions =>
      ContentMyStatus.values.map((e) => e.label).toList();

  @override
  void setWorkStatus(String label) {
    workStatus = ContentWorkStatus.fromStorage(label);
  }

  @override
  void setMyStatus(String label) {
    myStatus = ContentMyStatus.fromStorage(label);
  }
}

// ────────────────────────────────────────────
//  게임 아이템
// ────────────────────────────────────────────

class GameItem extends AkashaItem {
  GameWorkStatus workStatus;
  GameMyStatus myStatus;

  GameItem({
    required super.workId,
    required super.title,
    required super.domain,
    this.workStatus = GameWorkStatus.released,
    this.myStatus = GameMyStatus.backlog,
    super.creator,
    super.releaseYear,
    super.rating,
    super.posterPath,
    super.description,
    super.memorableQuotes,
    super.review,
    super.isHallOfFame,
    super.tags,
    super.addedAt,
    super.bodyRaw,
    super.recordMetadata,
  }) : super(category: MediaCategory.game);

  @override
  String get workStatusLabel => workStatus.label;
  @override
  String get myStatusLabel => myStatus.label;

  @override
  List<String> get workStatusOptions =>
      GameWorkStatus.values.map((e) => e.label).toList();
  @override
  List<String> get myStatusOptions =>
      GameMyStatus.values.map((e) => e.label).toList();

  @override
  void setWorkStatus(String label) {
    workStatus = GameWorkStatus.fromStorage(label);
  }

  @override
  void setMyStatus(String label) {
    myStatus = GameMyStatus.fromStorage(label);
  }
}

// ────────────────────────────────────────────
//  일반 엔티티 아이템 (인물, 사건, 개념 등)
// ────────────────────────────────────────────

class EntityItem extends AkashaItem {
  final EntityAnchorType entityType;
  final String entityId;

  EntityItem({
    required this.entityType,
    required String entityId,
    required super.title,
    required super.category,
    required super.domain,
    super.creator = '',
    super.releaseYear,
    super.rating = 0.0,
    super.posterPath,
    super.description = '',
    super.memorableQuotes,
    super.review = '',
    super.isHallOfFame = false,
    super.tags,
    super.addedAt,
    super.bodyRaw = '',
    super.recordMetadata,
  }) : entityId = entityId,
       super(workId: entityId);

  @override
  String get workStatusLabel => '';
  @override
  String get myStatusLabel => '';

  @override
  List<String> get workStatusOptions => const [];
  @override
  List<String> get myStatusOptions => const [];

  @override
  void setWorkStatus(String label) {}
  @override
  void setMyStatus(String label) {}
}
