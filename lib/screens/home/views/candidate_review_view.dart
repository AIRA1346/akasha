import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/archiving/archive_candidate.dart';
import '../../../core/archiving/archive_operation.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/record_kind.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/archive_candidate_store.dart';
import '../../../services/archive_operation_executor.dart';
import '../../../services/archive_record_revision_service.dart';
import '../../../services/record_summary_index_service.dart';
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
    this.recordSummaryIndexService,
    this.revisionService,
  });

  final String? vaultPath;
  final UserCatalogPort userCatalog;
  final Future<void> Function(UserCatalogEntity entity)? onOpenEntity;
  final int reloadToken;

  /// 테스트 주입용. null이면 기본 구현을 사용한다.
  final ArchiveCandidateStore? candidateStore;
  final ArchiveOperationExecutor? operationExecutor;
  final RecordSummaryIndexService? recordSummaryIndexService;
  final ArchiveRecordRevisionService? revisionService;

  @override
  State<CandidateReviewView> createState() => _CandidateReviewViewState();
}

class _CandidateReviewViewState extends State<CandidateReviewView> {
  late final ArchiveCandidateStore _store =
      widget.candidateStore ?? ArchiveCandidateStore();
  late final ArchiveOperationExecutor _executor =
      widget.operationExecutor ??
      ArchiveOperationExecutor(candidateStore: _store);
  late final RecordSummaryIndexService _recordSummaryIndex =
      widget.recordSummaryIndexService ?? RecordSummaryIndexService();
  late final ArchiveRecordRevisionService _revisionService =
      widget.revisionService ?? const ArchiveRecordRevisionService();

  List<ArchiveCandidate> _candidates = const [];
  bool _loading = true;
  final Set<String> _busyCandidateIds = {};
  StreamSubscription<FileSystemEvent>? _candidateWatch;
  Timer? _candidateWatchDebounce;

  @override
  void initState() {
    super.initState();
    _reload();
    _startCandidateWatch();
  }

