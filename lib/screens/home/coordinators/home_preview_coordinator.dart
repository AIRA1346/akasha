import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/vault_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/detail/detail_archive_save.dart';
import '../../../services/link_candidate_service.dart';
import '../../../services/works_registry.dart';
import '../../../utils/vault_work_presence.dart';
import '../home_auto_archive.dart';
import '../home_registry_archive.dart';
import '../preview_frame.dart';
import '../../../utils/app_l10n.dart';

/// Home Work/Entity 프리뷰 스택·복귀 스냅샷·연결 픽 pending.
class HomePreviewCoordinator {
  HomePreviewCoordinator({
    required this.hostContext,
    required this.vault,
    required this.rebuild,
    required this.resolveItemForOpen,
    required this.openBrowseItemInWorkbench,
    required this.openEntityInWorkbench,
    required this.showBrowseInWorkbench,
    required this.getVaultItems,
    required this.recordWorkExploration,
    required this.recordEntityExploration,
    required this.showSnack,
    required this.onWorkPersisted,
    required this.resolveEntity,
  });

  final BuildContext Function() hostContext;
  final VaultPort vault;
  final void Function() rebuild;
  final AkashaItem Function(AkashaItem item) resolveItemForOpen;
  final void Function(AkashaItem item) openBrowseItemInWorkbench;
  final Future<void> Function(UserCatalogEntity entity) openEntityInWorkbench;
  final Future<void> Function() showBrowseInWorkbench;
  final List<AkashaItem> Function() getVaultItems;
  final void Function(String workId) recordWorkExploration;
  final void Function(String entityId) recordEntityExploration;
  final void Function(String message) showSnack;
  final Future<void> Function(AkashaItem item) onWorkPersisted;
  final UserCatalogEntity? Function(String entityId) resolveEntity;

  PreviewTarget _previewTarget = NoPreviewTarget.instance;
  PreviewTarget get previewTarget => _previewTarget;
  final List<PreviewTarget> _backStack = [];
  PreviewReturnSnapshot? _returnSnapshot;

  AkashaItem? get workPreviewItem => switch (previewTarget) {
    WorkPreviewTarget(:final item) => item,
    _ => null,
  };

  UserCatalogEntity? get entityPreviewItem => switch (previewTarget) {
    EntityPreviewTarget(:final entity) => entity,
    _ => null,
  };

  bool get hasOpenPreview => previewTarget is! NoPreviewTarget;

