import 'package:flutter/material.dart';

import '../../models/akasha_item.dart';
import '../../models/format_slot.dart';
import '../../services/franchise_registry.dart';
import '../../services/user_registry_preferences.dart';
import '../../widgets/format_chip_row.dart';
import 'detail_section_title.dart';

/// 프랜차이즈(IP) 매체 섹션
class DetailFranchiseSection extends StatelessWidget {
  final AkashaItem item;
  final List<FormatSlot> formatSlots;
  final VoidCallback onPreferencesChanged;
  final Future<void> Function() onReloadFormatSlots;
  final void Function(String message) showSnackBar;

  const DetailFranchiseSection({
    super.key,
    required this.item,
    required this.formatSlots,
    required this.onPreferencesChanged,
    required this.onReloadFormatSlots,
    required this.showSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    if (item.workId.isEmpty) return const SizedBox.shrink();

    final group = FranchiseRegistry.groupFor(item.workId);
    if (group == null) return const SizedBox.shrink();

    final tracksMulti =
        UserRegistryPreferences.instance.tracksMultipleFormats(group.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          detailSectionTitle('🔗', '같은 작품 · 다른 매체'),
          Text(
            '그리드에는 「${group.displayName}」 카드 1장으로 표시됩니다.',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '검색에서 매체 버전 개별 표시',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              tracksMulti
                  ? '검색에서만 매체 버전이 개별 행으로 나타납니다. 그리드는 IP당 1카드입니다.'
                  : '검색에서도 IP당 1행으로 묶어 표시합니다. 그리드는 항상 1카드입니다.',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            value: tracksMulti,
            onChanged: (value) async {
              await UserRegistryPreferences.instance.setTracksMultipleFormats(
                group.id,
                enabled: value,
              );
              onPreferencesChanged();
              showSnackBar(
                value
                    ? '「${group.displayName}」 검색 시 매체별 표시를 켰습니다.'
                    : '「${group.displayName}」 검색 시 IP 통합 표시를 켰습니다.',
              );
            },
          ),
          if (formatSlots.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '포함 매체',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            FormatChipRow(
              slots: formatSlots,
              onHideSlot: (slot) async {
                if (slot.state != FormatSlotState.catalogOnly) return;
                await UserRegistryPreferences.instance.hideWork(slot.workId);
                await onReloadFormatSlots();
                showSnackBar('「${slot.shortLabel}」 매체를 사전에서 숨겼습니다.');
              },
            ),
          ],
        ],
      ),
    );
  }
}
