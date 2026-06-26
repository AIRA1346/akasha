part of 'work_detail_workspace.dart';

mixin _WorkDetailWorkspaceLinks
    on _WorkDetailWorkspaceStateBase, _WorkDetailWorkspacePersist {
  Future<void> _maybeRunPendingEntityLinkPick() async {
    if (!mounted) return;
    await WorkDetailLinkPickOps.runPendingPick(
      context: context,
      pendingWorkId: widget.pendingEntityLinkWorkId,
      pendingWorkLinkPick: widget.pendingWorkLinkPick,
      pendingEntityLinkType: widget.pendingEntityLinkType,
      preselected: widget.pendingEntityLinkCandidate,
      currentWorkId: _item.workId,
      catalog: widget.userCatalog,
      item: _item,
      vaultItems: widget.vaultItems,
      showBodyView: (view) => setState(() => _pageView = view),
      requestWorkLink: _requestWorkLink,
      applySelection: _applyWikiLinkSelection,
      onPendingHandled: widget.onPendingEntityLinkHandled,
    );
  }

  void _openLinkedEntity(UserCatalogEntity entity) {
    WorkbenchLinkedRecordOps.openLinkedEntity(
      entity: entity,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

  void _openLinkedWork(AkashaItem work) {
    WorkbenchLinkedRecordOps.openLinkedWork(
      work: work,
      onWikiLinkTap: widget.onWikiLinkTap,
    );
  }

  Future<void> _requestEntityLinkForType(EntityAnchorType type) =>
      WorkDetailLinkPickOps.runInteractiveEntityPick(
        context: context,
        isMounted: () => mounted,
        catalog: widget.userCatalog,
        type: type,
        workContext: _item,
        vaultItems: widget.vaultItems,
        showBodyView: (view) => setState(() => _pageView = view),
        applySelection: _applyWikiLinkSelection,
      );

  Future<void> _requestWorkLink() => WorkDetailLinkPickOps.runInteractiveWorkPick(
        context: context,
        isMounted: () => mounted,
        vaultItems: widget.vaultItems,
        excludeWorkId: _item.workId,
        showBodyView: (view) => setState(() => _pageView = view),
        applySelection: _applyWikiLinkSelection,
      );

  Future<void> _applyWikiLinkSelection(EntityLinkSelection picked) async {
    await WorkDetailLinkPickOps.applySelection(
      picked: picked,
      pageView: _pageView,
      sectionEditor: _sectionEditorKey.currentState,
      bodyCtrl: _bodyCtrl,
      syncBodyToItem: () => WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl),
      markDirty: _markDirty,
      reloadLinkNeighbors: () => _connections.loadLinkNeighbors(
        work: _item,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      ),
    );
  }

  void _focusSanctumForLinks() => setState(() => _pageView = SanctumPageView.body);

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
