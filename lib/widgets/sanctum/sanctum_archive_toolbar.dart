import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../services/sanctum_body_templates.dart';
import '../../theme/akasha_colors.dart';
import '../../theme/akasha_spacing.dart';
import '../../theme/akasha_typography.dart';
import '../../features/workbench/presentation/widgets/workbench_panel_styles.dart';

/// Sanctum 기록 — 템플릿 적용 · HTML보내기.
class SanctumArchiveToolbar extends StatelessWidget {
  const SanctumArchiveToolbar({
    super.key,
    this.category,
    this.onApplyTemplate,
    required this.onExportHtml,
    this.canExportHtml = false,
    this.showTemplates = true,
  });

  final MediaCategory? category;
  final ValueChanged<SanctumBodyTemplate>? onApplyTemplate;
  final VoidCallback onExportHtml;
  final bool canExportHtml;
  final bool showTemplates;

  bool get _templatesEnabled =>
      showTemplates && category != null && onApplyTemplate != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkashaSpacing.sm),
      child: Row(
        children: [
          if (_templatesEnabled) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showTemplatePicker(context),
                icon: const Icon(Icons.article_outlined, size: 14),
                label: const Text('템플릿'),
                style: WorkbenchPanelStyles.compactOutlinedStyle(),
              ),
            ),
            const SizedBox(width: AkashaSpacing.sm),
          ],
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canExportHtml ? onExportHtml : null,
              icon: const Icon(Icons.html_outlined, size: 14),
              label: const Text('HTML보내기'),
              style: WorkbenchPanelStyles.compactOutlinedStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTemplatePicker(BuildContext context) async {
    if (!_templatesEnabled) return;
    final templates = SanctumBodyTemplates.forCategory(category!);
    final picked = await showDialog<SanctumBodyTemplate>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 템플릿'),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: templates.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(template.label),
                subtitle: Text(
                  template.description,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.of(ctx).pop(template),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (picked != null) onApplyTemplate!(picked);
  }
}
