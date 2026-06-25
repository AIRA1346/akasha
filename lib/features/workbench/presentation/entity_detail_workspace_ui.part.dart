part of 'entity_detail_workspace.dart';

EntityDetailWorkspaceBody buildEntityDetailWorkspaceBody(
  _EntityDetailWorkspaceState state,
) {
  final widget = state.widget;
  final hasJournal = EntityDetailArchiveOps.hasJournal(state._journal);
  final saveLabel = hasJournal ? 'md 저장' : 'journal 생성';

  return EntityDetailWorkspaceBody(
    entity: state._entity,
    preview: state._preview,
    hasJournal: hasJournal,
    saveLabel: saveLabel,
    infoPanelWidth: widget.infoPanelWidth,
    infoPanelLocked: widget.infoPanelLocked,
    posterUrlCtrl: state._posterUrlCtrl,
    bodyCtrl: state._bodyCtrl,
    fileCtrl: state._fileCtrl,
    draftTags: state._draftTags,
    pageView: state._pageView,
    isDirty: widget.isDirty,
    isSaving: state._isSaving,
    externalChangePending: state._externalChangePending,
    lastSavedAt: state._lastSavedAt,
    showAddToLibrary: widget.onAddToLibrary != null,
    linkNeighbors: state._connections.linkNeighbors,
    loadingLinkNeighbors: state._connections.loadingLinkNeighbors,
    loadingIncoming: state._connections.loadingIncoming,
    incomingPaths: state._connections.incomingPaths,
    staleLabelRecordCount: state._connections.staleLabelRecordCount,
    loadingSameDay: state._connections.loadingSameDay,
    sameDayRefs: state._connections.sameDayRefs,
    onClose: widget.onClose,
    onGoKnowledgeGraph: widget.onGoKnowledgeGraph,
    userCatalog: widget.userCatalog,
    linkIndex: widget.linkIndex,
    journalStoragePath: state._journal?.storagePath,
    onWikiLinkTap: widget.onWikiLinkTap,
    onRequestEntityLink: widget.onRequestEntityLink,
    onInfoWidthChanged: widget.onInfoWidthChanged,
    onToggleInfoLock: widget.onToggleInfoLock,
    onPosterTap: state._openPosterCorrection,
    onFocusSanctum: state._focusSanctumForLinks,
    onViewChanged: state._onPageViewChanged,
    onReloadFromDisk: () => state._reloadFromDisk(),
    onDismissExternalChange: state._dismissExternalChange,
    onBodyChanged: state._markDirty,
    onFileChanged: state._markDirty,
    onOpenFileView: state._refreshFileEditor,
    onSave: () => state._saveJournal(),
    onExportHtml: state._exportHtml,
    onAddToLibrary: state._handleAddToLibrary,
    onDeleteArchive: hasJournal ? state._confirmDelete : null,
    onOpenLinkedEntity: state._openLinkedEntity,
    onOpenLinkedWork: state._openLinkedWork,
    onAddEntityLink:
        widget.userCatalog != null ? state._requestEntityLinkForType : null,
    onAddWorkLink: widget.userCatalog != null ? state._requestWorkLink : null,
    onRefreshIncoming: () => state._connections.loadIncoming(
      entity: state._entity,
      journal: state._journal,
      linkIndex: widget.linkIndex,
    ),
    onOpenIncoming: state._openIncoming,
    onOpenSameDay: state._openSameDay,
    onDraftTagsChanged: (tags) {
      state.setState(() => state._draftTags = tags);
      state._updatePreview();
      state._markDirty();
    },
  );
}
