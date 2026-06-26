import 'package:flutter/material.dart';

import '../../core/ports/vault_port.dart';
import '../../models/akasha_item.dart';
import '../../models/browse_card.dart';
import '../../models/format_slot.dart';
import '../../services/franchise_registry.dart';
import '../../services/user_registry_preferences.dart';

/// 포스터 카드 숨기기(사전·프랜차이즈·매체) 액션
class HomeRegistryHideActions {
  final VaultPort vault;
  final void Function() onStateChanged;
  final void Function(String message) showMessage;

  const HomeRegistryHideActions({
    required this.vault,
    required this.onStateChanged,
    required this.showMessage,
  });

  Future<void> hideWork(String workId, {String? label}) async {
    if (workId.isEmpty) return;
    await UserRegistryPreferences.instance.hideWork(workId);
    onStateChanged();
    showMessage(
      label != null ? '「$label」 매체를 사전에서 숨겼습니다.' : '사전 항목을 숨겼습니다.',
    );
  }

  Future<void> hideFranchise(String franchiseId) async {
    final group = FranchiseRegistry.groupById(franchiseId);
    if (group == null) return;
    await UserRegistryPreferences.instance.hideFranchise(franchiseId);
    onStateChanged();
    showMessage('「${group.displayName}」 전체를 사전에서 숨겼습니다.');
  }

  VoidCallback? registryHideActionFor(AkashaItem item) {
    if (item.workId.isEmpty) return null;
    if (vault.isArchivedInVault(item)) return null;
    return () => hideWork(item.workId, label: item.title);
  }

  VoidCallback? franchiseHideActionFor(BrowseCard card) {
    final franchiseId = card.franchiseId;
    if (franchiseId == null) return null;
    final hasCatalogSlot = card.formatSlots.any(
      (s) => s.state == FormatSlotState.catalogOnly,
    );
    if (!hasCatalogSlot) return null;
    return () => hideFranchise(franchiseId);
  }

  void Function(FormatSlot slot)? formatSlotHideActionFor(BrowseCard card) {
    if (card.formatSlots.isEmpty) return null;
    return (slot) => hideWork(slot.workId, label: slot.shortLabel);
  }
}
