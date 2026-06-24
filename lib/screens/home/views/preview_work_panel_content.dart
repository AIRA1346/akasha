import 'package:flutter/material.dart';

import '../../../theme/akasha_colors.dart';
import '../../../widgets/poster_image.dart';
import 'preview_record_view_model.dart';

/// 우측 패널 히어로·제목·메타 (Work·Entity 공통). 실데이터 [PreviewRecordViewModel] 연동.
class PreviewRecordHero extends StatelessWidget {
  const PreviewRecordHero({super.key, required this.model});

  final PreviewRecordViewModel model;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: model.heroAspectRatio,
        child: PosterImage(item: model.posterItem, fit: BoxFit.cover),
      ),
    );
  }
}

class PreviewRecordTitleBlock extends StatelessWidget {
  const PreviewRecordTitleBlock({super.key, required this.model});

  final PreviewRecordViewModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          model.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.25,
          ),
        ),
        if (model.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            model.subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          model.metaLine,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class PreviewRecordActionBar extends StatelessWidget {
  const PreviewRecordActionBar({
    super.key,
    required this.onOpenDetail,
    this.canGoBack = false,
    this.onBack,
  });

  final VoidCallback onOpenDetail;
  final bool canGoBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack && onBack != null) ...[
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              foregroundColor: Colors.grey[300],
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 16),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: FilledButton(
            onPressed: onOpenDetail,
            style: FilledButton.styleFrom(
              backgroundColor: AkashaColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '상세 정보',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PreviewRecordCoreInfoSection extends StatelessWidget {
  const PreviewRecordCoreInfoSection({super.key, required this.rows});

  final List<PreviewCoreInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '핵심 정보',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 12,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                _CoreInfoRowWidget(row: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CoreInfoRowWidget extends StatelessWidget {
  const _CoreInfoRowWidget({required this.row});

  final PreviewCoreInfoRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(row.icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text(
            row.label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: row.valueWidget ??
              Text(
                row.value ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
        ),
      ],
    );
  }
}

/// 프리뷰 연결 섹션 공통 헤더.
class PreviewSectionHeader extends StatelessWidget {
  const PreviewSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── 레거시 import 호환 (dashboard_preview_panel 등) ──
// Work·Entity 모두 PreviewRecord* 위젯 + PreviewRecordViewModel 사용.
