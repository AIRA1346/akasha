import '../models/enums.dart';
import '../models/akasha_item.dart';

// ════════════════════════════════════════════════════════════════
//  팩토리 헬퍼 & 유틸리티 함수
// ════════════════════════════════════════════════════════════════

/// 카테고리에 따라 올바른 서브클래스 인스턴스를 생성하는 팩토리.
AkashaItem createItem({
  required String workId,
  required String title,
  required MediaCategory category,
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
}) {
  if (category.isContentType) {
    final item = ContentItem(
      workId: workId,
      title: title,
      category: category,
      creator: creator,
      releaseYear: releaseYear,
      rating: rating,
      posterPath: posterPath,
      description: description,
      memorableQuotes: memorableQuotes,
      review: review,
      isHallOfFame: isHallOfFame,
      tags: tags,
    );
    if (workStatus != null) item.setWorkStatus(workStatus);
    if (myStatus != null) item.setMyStatus(myStatus);
    return item;
  } else {
    final item = GameItem(
      workId: workId,
      title: title,
      creator: creator,
      releaseYear: releaseYear,
      rating: rating,
      posterPath: posterPath,
      description: description,
      memorableQuotes: memorableQuotes,
      review: review,
      isHallOfFame: isHallOfFame,
      tags: tags,
    );
    if (workStatus != null) item.setWorkStatus(workStatus);
    if (myStatus != null) item.setMyStatus(myStatus);
    return item;
  }
}

/// 특정 카테고리에 해당하는 작품 상태 옵션 목록을 반환.
List<String> workStatusOptionsFor(MediaCategory category) {
  if (category.isContentType) {
    return ContentWorkStatus.values.map((e) => e.label).toList();
  }
  return GameWorkStatus.values.map((e) => e.label).toList();
}

/// 특정 카테고리에 해당하는 나의 상태 옵션 목록을 반환.
List<String> myStatusOptionsFor(MediaCategory category) {
  if (category.isContentType) {
    return ContentMyStatus.values.map((e) => e.label).toList();
  }
  return GameMyStatus.values.map((e) => e.label).toList();
}

/// 정렬 기준 열거형
enum SortCriteria {
  titleAsc('작품/제목명 순'),
  ratingDesc('별점 높은 순'),
  recentlyAdded('최근 추가 순'),
  yearDesc('출시 연도 순');

  final String label;
  const SortCriteria(this.label);
}

/// 정렬 기준에 따라 아이템 리스트를 정렬하여 반환
List<AkashaItem> sortItems(List<AkashaItem> items, SortCriteria criteria) {
  final sorted = List<AkashaItem>.from(items);
  switch (criteria) {
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
