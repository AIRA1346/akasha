import 'dart:async';

import '../../../core/archiving/entity_anchor.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/link_candidate_service.dart';

/// 프리뷰 → 워크벤치 연결 픽 pending 상태 (HomeShellController 위임).
class HomePreviewLinkCoordinator {
  HomePreviewLinkCoordinator({
    required this.rebuild,
    required this.workPreviewItem,
    required this.entityPreviewItem,
    required this.isRegistryOnlyPreview,
    required this.archiveRegistryWorkFromPreview,
    required this.openWorkFromPreview,
    required this.openEntityFromPreview,
  });

  final void Function() rebuild;
  final AkashaItem? Function() workPreviewItem;
  final UserCatalogEntity? Function() entityPreviewItem;
  final bool Function(AkashaItem item) isRegistryOnlyPreview;
  final Future<void> Function() archiveRegistryWorkFromPreview;
  final Future<void> Function() openWorkFromPreview;
  final Future<void> Function() openEntityFromPreview;

  EntityAnchorType? pendingWorkEntityLinkType;
  String? pendingWorkEntityLinkWorkId;
  LinkCandidate? pendingWorkEntityLinkCandidate;
  bool pendingWorkLinkPick = false;

  EntityAnchorType? pendingEntityEntityLinkType;
  String? pendingEntityLinkEntityId;
  bool pendingEntityWorkLinkPick = false;

  void clearPendingWork() {
    if (pendingWorkEntityLinkType == null &&
        pendingWorkEntityLinkWorkId == null &&
        pendingWorkEntityLinkCandidate == null &&
        !pendingWorkLinkPick) {
      return;
    }
    pendingWorkEntityLinkType = null;
    pendingWorkEntityLinkWorkId = null;
    pendingWorkEntityLinkCandidate = null;
    pendingWorkLinkPick = false;
    rebuild();
  }

  void clearPendingEntity() {
    if (pendingEntityEntityLinkType == null &&
        pendingEntityLinkEntityId == null &&
        !pendingEntityWorkLinkPick) {
      return;
    }
    pendingEntityEntityLinkType = null;
    pendingEntityLinkEntityId = null;
    pendingEntityWorkLinkPick = false;
    rebuild();
  }

  void openWorkFromPreviewToConnect(EntityAnchorType type) {
    unawaited(_openWorkFromPreviewToConnect(type: type, candidate: null, pickWork: false));
  }

  void openWorkFromPreviewToConnectWork() {
    unawaited(_openWorkFromPreviewToConnect(type: null, candidate: null, pickWork: true));
  }

  void openWorkFromPreviewToConnectSuggested(LinkCandidate candidate) {
    unawaited(_openWorkFromPreviewToConnect(
      type: candidate.anchorType,
      candidate: candidate,
      pickWork: false,
    ));
  }

  Future<void> _openWorkFromPreviewToConnect({
    EntityAnchorType? type,
    LinkCandidate? candidate,
    required bool pickWork,
  }) async {
    final item = workPreviewItem();
    if (item == null) return;
    if (isRegistryOnlyPreview(item)) {
      await archiveRegistryWorkFromPreview();
    }
    final updated = workPreviewItem();
    if (updated == null) return;
    pendingWorkEntityLinkType = pickWork ? null : type;
    pendingWorkEntityLinkWorkId = updated.workId;
    pendingWorkEntityLinkCandidate = candidate;
    pendingWorkLinkPick = pickWork;
    await openWorkFromPreview();
  }

  void openEntityFromPreviewToConnect(EntityAnchorType type) {
    unawaited(_openEntityFromPreviewToConnect(type: type, pickWork: false));
  }

  void openEntityFromPreviewToConnectWork() {
    unawaited(_openEntityFromPreviewToConnect(pickWork: true));
  }

  Future<void> _openEntityFromPreviewToConnect({
    EntityAnchorType? type,
    required bool pickWork,
  }) async {
    final entity = entityPreviewItem();
    if (entity == null) return;
    pendingEntityEntityLinkType = pickWork ? null : type;
    pendingEntityLinkEntityId = entity.entityId;
    pendingEntityWorkLinkPick = pickWork;
    await openEntityFromPreview();
  }
}
