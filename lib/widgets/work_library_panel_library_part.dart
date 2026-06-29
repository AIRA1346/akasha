part of 'work_library_panel.dart';

List<Widget> _buildWorkLibraryPanelLibrarySection(
  _WorkLibraryPanelState state,
  BuildContext context,
  List<PersonalLibraryConfig> libraries,
  String? activeId,
) {
  return [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Text(
        '나만의 서재',
        style: TextStyle(
          fontSize: 11,
          color: AkashaColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    if (state.widget.showIpScopeOption) ...[
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SegmentedButton<bool>(
          segments: [
            ButtonSegment<bool>(
              value: false,
              label: Text(
                state.widget.singleWorkIds.length == 1
                    ? '이 매체만'
                    : '선택 매체',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text(
                'IP 전체 (${state.widget.entireIpWorkIds.length})',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
          selected: {state._useEntireIp},
          onSelectionChanged: (selected) {
            state._onIpScopeSelectionChanged(selected.first);
          },
        ),
      ),
    ],
    const SizedBox(height: 4),
    Flexible(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          for (final lib in libraries)
            CheckboxListTile(
              tristate: _workLibraryPanelEffectiveIds(state).length > 1,
              value: state._checked[lib.id],
              onChanged: state._applying
                  ? null
                  : (v) => state._onLibraryCheckChanged(lib.id, v),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      lib.name,
                      style: TextStyle(
                        fontWeight: lib.id == activeId
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (lib.id == activeId)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '현재 서재',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                _workLibraryPanelLibrarySubtitle(state, lib) ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: AkashaColors.textCaption,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
        ],
      ),
    ),
    if (state.widget.onCreateLibrary != null)
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: state._applying
              ? null
              : () async {
                  final created = await state.widget.onCreateLibrary!();
                  if (created == null || !state.mounted) return;
                  state._onLibraryCreated(created);
                },
          icon: const Icon(Icons.add_box_outlined, size: 16),
          label: const Text(
            '새 서재 만들기…',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
  ];
}

Widget _buildWorkLibraryPanelEmptyLibrariesHint() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      'curated 서재가 없습니다.',
      style: TextStyle(fontSize: 12, color: AkashaColors.textMuted),
    ),
  );
}
