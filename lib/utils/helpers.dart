import '../models/browse_card.dart';
import '../models/category_descriptor.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../core/archiving/archive_record_contract.dart';

// ════════════════════════════════════════════════════════════════
//  팩토리 헬퍼 & 유틸리티 함수
// ════════════════════════════════════════════════════════════════

/// 카테고리에 따라 올바른 서브클래스 인스턴스를 생성하는 팩토리.
AkashaItem createItem({
  required String workId,
  required String title,
  required MediaCategory category,
  AppDomain? domain,
  String? workStatus,
  String? myStatus,
  String creator = '',
  int? releaseYear,
  double rating = 0.0,
  String? posterPath,
  String description = '',
  List<String>? memorableQuotes,
  String review = '',
  bool isHallOfFame = false,
  List<String>? tags,
  String bodyRaw = '',
  ArchiveRecordMetadata? recordMetadata,
}) {
  final resolvedDomain = domain ?? AppDomain.subculture;
  if (CategoryRegistry.isContentType(category)) {
    final item = ContentItem(
      workId: workId,
      title: title,
      category: category,
      domain: resolvedDomain,
      creator: creator,
      releaseYear: releaseYear,
      rating: rating,
      posterPath: posterPath,
      description: description,
      memorableQuotes: memorableQuotes,
      review: review,
      isHallOfFame: isHallOfFame,
      tags: tags,
      bodyRaw: bodyRaw,
      recordMetadata: recordMetadata,
    );
    if (workStatus != null) item.setWorkStatus(workStatus);
    if (myStatus != null) item.setMyStatus(myStatus);
    return item;
  } else {
    final item = GameItem(
      workId: workId,
      title: title,
      domain: resolvedDomain,
      creator: creator,
      releaseYear: releaseYear,
      rating: rating,
      posterPath: posterPath,
      description: description,
      memorableQuotes: memorableQuotes,
      review: review,
      isHallOfFame: isHallOfFame,
      tags: tags,
      bodyRaw: bodyRaw,
      recordMetadata: recordMetadata,
    );
    if (workStatus != null) item.setWorkStatus(workStatus);
    if (myStatus != null) item.setMyStatus(myStatus);
    return item;
  }
}

/// 특정 카테고리에 해당하는 작품 상태 옵션 목록을 반환.
List<String> workStatusOptionsFor(MediaCategory category) {
  if (CategoryRegistry.isContentType(category)) {
    return ContentWorkStatus.values.map((e) => e.label).toList();
  }
  return GameWorkStatus.values.map((e) => e.label).toList();
}

/// 특정 카테고리에 해당하는 나의 상태 옵션 목록을 반환.
List<String> myStatusOptionsFor(MediaCategory category) {
  if (CategoryRegistry.isContentType(category)) {
    return ContentMyStatus.values.map((e) => e.label).toList();
  }
  return GameMyStatus.values.map((e) => e.label).toList();
}

/// 정렬 기준 열거형
enum SortCriteria {
  /// curated 서재 — `memberOrder` SSOT (DnD-B·E9와 동일)
  manualOrder('Manual Order'),
  titleAsc('By Name'),
  ratingDesc('Highest Rating'),
  recentlyAdded('Recently Added'),
  yearDesc('Release Year');

  final String label;
  const SortCriteria(this.label);

  bool get isManualOrder => this == SortCriteria.manualOrder;

  /// filter·대시보드 카탈로그 (직접 배치 순 제외)
  static const List<SortCriteria> standardViewCriteria = [
    titleAsc,
    ratingDesc,
    recentlyAdded,
    yearDesc,
  ];

  /// curated 서재 메인 그리드
  static const List<SortCriteria> curatedLibraryCriteria = [
    manualOrder,
    titleAsc,
    ratingDesc,
    recentlyAdded,
    yearDesc,
  ];
}

/// 정렬 기준에 따라 아이템 리스트를 정렬하여 반환
List<AkashaItem> sortItems(List<AkashaItem> items, SortCriteria criteria) {
  final sorted = List<AkashaItem>.from(items);
  switch (criteria) {
    case SortCriteria.manualOrder:
      break;
    case SortCriteria.titleAsc:
      sorted.sort((a, b) => a.title.compareTo(b.title));
    case SortCriteria.ratingDesc:
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
    case SortCriteria.recentlyAdded:
      sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    case SortCriteria.yearDesc:
      sorted.sort((a, b) => (b.releaseYear ?? 0).compareTo(a.releaseYear ?? 0));
  }
  return sorted;
}

/// BrowseCard 리스트 정렬 (대표 item 기준)
List<BrowseCard> sortBrowseCards(
  List<BrowseCard> cards,
  SortCriteria criteria,
) {
  final sorted = List<BrowseCard>.from(cards);
  int compare(AkashaItem a, AkashaItem b) {
    switch (criteria) {
      case SortCriteria.manualOrder:
        return 0;
      case SortCriteria.titleAsc:
        return a.title.compareTo(b.title);
      case SortCriteria.ratingDesc:
        return b.rating.compareTo(a.rating);
      case SortCriteria.recentlyAdded:
        return b.addedAt.compareTo(a.addedAt);
      case SortCriteria.yearDesc:
        return (b.releaseYear ?? 0).compareTo(a.releaseYear ?? 0);
    }
  }

  sorted.sort((a, b) => compare(a.item, b.item));
  return sorted;
}

/// 이미지 URL이 유효한 인터넷 이미지 주소 형태인지 검증
bool isValidImageUrl(String text) {
  if (!text.startsWith('http://') && !text.startsWith('https://')) return false;
  if (text.length > 2048) return false;

  final lower = text.toLowerCase();

  // 일반적인 이미지 확장자 포함 여부
  if (lower.contains('.jpg') ||
      lower.contains('.jpeg') ||
      lower.contains('.png') ||
      lower.contains('.webp') ||
      lower.contains('.gif')) {
    return true;
  }

  // 자주 쓰이는 신뢰할 수 있는 CDN 도메인
  if (lower.contains('gstatic.com/images') ||
      lower.contains('yes24.com/goods') ||
      lower.contains('kyobobook.co.kr') ||
      lower.contains('steamstatic.com') ||
      lower.contains('akamaihd.net') ||
      lower.contains('anilist.co/file/anilistcdn')) {
    return true;
  }

  try {
    final uri = Uri.parse(text);
    return uri.hasAbsolutePath;
  } catch (_) {
    return false;
  }
}
