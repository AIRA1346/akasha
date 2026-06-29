part of 'work_library_panel.dart';

Widget _buildWorkLibraryPanelHideSection(_WorkLibraryPanelState state) {
  return ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
    title: Text(
      '표시 안 함',
      style: TextStyle(fontSize: 12, color: AkashaColors.textSecondary),
    ),
    initiallyExpanded: state._hideExpanded,
    onExpansionChanged: state._onHideExpansionChanged,
    children: [
      if (state.widget.onHideFranchise != null)
        ListTile(
          dense: true,
          leading: const Icon(Icons.layers_clear_outlined, size: 18),
          title: const Text(
            'IP 전체 숨기기',
            style: TextStyle(fontSize: 12),
          ),
          onTap: () {
            state.widget.onCancel?.call();
            state.widget.onHideFranchise!();
          },
        ),
      if (state.widget.onHideFromRegistry != null)
        ListTile(
          dense: true,
          leading: const Icon(Icons.visibility_off_outlined, size: 18),
          title: Text(
            state.widget.onHideFranchise != null
                ? '대표 매체만 숨기기'
                : '이 매체 숨기기',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            state.widget.onCancel?.call();
            state.widget.onHideFromRegistry!();
          },
        ),
    ],
  );
}
