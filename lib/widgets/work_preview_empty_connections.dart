import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/link_candidate_service.dart';
import '../utils/app_l10n.dart';
import 'preview_connection_empty_state.dart';

/// Work Preview — 연결 0건일 때 한 개의 메뉴로 다음 행동을 정돈한다.
class WorkPreviewEmptyConnections extends StatelessWidget {
  const WorkPreviewEmptyConnections({
    super.key,
    this.suggestedLinks = const [],
    this.onSelectSuggested,
    this.onConnectPerson,
    this.onConnectEvent,
    this.onConnectConcept,
    this.onConnectPlace,
    this.onConnectOrganization,
  });

  final List<LinkCandidate> suggestedLinks;
  final void Function(LinkCandidate candidate)? onSelectSuggested;
  final VoidCallback? onConnectPerson;
  final VoidCallback? onConnectEvent;
  final VoidCallback? onConnectConcept;
  final VoidCallback? onConnectPlace;
  final VoidCallback? onConnectOrganization;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final actions = <PreviewConnectionAction>[
      if (onConnectPerson != null)
        _action(
          l10n?.entityTypePerson ?? '인물',
          Icons.person_outline,
          onConnectPerson!,
          l10n,
        ),
      if (onConnectEvent != null)
        _action(
          l10n?.entityTypeEvent ?? '사건',
          Icons.event_outlined,
          onConnectEvent!,
          l10n,
        ),
      if (onConnectConcept != null)
        _action(
          l10n?.entityTypeConcept ?? '개념',
          Icons.lightbulb_outline,
          onConnectConcept!,
          l10n,
        ),
      if (onConnectPlace != null)
        _action(
          l10n?.entityTypePlace ?? '장소',
          Icons.place_outlined,
          onConnectPlace!,
          l10n,
        ),
      if (onConnectOrganization != null)
        _action(
          l10n?.entityTypeOrganization ?? '조직',
          Icons.groups_outlined,
          onConnectOrganization!,
          l10n,
        ),
    ];

    return PreviewConnectionEmptyState(
      description:
          l10n?.previewWorkNoConnectionsDescription ??
          '작품 기록에 링크를 추가하면 아카이브의 연결로 표시됩니다.',
      actions: actions,
      suggestions: [
        for (final candidate in suggestedLinks.take(3))
          PreviewConnectionSuggestion(
            label: candidate.title,
            icon: _iconFor(candidate.anchorType),
            onPressed: onSelectSuggested == null
                ? null
                : () => onSelectSuggested!(candidate),
          ),
      ],
    );
  }

  PreviewConnectionAction _action(
    String typeLabel,
    IconData icon,
    VoidCallback onPressed,
    AppLocalizations? l10n,
  ) {
    return PreviewConnectionAction(
      label: l10n?.previewConnectType(typeLabel) ?? '$typeLabel 연결',
      icon: icon,
      onPressed: onPressed,
    );
  }

  static IconData _iconFor(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.person => Icons.person_outline,
      EntityAnchorType.event => Icons.event_outlined,
      EntityAnchorType.concept => Icons.lightbulb_outline,
      EntityAnchorType.place => Icons.place_outlined,
      EntityAnchorType.organization => Icons.groups_outlined,
      _ => Icons.category_outlined,
    };
  }
}
