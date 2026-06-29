part of 'work_library_panel.dart';

Widget _buildWorkLibraryPanelActionsRow(_WorkLibraryPanelState state) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed:
              state._applying ? null : () => state.widget.onCancel?.call(),
          child: const Text('취소'),
        ),
        const SizedBox(width: 8),
        if (state.widget.hasLibrarySection)
          FilledButton(
            onPressed: _workLibraryPanelCanApply(state)
                ? state._handleApply
                : null,
            child: state._applying
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('적용 중…'),
                    ],
                  )
                : const Text('적용'),
          ),
      ],
    ),
  );
}
