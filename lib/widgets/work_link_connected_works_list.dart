import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../theme/akasha_palette.dart';
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
    final palette = context.akashaPalette;
    return Column(
      children: works.map((work) {
        final bridge = bridgeLabelsByWorkId[work.workId];
        final percent = sourceWork != null
            ? workPairSimilarityPercent(sourceWork!, work)
            : null;
        final subtitle =
            bridge ?? (percent != null ? '서사 유사도 $percent%' : null);

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
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textPrimary,
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
                                  ? palette.accent.withValues(alpha: 0.85)
                                  : palette.textMuted,
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
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 8,
                          color: palette.accent,
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
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: palette.borderSubtle(0.2)),
                      ),
                      child: Text(
                        '링크 연결',
                        style: AkashaTypography.micro.copyWith(
                          color: palette.textMuted,
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
