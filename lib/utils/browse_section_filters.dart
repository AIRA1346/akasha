import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../services/franchise_registry.dart';
import 'status_helpers.dart';

/// 감상 예정 보관함 — 프랜차이즈는 구성 매체 중 하나라도 watchlist면 포함
bool isWatchlistBrowseCard(BrowseCard card, List<AkashaItem> allUserItems) {
  final franchiseId = card.franchiseId;
  if (franchiseId != null) {
    final hasUserMember = allUserItems.any(
      (item) => FranchiseRegistry.groupFor(item.workId)?.id == franchiseId,
    );
    if (hasUserMember) {
      return allUserItems.any((item) {
        if (FranchiseRegistry.groupFor(item.workId)?.id != franchiseId) {
          return false;
        }
        return isWatchlistItem(item);
      });
    }
  }
  return isWatchlistItem(card.item);
}

List<BrowseCard> filterWatchlistCards(
  List<BrowseCard> cards,
  List<AkashaItem> allUserItems,
) {
  return cards.where((c) => isWatchlistBrowseCard(c, allUserItems)).toList();
}

List<BrowseCard> filterLibraryCards(
  List<BrowseCard> cards,
  List<AkashaItem> allUserItems,
) {
  return cards
      .where((c) => !isWatchlistBrowseCard(c, allUserItems))
      .toList();
}
