import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../utils/app_l10n.dart';
import 'preview_connection_empty_state.dart';

/// Entity Preview — 연결 0건일 때 타입별 동작을 한 개의 메뉴로 제공한다.
class EntityPreviewEmptyConnections extends StatelessWidget {
  const EntityPreviewEmptyConnections({
    super.key,
    this.onConnectPerson,
    this.onConnectEvent,
    this.onConnectConcept,
    this.onConnectPlace,
    this.onConnectOrganization,
    this.onConnectWork,
  });

  final VoidCallback? onConnectPerson;
  final VoidCallback? onConnectEvent;
  final VoidCallback? onConnectConcept;
  final VoidCallback? onConnectPlace;
  final VoidCallback? onConnectOrganization;
  final VoidCallback? onConnectWork;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    return PreviewConnectionEmptyState(
      description:
          l10n?.previewEntityNoConnectionsDescription ??
          '이 기록에 작품이나 다른 엔티티를 연결할 수 있습니다.',
      actions: [
        if (onConnectWork != null)
          _action(
            l10n?.entityTypeWork ?? '작품',
            Icons.movie_filter_outlined,
            onConnectWork!,
            l10n,
          ),
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
}
