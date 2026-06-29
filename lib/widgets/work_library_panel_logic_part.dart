part of 'work_library_panel.dart';

List<String> _workLibraryPanelEffectiveIds(_WorkLibraryPanelState state) =>
    state.widget.showIpScopeOption && state._useEntireIp
        ? state.widget.entireIpWorkIds
        : state.widget.singleWorkIds;

bool? _workLibraryPanelMembershipCheckState(
  _WorkLibraryPanelState state,
  PersonalLibraryConfig lib,
) {
  final ids = _workLibraryPanelEffectiveIds(state);
  if (ids.isEmpty) return false;
  final contained = state.widget.membership.countContainedWorkIds(lib, ids);
  if (contained == 0) return false;
  if (contained >= ids.length) return true;
  return null;
}

void _syncCheckedFromMembership(_WorkLibraryPanelState state) {
  state._initialChecked = {
    for (final lib in state.widget.membership.curatedLibraries)
      lib.id: _workLibraryPanelMembershipCheckState(state, lib),
  };
  state._checked = Map<String, bool?>.from(state._initialChecked);
}

List<PersonalLibraryConfig> _sortedLibraries(_WorkLibraryPanelState state) {
  final list = List<PersonalLibraryConfig>.from(
    state.widget.membership.curatedLibraries,
  )..sort((a, b) {
      final active = state.widget.activeLibraryId;
      if (active != null) {
        if (a.id == active) return -1;
        if (b.id == active) return 1;
      }
      return a.name.compareTo(b.name);
    });
  return list;
}

bool _workLibraryPanelHasDiff(_WorkLibraryPanelState state) {
  for (final lib in state.widget.membership.curatedLibraries) {
    if (state._checked[lib.id] != state._initialChecked[lib.id]) {
      return true;
    }
  }
  return false;
}

bool _workLibraryPanelHasAddDiff(_WorkLibraryPanelState state) {
  for (final lib in state.widget.membership.curatedLibraries) {
    if (state._checked[lib.id] == true &&
        state._checked[lib.id] != state._initialChecked[lib.id]) {
      return true;
    }
  }
  return false;
}

bool _workLibraryPanelCanApply(_WorkLibraryPanelState state) {
  if (!_workLibraryPanelHasDiff(state) || state._applying) return false;
  if (state.widget.showTitleEditor && _workLibraryPanelHasAddDiff(state)) {
    return state._titleCtrl.text.trim().isNotEmpty;
  }
  return true;
}

Future<void> _workLibraryPanelApply(_WorkLibraryPanelState state) async {
  if (!_workLibraryPanelCanApply(state)) return;
  final onApply = state.widget.onApply;
  if (onApply == null) return;

  state._setApplying(true);
  try {
    final result = await onApply(
      WorkLibraryPanelApplyInput(
        titleOverride: state.widget.showTitleEditor
            ? state._titleCtrl.text.trim()
            : null,
        useEntireIp: state._useEntireIp,
        desiredChecked: state._checked,
        initialChecked: state._initialChecked,
      ),
    );
    if (!state.mounted) return;
    state.widget.onApplied?.call(result);
  } catch (e) {
    if (!state.mounted) return;
    final message =
        e is LibraryApplyException ? e.message : '적용 실패: $e';
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(
          seconds: e is LibraryApplyException && e.vaultMdCreated ? 5 : 3,
        ),
      ),
    );
  } finally {
    if (state.mounted) state._setApplying(false);
  }
}

String? _workLibraryPanelLibrarySubtitle(
  _WorkLibraryPanelState state,
  PersonalLibraryConfig lib,
) {
  final ids = _workLibraryPanelEffectiveIds(state);
  if (ids.length <= 1) return '${lib.memberOrder.length}작';
  final contained = state.widget.membership.countContainedWorkIds(lib, ids);
  if (contained == 0) return '${lib.memberOrder.length}작';
  if (contained < ids.length) {
    return '$contained/${ids.length} 매체 · ${lib.memberOrder.length}작';
  }
  return '${lib.memberOrder.length}작';
}
