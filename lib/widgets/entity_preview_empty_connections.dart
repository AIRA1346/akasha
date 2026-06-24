import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../theme/akasha_colors.dart';

/// Entity Preview — 연결 0건일 때 타입별 연결 CTA (Work 패널과 동일 패턴).
class EntityPreviewEmptyConnections extends StatelessWidget {
  const EntityPreviewEmptyConnections({
    super.key,
    this.onConnectPerson,
    this.onConnectEvent,
    this.onConnectConcept,
    this.onConnectPlace,
    this.onConnectOrganization,
    this.onConnectWork,
    this.onOpenRecord,
  });

  final VoidCallback? onConnectPerson;
  final VoidCallback? onConnectEvent;
  final VoidCallback? onConnectConcept;
  final VoidCallback? onConnectPlace;
  final VoidCallback? onConnectOrganization;
  final VoidCallback? onConnectWork;
  final VoidCallback? onOpenRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '연결이 없습니다.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '아래에서 연결을 추가하거나 상세 정보에서 기록을 작성하세요.',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          if (onConnectWork != null)
            _linkButton(
              label: '작품 연결하기',
              icon: Icons.movie_filter_outlined,
              onPressed: onConnectWork,
            ),
          _linkButton(
            label: '인물 연결하기',
            icon: Icons.person_outline,
            onPressed: onConnectPerson,
          ),
          _linkButton(
            label: '사건 연결하기',
            icon: Icons.event_outlined,
            onPressed: onConnectEvent,
          ),
          _linkButton(
            label: '개념 연결하기',
            icon: Icons.lightbulb_outline,
            onPressed: onConnectConcept,
          ),
          _linkButton(
            label: '장소 연결하기',
            icon: Icons.place_outlined,
            onPressed: onConnectPlace,
          ),
          _linkButton(
            label: '조직 연결하기',
            icon: Icons.groups_outlined,
            onPressed: onConnectOrganization,
          ),
          if (onOpenRecord != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onOpenRecord,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(
                    color: AkashaColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  '상세 정보에서 기록 작성하기',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linkButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    if (onPressed == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(icon, size: 14, color: AkashaColors.accent),
          label: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
