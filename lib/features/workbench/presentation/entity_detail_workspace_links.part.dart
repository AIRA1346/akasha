part of 'entity_detail_workspace.dart';

mixin _EntityDetailWorkspaceLinks
    on _EntityDetailWorkspaceStateBase, _EntityDetailWorkspacePersist {
  Future<void> _maybeRunPendingEntityLinkPick() async {
    if (!mounted) return;
    await EntityDetailLinkPickOps.runPendingPick(
      context: context,
      pendingEntityId: widget.pendingEntityLinkEntityId,
      pendingWorkLinkPick: widget.pendingEntityWorkLinkPick,
      pendingEntityLinkType: widget.pendingEntityLinkType,
      currentEntityId: _entity.entityId,
      catalog: widget.userCatalog,
      item: _item,
      vaultItems: widget.vaultItems,
      bodyCtrl: _bodyCtrl,
      showBodyView: (view) => setState(() => _pageView = view),
      markDirty: _markDirty,
      reloadLinkNeighbors: () => _connections.loadLinkNeighbors(
        entity: _entity,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      ),
      requestWorkLink: _requestWorkLink,
      onPendingHandled: widget.onPendingEntityLinkHandled,
    );
  }

  Future<void> _requestEntityLinkForType(EntityAnchorType type) async {
    final catalog = widget.userCatalog;
    if (catalog == null || !mounted) return;

    setState(() => _pageView = SanctumPageView.body);

    final picked = await EntityDetailLinkPickOps.requestEntityLinkForType(
      context: context,
      catalog: catalog,
      type: type,
      workContext: _item,
      vaultItems: widget.vaultItems,
    );
    if (!mounted || picked == null) return;
    await _applyWikiLinkSelection(picked);
  }

  Future<void> _requestWorkLink() async {
    if (!mounted) return;

    setState(() => _pageView = SanctumPageView.body);

    final picked = await EntityDetailLinkPickOps.requestWorkLink(
      context: context,
      vaultItems: widget.vaultItems,
    );
    if (!mounted || picked == null) return;
    await _applyWikiLinkSelection(picked);
  }

  Future<void> _applyWikiLinkSelection(EntityLinkSelection picked) async {
    await EntityDetailLinkPickOps.applySelection(
      picked: picked,
      bodyCtrl: _bodyCtrl,
      markDirty: _markDirty,
      reloadLinkNeighbors: () => _connections.loadLinkNeighbors(
        entity: _entity,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      ),
    );
  }

  void _openLinkedEntity(UserCatalogEntity entity) {
    WorkbenchLinkedRecordOps.openLinkedEntity(
      entity: entity,
      onRecordOpenEntity: widget.onRecordOpenEntity,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

  void _openLinkedWork(AkashaItem work) {
    WorkbenchLinkedRecordOps.openLinkedWork(
      work: work,
      onRecordOpenWork: widget.onRecordOpenWork,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

  void _focusSanctumForLinks() {
    setState(() => _pageView = SanctumPageView.body);
  }

  Future<void> _openIncoming(String path) => WorkbenchWorkspaceRecordNav.openIncoming(
        context: context,
        path: path,
        vaultItems: widget.vaultItems,
        userCatalog: widget.userCatalog,
        onRecordOpenWork: widget.onRecordOpenWork,
        onRecordOpenEntity: widget.onRecordOpenEntity,
        onWikiLinkTap: widget.onWikiLinkTap,
      );

  Future<void> _openSameDay(SameDayRecordRef ref) =>
      WorkbenchWorkspaceRecordNav.openSameDay(
        context: context,
        ref: ref,
        vaultItems: widget.vaultItems,
        userCatalog: widget.userCatalog,
        onRecordOpenWork: widget.onRecordOpenWork,
        onRecordOpenEntity: widget.onRecordOpenEntity,
        onWikiLinkTap: widget.onWikiLinkTap,
      );
}
