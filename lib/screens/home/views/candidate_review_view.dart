import 'package:flutter/material.dart';

import '../../../core/archiving/archive_candidate.dart';
import '../../../core/archiving/archive_operation.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/record_kind.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/archive_candidate_store.dart';
import '../../../services/archive_operation_executor.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_typography.dart';
import '../dialogs/add_catalog_entity_dialog.dart' show entityTypeBadgeLabel;

/// `.akasha/candidates/`에 쌓인 ArchiveCandidate를 검토하는 뷰.
///
/// 에이전트/임포트가 추출한 후보를 사용자가 직접 수락(promoteCandidate 실행)
/// 하거나 반려(dismiss)한다. 승격은 앱 소유 쓰기 경로(ArchiveOperationExecutor)
/// 만 사용한다.
class CandidateReviewView extends StatefulWidget {
  const CandidateReviewView({
    super.key,
    required this.vaultPath,
    required this.userCatalog,
    this.onOpenEntity,
    this.reloadToken = 0,
    this.candidateStore,
    this.operationExecutor,
  });

  final String? vaultPath;
  final UserCatalogPort userCatalog;
  final Future<void> Function(UserCatalogEntity entity)? onOpenEntity;
  final int reloadToken;

  /// 테스트 주입용. null이면 기본 구현을 사용한다.
  final ArchiveCandidateStore? candidateStore;
  final ArchiveOperationExecutor? operationExecutor;

  @override
  State<CandidateReviewView> createState() => _CandidateReviewViewState();
}

class _CandidateReviewViewState extends State<CandidateReviewView> {
  late final ArchiveCandidateStore _store =
      widget.candidateStore ?? ArchiveCandidateStore();
  late final ArchiveOperationExecutor _executor =
      widget.operationExecutor ??
      ArchiveOperationExecutor(candidateStore: _store);