  @override
  void didUpdateWidget(covariant CandidateReviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken ||
        oldWidget.vaultPath != widget.vaultPath) {
      _reload();
    }
    if (oldWidget.vaultPath != widget.vaultPath) {
      _startCandidateWatch();
    }
  }

  @override
  void dispose() {
    _candidateWatchDebounce?.cancel();
    _candidateWatch?.cancel();
    super.dispose();
  }

  void _startCandidateWatch() {
    _candidateWatchDebounce?.cancel();
    _candidateWatchDebounce = null;
    _candidateWatch?.cancel();
    _candidateWatch = null;

    final vaultPath = widget.vaultPath?.trim();
    if (vaultPath == null || vaultPath.isEmpty) return;
    final root = Directory(vaultPath);
    if (!root.existsSync()) return;

    try {
      _candidateWatch = root.watch(recursive: true).listen((event) {
        if (!_isCandidateStorageEvent(event.path)) return;
        _candidateWatchDebounce?.cancel();
        _candidateWatchDebounce = Timer(
          const Duration(milliseconds: 180),
          _reload,
        );
      }, onError: (_) {});
    } on FileSystemException {
      // The visible manual refresh remains a fallback for filesystems that do
      // not support directory watching (for example, some removable drives).
    }
  }

  bool _isCandidateStorageEvent(String eventPath) {
    final normalized = eventPath.replaceAll('\\', '/').toLowerCase();
    return normalized.contains('/system/candidates');
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

  Future<void> _showDetails(ArchiveCandidate candidate) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${candidate.title} 후보 정보'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailSection(ctx, '제안', [
                  _detailRow('종류', entityTypeBadgeLabel(candidate.entityType)),
                  _detailRow('출처', _sourceLabel(candidate.source)),
                  _detailRow('생성', _formatWhen(candidate.createdAt)),
                  if (_proposalActor(candidate) != null)
                    _detailRow('제안 주체', _proposalActor(candidate)!),
                  if (candidate.sourceOperationId?.trim().isNotEmpty == true)
                    _detailRow('작업 ID', candidate.sourceOperationId!.trim()),
                ]),
                const SizedBox(height: 16),
                FutureBuilder<_CandidateSourceState>(
                  future: _loadSourceState(candidate),
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    return _detailSection(ctx, '원본 기록', [
                      if (state?.title?.trim().isNotEmpty == true)
                        _detailRow('기록', state!.title!.trim()),
                      _detailRow('기록 ID', candidate.sourceRecordId),
                      if (state != null) _detailRow('현재 상태', state.statusLabel),
                      if (candidate.sourceRecordRevision?.trim().isNotEmpty ==
                          true)
                        _detailRow(
                          '제안 당시 revision',
                          candidate.sourceRecordRevision!.trim(),
                          selectable: true,
                        )
                      else
                        _detailRow('제안 당시 revision', '기존 후보 — 정보 없음'),
                    ]);
                  },
                ),
                if (candidate.evidence.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _detailSection(ctx, '근거', [
                    SelectableText(
                      candidate.evidence.trim(),
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                  ]),
                ],
                if (candidate.aliases.isNotEmpty ||
                    candidate.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _detailSection(ctx, '보조 정보', [
                    if (candidate.aliases.isNotEmpty)
                      _detailRow('별칭', candidate.aliases.join(', ')),
                    if (candidate.tags.isNotEmpty)
                      _detailRow('태그', candidate.tags.join(', ')),
                  ]),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<_CandidateSourceState> _loadSourceState(
    ArchiveCandidate candidate,
  ) async {
    final path = widget.vaultPath;
    if (path == null || path.trim().isEmpty) {
      return const _CandidateSourceState.unavailable();
    }

    final summary = await _recordSummaryIndex.lookupById(
      path,
      candidate.sourceRecordId,
    );
    final revision = await _revisionService.currentForRecordId(
      vaultPath: path,
      recordId: candidate.sourceRecordId,
    );
    final captured = candidate.sourceRecordRevision?.trim();
    return _CandidateSourceState(
      title: summary?.title,
      exists: revision.exists,
      isChanged: captured == null || captured.isEmpty
          ? null
          : !revision.exists || revision.value != captured,
    );
  }

  Widget _detailSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AkashaColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool selectable = false}) {
    final text = Text(
      value,
      style: AkashaTypography.bodySecondary.copyWith(
        color: AkashaColors.textSecondary,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: AkashaTypography.bodySecondary.copyWith(
                color: AkashaColors.textMuted,
              ),
            ),
          ),
          Expanded(child: selectable ? SelectableText(value) : text),
        ],
      ),
    );
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
                style: Theme.of(
                  ctx,
                ).textTheme.bodySmall?.copyWith(color: AkashaColors.textMuted),
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _metadataLabel(
                  Icons.article_outlined,
                  '원본 ${_shortId(candidate.sourceRecordId)}',
                ),
                if (_proposalActor(candidate) != null)
                  _metadataLabel(
                    Icons.smart_toy_outlined,
                    _proposalActor(candidate)!,
                  ),
              ],
            ),
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
                  TextButton.icon(
                    onPressed: () => _showDetails(candidate),
                    icon: const Icon(Icons.info_outline, size: 17),
                    label: const Text('상세'),
                  ),
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

  Widget _metadataLabel(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AkashaColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AkashaTypography.bodySecondary.copyWith(
            color: AkashaColors.textMuted,
          ),
        ),
      ],
    );
  }

  static String? _proposalActor(ArchiveCandidate candidate) {
    final label = candidate.actorLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    final binding = candidate.actorBindingId?.trim();
    return binding == null || binding.isEmpty ? null : binding;
  }

  static String _shortId(String id) {
    final trimmed = id.trim();
    if (trimmed.length <= 26) return trimmed;
    return '${trimmed.substring(0, 23)}…';
  }
}

class _CandidateSourceState {
  const _CandidateSourceState({
    this.title,
    required this.exists,
    required this.isChanged,
  });

  const _CandidateSourceState.unavailable()
    : title = null,
      exists = false,
      isChanged = null;

  final String? title;
  final bool exists;
  final bool? isChanged;

  String get statusLabel {
    if (!exists) return '원본을 찾지 못했습니다';
    return switch (isChanged) {
      true => '후보 제안 이후 원본이 변경되었습니다',
      false => '후보 제안 당시와 같은 원본입니다',
      null => '기존 후보 — 비교할 revision이 없습니다',
    };
  }
}
