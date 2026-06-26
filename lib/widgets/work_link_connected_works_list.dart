import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../theme/akasha_colors.dart';
import '../theme/akasha_typography.dart';
import '../utils/connection_similarity.dart';
import 'poster_image.dart';

class WorkLinkConnectedWorksList extends StatelessWidget {
  const WorkLinkConnectedWorksList({
    super.key,
    required this.works,
    this.bridgeLabelsByWorkId = const {},
    this.sourceWork,
    this.onOpenWork,
  });

  final List<AkashaItem> works;
  final Map<String, String> bridgeLabelsByWorkId;
  final AkashaItem? sourceWork;
  final void Function(AkashaItem work)? onOpenWork;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: works.map((work) {
        final bridge = bridgeLabelsByWorkId[work.workId];
        final percent = sourceWork != null
            ? workPairSimilarityPercent(sourceWork!, work)
            : null;
        final subtitle = bridge ?? (percent != null ? '서사 유사도 $percent%' : null);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: onOpenWork == null ? null : () => onOpenWork!(work),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 28,
                      height: 40,
                      child: PosterImage(item: work, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: bridge != null
                                  ? AkashaColors.accent.withValues(alpha: 0.85)
                                  : AkashaColors.textCaption,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (percent != null && bridge == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AkashaColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 8,
                          color: AkashaColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (bridge == null && subtitle == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AkashaColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '링크 연결',
                        style: AkashaTypography.micro.copyWith(
                          color: AkashaColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