  List<ArchiveCandidate> _candidates = const [];
  bool _loading = true;
  final Set<String> _busyCandidateIds = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant CandidateReviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken ||
        oldWidget.vaultPath != widget.vaultPath) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final path = widget.vaultPath;
    if (path == null || path.trim().isEmpty) {
      setState(() {
        _candidates = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final candidates = await _store.openCandidates(path);
    if (!mounted) return;
    setState(() {
      _candidates = candidates;
      _loading = false;
    });
  }

  Future<void> _approve(ArchiveCandidate candidate) async {
    final path = widget.vaultPath;
    if (path == null) return;

    final approvedTitle = await _confirmApprove(candidate);
    if (approvedTitle == null || !mounted) return;

    setState(() => _busyCandidateIds.add(candidate.candidateId));
    try {
      final operation = ArchiveOperation(
        operationId: 'op_promote_${candidate.candidateId}',
        type: ArchiveOperationType.promoteCandidate,
        recordKind: RecordKind.entityJournal,
        source: ArchiveOperationSource.user,
        createdAt: DateTime.now().toUtc(),
        actor: 'user',
        title: approvedTitle == candidate.title.trim() ? null : approvedTitle,
        targetEntity: EntityAnchor(
          entityId: candidate.resolvePromotionEntityId(),
          type: candidate.entityType,
        ),
        payload: {'candidateId': candidate.candidateId},
      );
      final result = await _executor.execute(
        vaultPath: path,
        operation: operation,
        userCatalog: widget.userCatalog,
      );
      if (!mounted) return;

      if (result.isSuccess) {
        _showSnack('후보를 수락했습니다: $approvedTitle');
        final entity = result.entity;
        if (entity != null && widget.onOpenEntity != null) {
          await widget.onOpenEntity!(entity);
        }
      } else {
        _showSnack('수락 실패: ${_issueSummary(result)}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyCandidateIds.remove(candidate.candidateId));
        await _reload();
      }
    }
  }

  Future<void> _reject(ArchiveCandidate candidate) async {
    final path = widget.vaultPath;
    if (path == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('후보 반려'),
        content: Text('"${candidate.title}" 후보를 반려할까요?\n반려된 후보는 목록에서 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('반려'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busyCandidateIds.add(candidate.candidateId));
    try {
      await _store.dismiss(vaultPath: path, candidateId: candidate.candidateId);
      if (mounted) _showSnack('후보를 반려했습니다: ${candidate.title}');
    } finally {
      if (mounted) {
        setState(() => _busyCandidateIds.remove(candidate.candidateId));
        await _reload();
      }
    }
  }

  /// 수락 확정 다이얼로그. 확정 시 (수정 가능한) 최종 제목을 돌려준다.
  Future<String?> _confirmApprove(ArchiveCandidate candidate) async {
    final titleCtrl = TextEditingController(text: candidate.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('후보 수락'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entityTypeBadgeLabel(candidate.entityType)} 엔티티로 승격합니다.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: AkashaColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (candidate.evidence.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '근거',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AkashaColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: SelectableText(candidate.evidence.trim()),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx, title);
            },
            child: const Text('수락'),
          ),
        ],
      ),
    );
    titleCtrl.dispose();
    return result;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  static String _issueSummary(ArchiveOperationExecutionResult result) {
    if (result.issues.isEmpty) return '알 수 없는 오류';
    return result.issues.map((issue) => issue.message).join(' ');
  }

  static String _sourceLabel(ArchiveCandidateSource source) {
    return switch (source) {
      ArchiveCandidateSource.user => '사용자',
      ArchiveCandidateSource.agent => 'AI 에이전트',
      ArchiveCandidateSource.importTool => '가져오기',
      ArchiveCandidateSource.registry => '레지스트리',
      ArchiveCandidateSource.script => '스크립트',
    };
  }

  static String _formatWhen(DateTime at) {
    final local = at.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _preview(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 140) return trimmed;
    return '${trimmed.substring(0, 140)}…';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vaultPath == null) {
      return const Center(child: Text('볼트를 연결하면 제안된 후보를 검토할 수 있습니다.'));
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AkashaColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text('검토할 후보가 없습니다.'),
            const SizedBox(height: 4),
            Text(
              'AI 에이전트나 가져오기가 제안한 엔티티 후보가 여기에 표시됩니다.',
              style: AkashaTypography.bodySecondary.copyWith(
                color: AkashaColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('새로고침'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Text(
                '제안된 후보 (${_candidates.length})',
                style: AkashaTypography.dashboardPanelTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '새로고침',
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _candidates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildCandidateCard(_candidates[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateCard(ArchiveCandidate candidate) {
    final busy = _busyCandidateIds.contains(candidate.candidateId);
    final isWork = candidate.entityType == EntityAnchorType.work;
    final confidence = candidate.confidence > 0
        ? '${(candidate.confidence * 100).clamp(0, 100).round()}%'
        : null;

    return Material(
      color: AkashaColors.workbenchListTile,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _typeBadge(candidate.entityType),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    candidate.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (confidence != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      confidence,
                      style: AkashaTypography.bodySecondary.copyWith(
                        color: AkashaColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
            if (candidate.evidence.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _preview(candidate.evidence),
                style: AkashaTypography.listItemTitle.copyWith(
                  color: AkashaColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_sourceLabel(candidate.source)} · ${_formatWhen(candidate.createdAt)}',
                  style: AkashaTypography.bodySecondary.copyWith(
                    color: AkashaColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  TextButton(
                    onPressed: () => _reject(candidate),
                    child: const Text(
                      '반려',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: isWork ? 'Work 후보는 작품 아카이브 경로로 추가하세요.' : '',
                    child: FilledButton(
                      onPressed: isWork ? null : () => _approve(candidate),
                      child: const Text('수락'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(EntityAnchorType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AkashaColors.textMuted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        entityTypeBadgeLabel(type),
        style: AkashaTypography.bodySecondary.copyWith(
          color: AkashaColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }
}
