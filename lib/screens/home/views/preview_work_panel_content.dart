import 'package:flutter/material.dart';

import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';
import '../../../widgets/poster_image.dart';
import 'preview_record_view_model.dart';

/// 우측 패널 히어로·제목·메타 (Work·Entity 공통). 실데이터 [PreviewRecordViewModel] 연동.
class PreviewRecordHero extends StatelessWidget {
  const PreviewRecordHero({
    super.key,
    required this.model,
    this.compact = false,
    this.compactMaxHeight = 300,
  });

  final PreviewRecordViewModel model;
  final bool compact;
  final double compactMaxHeight;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : 320.0;
          final naturalHeight = width / model.heroAspectRatio;
          final height = naturalHeight
              .clamp(180.0, compactMaxHeight)
              .toDouble();

          return ClipRRect(
            borderRadius: AkashaRadius.xlBorder,
            child: SizedBox(
              width: double.infinity,
              height: height,
              child: PosterImage(item: model.posterItem, fit: BoxFit.cover),
            ),
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: AkashaRadius.xlBorder,
      child: AspectRatio(
        aspectRatio: model.heroAspectRatio,
        child: PosterImage(item: model.posterItem, fit: BoxFit.contain),
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
        Text(model.title, style: AkashaTypography.previewTitle),
        if (model.subtitle != null) ...[
          SizedBox(height: AkashaSpacing.xs),
          Text(
            model.subtitle!,
            style: AkashaTypography.bodySecondary.copyWith(height: 1.3),
          ),
        ],
        SizedBox(height: AkashaSpacing.xs + 2),
        Text(model.metaLine, style: AkashaTypography.bodySecondary),
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
    final l10n = lookupAppL10n(context);

    return Row(
      children: [
        if (canGoBack && onBack != null) ...[
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              foregroundColor: AkashaColors.textSecondary,
              side: BorderSide(color: AkashaColors.borderSubtle(0.12)),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 16),
          ),
          SizedBox(width: AkashaSpacing.sm),
        ],
        Expanded(
          child: FilledButton(
            onPressed: onOpenDetail,
            style: FilledButton.styleFrom(
              backgroundColor: AkashaColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: AkashaRadius.lgBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n?.previewDetails ?? '상세 정보',
                  style: AkashaTypography.buttonLabel,
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
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
    final l10n = lookupAppL10n(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.previewCoreInfo ?? '핵심 정보',
          style: AkashaTypography.sectionLabel,
        ),
        SizedBox(height: AkashaSpacing.sm + 2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: AkashaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AkashaColors.borderSubtle(0.03),
            borderRadius: AkashaRadius.lgBorder,
            border: Border.all(color: AkashaColors.borderSubtle(0.06)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: AkashaSpacing.md,
                    color: AkashaColors.borderSubtle(0.05),
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
        Icon(row.icon, size: 14, color: AkashaColors.textCaption),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text(row.label, style: AkashaTypography.caption),
        ),
        Expanded(
          child:
              row.valueWidget ??
              Text(
                row.value ?? '',
                style: AkashaTypography.bodySecondary.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AkashaColors.textPrimary,
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
      child: Text(title, style: AkashaTypography.sectionLabel),
    );
  }
}

// ── 레거시 import 호환 (dashboard_preview_panel 등) ──
// Work·Entity 모두 PreviewRecord* 위젯 + PreviewRecordViewModel 사용.
