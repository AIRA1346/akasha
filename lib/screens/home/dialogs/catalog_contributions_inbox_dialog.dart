import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/catalog_contribution.dart';
import '../../../services/catalog_contribution_service.dart';
import '../../../utils/catalog_contribution_export.dart';
import 'catalog_add_contribution_dialog.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/app_l10n.dart';

/// 저장된 카탈로그 제안 목록 — export·GitHub Issue·삭제
Future<void> showCatalogContributionsInboxDialog(BuildContext context) async {
  await CatalogContributionService.instance.load();

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _CatalogContributionsInboxDialog(
      onChanged: () {
        if (ctx.mounted) Navigator.pop(ctx);
        showCatalogContributionsInboxDialog(context);
      },
    ),
  );
}

class _CatalogContributionsInboxDialog extends StatefulWidget {
  final VoidCallback onChanged;

  const _CatalogContributionsInboxDialog({required this.onChanged});

  @override
  State<_CatalogContributionsInboxDialog> createState() =>
      _CatalogContributionsInboxDialogState();
}

class _CatalogContributionsInboxDialogState
    extends State<_CatalogContributionsInboxDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final service = CatalogContributionService.instance;
    final items = service.pending;

    return AlertDialog(
      title: Text(
        l10n != null
            ? l10n.catalogContributionsTitle(items.length)
            : '카탈로그 제안 (${items.length})',
      ),
      content: SizedBox(
        width: 480,
        height: 400,
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n?.noSavedProposals ?? '저장된 제안이 없습니다.',
                      style: const TextStyle(color: AkashaColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await showCatalogAddContributionDialog(context);
                        widget.onChanged();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n?.suggestNewWork ?? '작품 추가 제안'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = items[index];
                  return ListTile(
                    title: Text(c.summaryLabel),
                    subtitle: Text(
                      c.createdAt.toLocal().toString().substring(0, 16),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) => _onAction(context, c, action),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'copy',
                          child: Text(l10n?.actionCopyJson ?? 'JSON 복사'),
                        ),
                        PopupMenuItem(
                          value: 'github',
                          child: Text(
                            l10n?.actionOpenGithubIssue ?? 'GitHub Issue 열기',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n?.actionDelete ?? '삭제'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        if (items.isNotEmpty)
          TextButton(
            onPressed: () => _exportAll(context),
            child: Text(l10n?.actionCopyAllJson ?? '전체 JSON 복사'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.actionClose ?? '닫기'),
        ),
      ],
    );
  }

  Future<void> _onAction(
    BuildContext context,
    CatalogContribution c,
    String action,
  ) async {
    final l10n = lookupAppL10n(context);
    switch (action) {
      case 'copy':
        await Clipboard.setData(
          ClipboardData(
            text: const JsonEncoder.withIndent('  ').convert(c.toJson()),
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.proposalJsonCopied ?? '제안 JSON이 클립보드에 복사되었습니다.',
              ),
            ),
          );
        }
      case 'github':
        final uri = CatalogContributionExport.githubIssueUri(c);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      case 'delete':
        await CatalogContributionService.instance.remove(c.id);
        widget.onChanged();
    }
  }

  Future<void> _exportAll(BuildContext context) async {
    final l10n = lookupAppL10n(context);
    final json = CatalogContributionService.instance.exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    try {
      final file = await CatalogContributionService.instance.writeExportFile();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n != null
                ? l10n.jsonCopiedWithFile(file.path)
                : 'JSON 복사됨 · 파일: ${file.path}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n != null
                ? l10n.jsonCopiedFileFailed(e.toString())
                : 'JSON 복사됨 (파일 저장 실패: $e)',
          ),
        ),
      );
    }
  }
}
