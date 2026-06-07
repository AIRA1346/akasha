import 'akasha_item.dart';
import 'format_slot.dart';

/// 그리드 1칸 = IP 1장 (대표 item + 전체 매체 슬롯)
class BrowseCard {
  final AkashaItem item;
  final List<FormatSlot> formatSlots;
  final String? franchiseId;

  const BrowseCard({
    required this.item,
    this.formatSlots = const [],
    this.franchiseId,
  });
}
