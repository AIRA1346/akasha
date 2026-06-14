import '../../../models/akasha_item.dart';
import '../../../models/browse_card.dart';
import '../../../services/franchise_fusion_service.dart';
import '../../../services/franchise_registry.dart';

/// BrowseCard 조립 (IP 포맷 슬롯·franchiseId).
class HomeBrowseCardBuilder {
  static BrowseCard forItem(
    AkashaItem item,
    List<AkashaItem> allUserItems,
  ) {
    final group = FranchiseRegistry.groupFor(item.workId);
    return BrowseCard(
      item: item,
      formatSlots: FranchiseFusionService.formatSlotsForWorkId(
        item.workId,
        allUserItems: allUserItems,
      ),
      franchiseId: group?.id,
    );
  }
}
