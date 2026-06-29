part of 'work_library_panel.dart';

Widget _buildWorkLibraryPanelDisplayTitle(_WorkLibraryPanelState state) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Text(
      state.widget.displayTitle,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

List<Widget> _buildWorkLibraryPanelTitleEditorSection(
  _WorkLibraryPanelState state,
) {
  return [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: state._titleCtrl,
        enabled: !state._applying,
        decoration: const InputDecoration(
          labelText: '제목',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    ),
    if (state.widget.draftMetaLine != null)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Text(
          state.widget.draftMetaLine!,
          style: TextStyle(fontSize: 11, color: AkashaColors.textMuted),
        ),
      ),
  ];
}
