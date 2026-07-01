part of 'collectible_collection_edit_dialog.dart';

List<Widget> _collectibleCollectionEditPresetSection(
  BuildContext ctx,
  _CollectibleCollectionEditSession session,
) {
  final l10n = lookupAppL10n(ctx);
  return [
    const SizedBox(height: 16),
    const Text(
      'Cast Presets',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 6),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final preset in CollectibleCollectionPresets.all)
          FilledButton.tonal(
            onPressed: preset.isAvailableIn(session.knownWorkIds())
                ? () => Navigator.pop(ctx, preset.build())
                : null,
            child: Text(preset.title),
          ),
      ],
    ),
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        l10n?.presetAvailabilityNote ?? '볼트·카탈로그에 해당 Work가 있을 때만 활성화됩니다.',
        style: TextStyle(color: AkashaColors.textMuted, fontSize: 11),
      ),
    ),
    const Divider(height: 24),
    Text(
      l10n?.customCreate ?? '직접 만들기',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 4),
    Text(
      l10n?.customCreateDescription ?? '태그 기반 · 작품 기반 · 혼합 — 아래에서 설정 후 「추가」',
      style: TextStyle(color: AkashaColors.textCaption, fontSize: 11),
    ),
  ];
}