  bool get canPopPreview => _backStack.isNotEmpty;

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
    unawaited(
      _openWorkFromPreviewToConnect(
        type: type,
        candidate: null,
        pickWork: false,
      ),
    );
  }

  void openWorkFromPreviewToConnectWork() {
    unawaited(
      _openWorkFromPreviewToConnect(
        type: null,
        candidate: null,
        pickWork: true,
      ),
    );
  }

  void openWorkFromPreviewToConnectSuggested(LinkCandidate candidate) {
    unawaited(
      _openWorkFromPreviewToConnect(
        type: candidate.anchorType,
        candidate: candidate,
        pickWork: false,
      ),
    );
  }

  Future<void> _openWorkFromPreviewToConnect({
    EntityAnchorType? type,
    LinkCandidate? candidate,
    required bool pickWork,
  }) async {
    final item = workPreviewItem;
    if (item == null) return;
    if (VaultWorkPresence.isRegistryOnlyPreview(item, getVaultItems())) {
      await archiveRegistryWorkFromPreview();
    }
    final updated = workPreviewItem;
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
    final entity = entityPreviewItem;
    if (entity == null) return;
    pendingEntityEntityLinkType = pickWork ? null : type;
    pendingEntityLinkEntityId = entity.entityId;
    pendingEntityWorkLinkPick = pickWork;
    await openEntityFromPreview();
  }

  void openWorkPreview(AkashaItem item, {bool push = false}) {
    if (!push) {
      clearReturnSnapshot();
    }
    final resolved = resolveItemForOpen(item);
    if (push) {
      _pushCurrentIfOpen();
    } else {
      _backStack.clear();
    }
    _previewTarget = WorkPreviewTarget(resolved);
    recordWorkExploration(resolved.workId);
    rebuild();
  }

  void openEntityPreview(UserCatalogEntity entity, {bool push = false}) {
    if (!push) {
      clearReturnSnapshot();
    }
    if (push) {
      _pushCurrentIfOpen();
    } else {
      _backStack.clear();
    }
    _previewTarget = EntityPreviewTarget(entity);
    recordEntityExploration(entity.entityId);
    rebuild();
  }

  void closeAllPreviews() {
    final hadPreview = hasOpenPreview;
    _previewTarget = NoPreviewTarget.instance;
    _backStack.clear();
    clearReturnSnapshot();
    if (hadPreview) rebuild();
  }

  void navigateWorkPreview(AkashaItem item) {
    if (hasOpenPreview) {
      previewLinkedWork(item);
    } else {
      openWorkPreview(item);
    }
  }

  void navigateEntityPreview(UserCatalogEntity entity) {
    if (hasOpenPreview) {
      previewLinkedEntity(entity);
    } else {
      openEntityPreview(entity);
    }
  }

  void popPreview() {
    if (_backStack.isEmpty) {
      closeAllPreviews();
      return;
    }
    _restoreTarget(_backStack.removeLast());
    rebuild();
  }

  void previewLinkedWork(AkashaItem work) => openWorkPreview(work, push: true);

  void previewLinkedEntity(UserCatalogEntity entity) =>
      openEntityPreview(entity, push: true);

  void previewRegistryWork(RegistryWork work) {
    navigateWorkPreview(HomeAutoArchive.itemFromRegistryWork(work));
  }

  Future<void> openWorkFromPreview() async {
    final item = workPreviewItem;
    if (item == null) return;
    if (VaultWorkPresence.isRegistryOnlyPreview(item, getVaultItems())) {
      await archiveRegistryWorkFromPreview();
      return;
    }
    final snapshot = _captureReturnSnapshot();
    closeAllPreviews();
    _returnSnapshot = snapshot;
    openBrowseItemInWorkbench(item);
    rebuild();
  }

  /// 그리드 더블클릭 등 프리뷰 없이 작품 상세로 바로 진입.
  Future<void> openWorkDetail(AkashaItem item) async {
    var resolved = resolveItemForOpen(item);
    if (VaultWorkPresence.isRegistryOnlyPreview(resolved, getVaultItems())) {
      _previewTarget = WorkPreviewTarget(resolved);
      await archiveRegistryWorkFromPreview();
      final updated = workPreviewItem;
      if (updated == null ||
          VaultWorkPresence.isRegistryOnlyPreview(updated, getVaultItems())) {
        return;
      }
      resolved = updated;
    }
    clearReturnSnapshot();
    closeAllPreviews();
    openBrowseItemInWorkbench(resolved);
    recordWorkExploration(resolved.workId);
    rebuild();
  }

  Future<void> openEntityFromPreview() async {
    final entity = entityPreviewItem;
    if (entity == null) return;
    final snapshot = _captureReturnSnapshot();
    closeAllPreviews();
    _returnSnapshot = snapshot;
    await openEntityInWorkbench(entity);
    rebuild();
  }

  Future<void> archiveRegistryWorkFromPreview() async {
    final item = workPreviewItem;
    if (item == null) return;

    final l10n = lookupAppL10n(hostContext());
    if (vault.vaultPath == null) {
      showSnack(l10n?.errorConnectVaultFirst ?? '볼트를 먼저 연결해 주세요.');
      return;
    }

    final registryWork = WorksRegistry.getWorkById(item.workId);
    final AkashaItem saved;
    if (registryWork != null) {
      saved = await HomeRegistryArchive.persistRegistryWork(
        registryWork,
        vault: vault,
        onDemoAdd: (_) {},
      );
    } else {
      saved = await DetailArchiveSave.save(item);
    }

    await onWorkPersisted(saved);

    openWorkPreview(resolveItemForOpen(saved));
    showSnack(
      l10n != null
          ? l10n.successArchivedWork(saved.title)
          : '"${saved.title}"을(를) 아카이브했습니다.',
    );
  }

  void maybeClearReturnForWork(String workId) {
    final snapshot = _returnSnapshot;
    if (snapshot == null) return;
    if (snapshot.current case WorkPreviewTarget(
      :final item,
    ) when item.workId == workId) {
      clearReturnSnapshot();
    }
  }

  void maybeClearReturnForEntity(String entityId) {
    final snapshot = _returnSnapshot;
    if (snapshot == null) return;
    if (snapshot.current case EntityPreviewTarget(
      :final entity,
    ) when entity.entityId == entityId) {
      clearReturnSnapshot();
    }
  }

  Future<void> maybeReturnAfterSave({String? workId, String? entityId}) async {
    final snapshot = _returnSnapshot;
    if (snapshot == null) return;

    final matches = switch (snapshot.current) {
      WorkPreviewTarget(:final item) => workId != null && item.workId == workId,
      EntityPreviewTarget(:final entity) =>
        entityId != null && entity.entityId == entityId,
      _ => false,
    };
    if (!matches) return;

    clearReturnSnapshot();
    _backStack
      ..clear()
      ..addAll(snapshot.backStack.map(_resolveTarget));
    _restoreTarget(_resolveTarget(snapshot.current));
    await showBrowseInWorkbench();
    rebuild();
  }

  void clearReturnSnapshot() {
    _returnSnapshot = null;
  }

  PreviewTarget? _captureCurrentTarget() {
    return previewTarget is NoPreviewTarget ? null : previewTarget;
  }

  void _pushCurrentIfOpen() {
    final current = _captureCurrentTarget();
    if (current != null) {
      _backStack.add(current);
    }
  }

  void _restoreTarget(PreviewTarget target) {
    _previewTarget = target;
  }

  PreviewReturnSnapshot? _captureReturnSnapshot() {
    final current = _captureCurrentTarget();
    if (current == null) return null;
    return PreviewReturnSnapshot(
      current: current,
      backStack: List<PreviewTarget>.from(_backStack),
    );
  }

  PreviewTarget _resolveTarget(PreviewTarget target) {
    return switch (target) {
      WorkPreviewTarget(:final item) => WorkPreviewTarget(
        resolveItemForOpen(item),
      ),
      EntityPreviewTarget(:final entity) => EntityPreviewTarget(
        resolveEntity(entity.entityId) ?? entity,
      ),
      _ => target,
    };
  }
}
