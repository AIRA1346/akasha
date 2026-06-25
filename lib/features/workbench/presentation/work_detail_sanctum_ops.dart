import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/akasha_item.dart';
import '../../../services/sanctum_body_templates.dart';
import '../../../services/sanctum_html_exporter.dart';

/// Work Sanctum — 템플릿·HTML보내기 (workspace UI에서 위임).
abstract final class WorkDetailSanctumOps {
  static Future<bool> confirmTemplateOverwrite(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('템플릿 적용'),
        content: const Text(
          '현재 기록 본문을 템플릿으로 바꿉니다. 계속할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('적용'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static String bodyMarkdownForTemplate(SanctumBodyTemplate template) =>
      template.bodyMarkdown.trim();

  static Future<WorkDetailHtmlExportResult> exportHtml({
    required AkashaItem item,
    required String bodyMarkdown,
    String? titleOverride,
  }) async {
    try {
      final path = await SanctumHtmlExporter.exportAdjacentToRecord(
        item: item,
        bodyMarkdown: bodyMarkdown,
        titleOverride: titleOverride,
      );
      if (path == null) {
        return const WorkDetailHtmlExportFailure(
          'HTML 파일을 만들 수 없습니다.',
        );
      }
      final opened = await launchUrl(Uri.file(path));
      return WorkDetailHtmlExportSuccess(
        path: path,
        openedInBrowser: opened,
      );
    } catch (e) {
      return WorkDetailHtmlExportFailure('HTML보내기 실패: $e');
    }
  }

  static String htmlExportSnackMessage(WorkDetailHtmlExportResult result) {
    return switch (result) {
      WorkDetailHtmlExportSuccess(:final path, openedInBrowser: true) =>
        'HTML을 저장하고 열었습니다.',
      WorkDetailHtmlExportSuccess(:final path) => 'HTML을 저장했습니다: $path',
      WorkDetailHtmlExportFailure(:final message) => message,
    };
  }
}

sealed class WorkDetailHtmlExportResult {
  const WorkDetailHtmlExportResult();
}

class WorkDetailHtmlExportSuccess extends WorkDetailHtmlExportResult {
  const WorkDetailHtmlExportSuccess({
    required this.path,
    required this.openedInBrowser,
  });

  final String path;
  final bool openedInBrowser;
}

class WorkDetailHtmlExportFailure extends WorkDetailHtmlExportResult {
  const WorkDetailHtmlExportFailure(this.message);

  final String message;
}
