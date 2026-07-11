import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../services/local_derived_index_lifecycle.dart';
import '../../../services/local_derived_index_store.dart';
import '../../../services/local_derived_index_synchronizer.dart';
import '../../../services/record_summary_index_service.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../widgets/safe_local_image.dart';

/// Bounded Work-only Explore surface.
///
/// A row is a read-only summary. Tapping it hydrates its one canonical source
/// before any preview or editor receives an [AkashaItem].
class WorkSummaryBrowseView extends StatefulWidget {
  const WorkSummaryBrowseView({
    super.key,
    required this.categories,
    required this.workStatuses,
    required this.myStatuses,
    required this.vaultPath,
    required this.onPreviewWork,
    required this.onOpenWorkDetail,
    this.lifecycle,
  });

  final Set<MediaCategory> categories;
  final Set<String> workStatuses;
  final Set<String> myStatuses;
  final String? vaultPath;
  final void Function(AkashaItem item) onPreviewWork;
  final void Function(AkashaItem item) onOpenWorkDetail;
  final LocalDerivedIndexLifecycle? lifecycle;

  @override
  State<WorkSummaryBrowseView> createState() => _WorkSummaryBrowseViewState();
}

class _WorkSummaryBrowseViewState extends State<WorkSummaryBrowseView> {
  late final ScrollController _scrollController;
  StreamSubscription<LocalDerivedIndexLifecycleStatus>? _statusSubscription;
  LocalDerivedIndexLifecycleStatus _status =
      const LocalDerivedIndexLifecycleStatus.inactive();
  WorkSummaryRebuildProgress? _progress;
  List<VaultRecordSummary> _summaries = const [];
  String? _nextCursor;
  String? _error;
  String? _openingWorkId;
  bool _loadingPage = false;
  var _requestEpoch = 0;

