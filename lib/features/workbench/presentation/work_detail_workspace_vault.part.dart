part of 'work_detail_workspace.dart';

mixin _WorkDetailWorkspaceVault
    on _WorkDetailWorkspaceStateBase, _WorkDetailWorkspacePersist {
  Future<void> _onVaultDiskChanged() async {
    if (!mounted) return;
    await WorkbenchVaultDiskOps.handleChange(
      action: _connections.evaluateVaultDiskChange(
        filePath: _item.filePath,
        isSaving: _isSaving,
        isDirty: widget.isDirty,
      ),
      mounted: mounted,
      promptRebuild: () => setState(() {}),
      reloadFromDisk: _reloadFromDisk,
    );
  }

  Future<void> _reloadFromDisk({bool silent = false}) async {
    await WorkbenchVaultReloadFlow.run(
      reload: () => _connections.reloadWorkFromDisk(current: _item),
      onReloaded: (reloaded) {
        _applyItem(reloaded, resetPageView: false);
        widget.onDirtyChanged(false);
        widget.onSaved(reloaded, silent: true, dirty: false);
      },
      showSuccess: _showSnack,
      showFailure: _showSnack,
      successMessage: () => WorkbenchVaultReloadMessages.workSuccess,
      failureMessage: WorkbenchVaultReloadMessages.workFailure,
      silent: silent,
      isMounted: () => mounted,
    );
  }

  void _dismissExternalChange() =>
      _connections.dismissExternalChange(_item.filePath);
}
