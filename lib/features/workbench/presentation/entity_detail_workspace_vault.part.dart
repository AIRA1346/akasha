part of 'entity_detail_workspace.dart';

mixin _EntityDetailWorkspaceVault
    on _EntityDetailWorkspaceStateBase, _EntityDetailWorkspacePersist {
  Future<void> _onVaultDiskChanged() async {
    if (!mounted) return;
    await WorkbenchVaultDiskOps.handleChange(
      action: _connections.evaluateVaultDiskChange(
        filePath: _journal?.storagePath,
        isSaving: _isSaving,
        isDirty: widget.isDirty,
      ),
      mounted: mounted,
      promptRebuild: () => setState(() {}),
      reloadFromDisk: _reloadFromDisk,
    );
  }

  void _applyJournalFromEntry(EntityJournalEntry entry) {
    _applySnapshot(
      EntityDetailWorkspaceSnapshot.fromJournalEntry(
        entity: _entity,
        entry: entry,
        pageView: _pageView,
      ),
    );
    _connections.refreshDiskMtime(_journal?.storagePath);
    _connections.loadLinkNeighbors(
      entity: _entity,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }

  Future<void> _reloadFromDisk({bool silent = false}) async {
    await WorkbenchVaultReloadFlow.run(
      reload: () => _connections.reloadJournalFromDisk(
        storagePath: _journal?.storagePath,
      ),
      onReloaded: (parsed) {
        _applyJournalFromEntry(parsed);
        widget.onDirtyChanged(false);
        widget.onSaved(_entity, parsed, silent: true);
      },
      showSuccess: _showSnack,
      showFailure: _showSnack,
      successMessage: () => WorkbenchVaultReloadMessages.entitySuccess,
      failureMessage: WorkbenchVaultReloadMessages.entityFailure,
      silent: silent,
      isMounted: () => mounted,
    );
  }

  void _dismissExternalChange() {
    _connections.dismissExternalChange(_journal?.storagePath);
  }
}