  LocalDerivedIndexLifecycle get _lifecycle =>
      widget.lifecycle ?? LocalDerivedIndexLifecycle.app;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreWhenNeeded);
    _status = _lifecycle.status;
    _statusSubscription = _lifecycle.statuses.listen(_onStatusChanged);
    unawaited(_prepareAndLoad());
  }

  @override
  void didUpdateWidget(covariant WorkSummaryBrowseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_filterKey(oldWidget) != _filterKey(widget)) {
      unawaited(_loadPage(reset: true));
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  Future<void> _prepareAndLoad() async {
    try {
      await _lifecycle.ensureWorkSummariesReady(
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (mounted) await _loadPage(reset: true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The archive could not be prepared.');
      }
    }
  }

  void _onStatusChanged(LocalDerivedIndexLifecycleStatus status) {
    if (!mounted) return;
    setState(() => _status = status);
    if (status.state == LocalDerivedIndexLifecycleState.ready &&
        _summaries.isEmpty &&
        !_loadingPage) {
      unawaited(_loadPage(reset: true));
    }
  }

  void _loadMoreWhenNeeded() {
    if (!_scrollController.hasClients ||
        _loadingPage ||
        _nextCursor == null ||
        _scrollController.position.extentAfter > 480) {
      return;
    }
    unawaited(_loadPage());
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_loadingPage ||
        _status.state != LocalDerivedIndexLifecycleState.ready) {
      return;
    }
    final epoch = ++_requestEpoch;
    setState(() {
      _loadingPage = true;
      if (reset) _error = null;
    });
    try {
      final page = await _lifecycle.queryWorkSummaries(
        query: WorkSummaryQuery(
          cursor: reset ? null : _nextCursor,
          categories: widget.categories.map((category) => category.name),
          workStatuses: widget.workStatuses,
          myStatuses: widget.myStatuses,
        ),
      );
      if (!mounted || epoch != _requestEpoch) return;
      setState(() {
        _summaries = reset
            ? page.summaries
            : [..._summaries, ...page.summaries];
        _nextCursor = page.nextCursor;
      });
    } catch (_) {
      if (mounted && epoch == _requestEpoch) {
        setState(() => _error = 'The archive could not be read right now.');
      }
    } finally {
      if (mounted && epoch == _requestEpoch) {
        setState(() => _loadingPage = false);
      }
    }
  }

  Future<void> _open(VaultRecordSummary summary, {required bool detail}) async {
    if (_openingWorkId != null) return;
    setState(() => _openingWorkId = summary.id);
    try {
      final hydration = await _lifecycle.hydrateSelectedWork(summary.id);
      if (!mounted) return;
      final item = hydration.item;
      if (hydration.state == SelectedWorkHydrationState.hydrated &&
          item != null) {
        if (detail) {
          widget.onOpenWorkDetail(item);
        } else {
          widget.onPreviewWork(item);
        }
      } else {
        setState(() => _error = 'This record is not ready to open yet.');
      }
    } finally {
      if (mounted) setState(() => _openingWorkId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status.state != LocalDerivedIndexLifecycleState.ready) {
      return _PreparationView(progress: _progress, error: _error);
    }
    if (_error != null && _summaries.isEmpty) {
      return _ErrorView(message: _error!, onRetry: _prepareAndLoad);
    }
    if (_summaries.isEmpty && !_loadingPage) {
      return const Center(
        child: Text(
          'No archived Work matches these filters.',
          style: TextStyle(color: AkashaColors.textMuted),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AkashaSpacing.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 330,
        mainAxisSpacing: AkashaSpacing.md,
        crossAxisSpacing: AkashaSpacing.md,
      ),
      itemCount: _summaries.length + (_nextCursor != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _summaries.length) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final summary = _summaries[index];
        return _WorkSummaryCard(
          summary: summary,
          vaultPath: widget.vaultPath,
          opening: _openingWorkId == summary.id,
          onTap: () => _open(summary, detail: false),
          onDoubleTap: () => _open(summary, detail: true),
        );
      },
    );
  }

  static String _filterKey(WorkSummaryBrowseView widget) {
    final categories = widget.categories.map((value) => value.name).toList()
      ..sort();
    final workStatuses = widget.workStatuses.toList()..sort();
    final myStatuses = widget.myStatuses.toList()..sort();
    return [
      ...categories,
      '|',
      ...workStatuses,
      '|',
      ...myStatuses,
    ].join('\u0000');
  }
}

class _PreparationView extends StatelessWidget {
  const _PreparationView({this.progress, this.error});

  final WorkSummaryRebuildProgress? progress;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final detail = progress == null
        ? 'Preparing archive'
        : 'Preparing ${progress!.scanned} archived records';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(detail, style: const TextStyle(color: AkashaColors.textMuted)),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(color: AkashaColors.statusWarning),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: AkashaColors.textMuted)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => unawaited(onRetry()),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _WorkSummaryCard extends StatelessWidget {
  const _WorkSummaryCard({
    required this.summary,
    required this.vaultPath,
    required this.opening,
    required this.onTap,
    required this.onDoubleTap,
  });

  final VaultRecordSummary summary;
  final String? vaultPath;
  final bool opening;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final category = _category(summary.category);
    final status = summary.myStatus ?? summary.workStatus;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('work_summary_card_${summary.id}'),
        onTap: opening ? null : onTap,
        onDoubleTap: opening ? null : onDoubleTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AkashaColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AkashaColors.borderSubtle(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: _SummaryPoster(
                    title: summary.title,
                    category: category,
                    posterPath: summary.posterPath,
                    vaultPath: vaultPath,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AkashaColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (summary.creator?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          summary.creator!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AkashaColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              status ?? category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AkashaColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if ((summary.rating ?? 0) > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AkashaColors.statusWarning,
                            ),
                            Text(
                              summary.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AkashaColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (opening) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                      if (summary.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          summary.tags.take(3).join('  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AkashaColors.textCaption,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static MediaCategory _category(String? value) {
    for (final category in MediaCategory.values) {
      if (category.name == value) return category;
    }
    return MediaCategory.book;
  }
}

class _SummaryPoster extends StatelessWidget {
  const _SummaryPoster({
    required this.title,
    required this.category,
    required this.posterPath,
    required this.vaultPath,
  });

  final String title;
  final MediaCategory category;
  final String? posterPath;
  final String? vaultPath;

  @override
  Widget build(BuildContext context) {
    final placeholder = _placeholder();
    final path = posterPath?.trim();
    if (path == null || path.isEmpty) return placeholder;
    if (path.startsWith('https://') || path.startsWith('http://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    final file = p.isAbsolute(path)
        ? File(path)
        : vaultPath == null || vaultPath!.isEmpty
        ? null
        : File(p.join(vaultPath!, path));
    if (file == null) return placeholder;
    return SafeLocalImage(
      file: file,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: categoryGradient(category),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(
            category.icon,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
