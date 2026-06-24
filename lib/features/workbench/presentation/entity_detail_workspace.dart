import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/archiving/record_link.dart';
import '../../../core/archiving/record_kind.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../widgets/web_image_search_dialog.dart';
import '../../../services/entity_journal_parser.dart';
import '../../../services/entity_vault_path_conflict.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/file_service.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../services/record_link_navigator.dart';
import '../../../utils/entity_link_neighbors.dart';
import '../../../theme/akasha_colors.dart';
import '../../../config/feature_flags.dart';
import '../../../utils/entity_tag_validation.dart';
import '../../../widgets/sanctum_page_panel.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../screens/home/views/preview_record_view_model.dart';
import 'entity_detail_archive_ops.dart';
import 'entity_detail_link_pick_ops.dart';
import 'workbench_link_pick_ops.dart';
import 'entity_detail_connections_panel.dart';
import 'entity_detail_info_panel.dart';
import 'workbench_autosave_scheduler.dart';
import 'workbench_record_links_loader.dart';
import 'widgets/workbench_breadcrumb.dart';
import 'widgets/workbench_panel_styles.dart';

/// Entity collectible — Workbench 3·4열 (Phase 6).
class EntityDetailWorkspace extends StatefulWidget {
  const EntityDetailWorkspace({
    super.key,
    required this.entity,
    required this.journal,
    required this.tabId,
    this.isDirty = false,
    required this.infoPanelWidth,
    this.infoPanelLocked = false,
    this.userCatalog,
    this.linkIndex,
    this.vaultItems = const [],
    required this.onSaved,
    required this.onDeleted,
    required this.onDirtyChanged,
    required this.onBindSave,
    this.onAddToLibrary,
    this.onPreserveDraft,
    this.onInfoWidthChanged,
    this.onToggleInfoLock,
    this.onWikiLinkTap,
    this.onRequestEntityLink,
    this.onClose,
    this.onGoKnowledgeGraph,
    this.onRecordOpenWork,
    this.onRecordOpenEntity,
    this.pendingEntityLinkType,
    this.pendingEntityLinkEntityId,
    this.pendingEntityWorkLinkPick = false,
    this.onPendingEntityLinkHandled,
  });

  final UserCatalogEntity entity;
  final EntityJournalEntry? journal;
  final String tabId;
  final bool isDirty;
  final double infoPanelWidth;
  final bool infoPanelLocked;
  final UserCatalogPort? userCatalog;
  final RecordLinkPort? linkIndex;
  final List<AkashaItem> vaultItems;
  final void Function(
    UserCatalogEntity entity,
    EntityJournalEntry? journal, {
    required bool silent,
  }) onSaved;
  final VoidCallback onDeleted;
  final ValueChanged<bool> onDirtyChanged;
  final void Function(Future<void> Function()? save) onBindSave;
  final void Function(
    String tabId,
    UserCatalogEntity entity,
    EntityJournalEntry? journal,
    List<String> tags,
    String body,
  )? onPreserveDraft;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )? onRequestEntityLink;
  final Future<void> Function(UserCatalogEntity entity)? onAddToLibrary;
  final VoidCallback? onClose;
  final VoidCallback? onGoKnowledgeGraph;
  final void Function(AkashaItem item)? onRecordOpenWork;
  final Future<void> Function(UserCatalogEntity entity)? onRecordOpenEntity;
  final EntityAnchorType? pendingEntityLinkType;
  final String? pendingEntityLinkEntityId;
  final bool pendingEntityWorkLinkPick;
  final VoidCallback? onPendingEntityLinkHandled;

  @override
  State<EntityDetailWorkspace> createState() => _EntityDetailWorkspaceState();
}

class _EntityDetailWorkspaceState extends State<EntityDetailWorkspace> {
  static final _store = EntityVaultStore();

  late UserCatalogEntity _entity;
  EntityJournalEntry? _journal;
  late EntityItem _item;
  late EntityItem _preview;
  late List<String> _draftTags;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _fileCtrl;
  late final TextEditingController _posterUrlCtrl;
  SanctumPageView _pageView = SanctumPageView.preview;
  bool _isSaving = false;
  bool _suppressPersist = false;
  DateTime? _lastSavedAt;
  final WorkbenchAutosaveScheduler _autosave = WorkbenchAutosaveScheduler();

  List<String> _incomingPaths = const [];
  bool _loadingIncoming = false;
  int _staleLabelRecordCount = 0;
  List<SameDayRecordRef> _sameDayRefs = const [];
  bool _loadingSameDay = false;
  EntityLinkNeighbors _linkNeighbors = const EntityLinkNeighbors();
  bool _loadingLinkNeighbors = false;

  EntityItem _buildEntityItem(UserCatalogEntity entity, EntityJournalEntry? journal) {
    return EntityItem(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      category: entity.subtype,
      domain: entity.domain,
      creator: entity.creator,
      releaseYear: entity.releaseYear,
      posterPath: journal?.posterPath ?? entity.posterPath,
      tags: List<String>.from(journal?.tags ?? entity.tags),
      addedAt: journal?.addedAt ?? entity.addedAt,
      bodyRaw: journal?.body ?? '',
    );
  }

  void _updatePreview() {
    setState(() {
      _preview = EntityItem(
        entityType: _entity.anchorType,
        entityId: _entity.entityId,
        title: _entity.title,
        category: _entity.subtype,
        domain: _entity.domain,
        creator: _entity.creator,
        releaseYear: _entity.releaseYear,
        posterPath: _posterUrlCtrl.text,
        tags: _draftTags,
        addedAt: _journal?.addedAt ?? _entity.addedAt,
        bodyRaw: _bodyCtrl.text,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _entity = widget.entity;
    _journal = widget.journal;
    _item = _buildEntityItem(_entity, _journal);
    _preview = _item;
    _draftTags = List<String>.from(_journal?.tags ?? _entity.tags);
    _bodyCtrl = TextEditingController(text: _journal?.body ?? '');
    _posterUrlCtrl = TextEditingController(text: _journal?.posterPath ?? _entity.posterPath ?? '');
    _posterUrlCtrl.addListener(() {
      _updatePreview();
    });
    _fileCtrl = TextEditingController(text: _serializeFile());
    _pageView = _bodyCtrl.text.trim().isEmpty
        ? SanctumPageView.body
        : SanctumPageView.preview;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
    _loadIncoming();
    _loadSameDay();
    _loadLinkNeighbors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRunPendingEntityLinkPick();
    });
  }

  Future<void> _maybeRunPendingEntityLinkPick() async {
    final request = EntityDetailLinkPickOps.pendingRequest(
      pendingEntityId: widget.pendingEntityLinkEntityId,
      pendingWorkLinkPick: widget.pendingEntityWorkLinkPick,
      entityLinkType: widget.pendingEntityLinkType,
    );
    switch (WorkbenchLinkPickOps.classifyPending(
      request: request,
      currentContextId: _entity.entityId,
      catalog: widget.userCatalog,
    )) {
      case WorkbenchPendingLinkResolution.wrongContext:
      case WorkbenchPendingLinkResolution.skipped:
        return;
      case WorkbenchPendingLinkResolution.pickWork:
        widget.onPendingEntityLinkHandled?.call();
        if (!mounted) return;
        await _requestWorkLink();
      case WorkbenchPendingLinkResolution.pickEntity:
        widget.onPendingEntityLinkHandled?.call();
        if (!mounted) return;
        setState(() => _pageView = SanctumPageView.body);
        final picked = await WorkbenchLinkPickOps.pickEntityLink(
          context: context,
          catalog: widget.userCatalog!,
          type: request.entityLinkType!,
          workContext: _item,
          vaultItems: widget.vaultItems,
        );
        if (!mounted || picked == null) return;
        await _applyWikiLinkSelection(picked);
    }
  }

  Future<void> _requestEntityLinkForType(EntityAnchorType type) async {
    final catalog = widget.userCatalog;
    if (catalog == null || !mounted) return;

    setState(() => _pageView = SanctumPageView.body);

    final picked = await EntityDetailLinkPickOps.requestEntityLinkForType(
      context: context,
      catalog: catalog,
      type: type,
      workContext: _item,
      vaultItems: widget.vaultItems,
    );
    if (!mounted || picked == null) return;
    await _applyWikiLinkSelection(picked);
  }

  Future<void> _requestWorkLink() async {
    if (!mounted) return;

    setState(() => _pageView = SanctumPageView.body);

    final picked = await EntityDetailLinkPickOps.requestWorkLink(
      context: context,
      vaultItems: widget.vaultItems,
    );
    if (!mounted || picked == null) return;
    await _applyWikiLinkSelection(picked);
  }

  Future<void> _applyWikiLinkSelection(EntityLinkSelection picked) async {
    await EntityDetailLinkPickOps.applySelection(
      picked: picked,
      bodyCtrl: _bodyCtrl,
      markDirty: _markDirty,
      reloadLinkNeighbors: _loadLinkNeighbors,
    );
  }

  Future<void> _loadLinkNeighbors() async {
    final catalog = widget.userCatalog;
    final index = widget.linkIndex;
    if (catalog == null || index == null) return;
    setState(() => _loadingLinkNeighbors = true);
    try {
      final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
        linkIndex: index,
        vaultItems: widget.vaultItems,
      );
      final neighbors = await fetchEntityLinkNeighbors(
        entity: _entity,
        userCatalog: catalog,
        discovery: discovery,
        linkIndex: index,
        vaultItems: widget.vaultItems,
      );
      if (mounted) {
        setState(() {
          _linkNeighbors = neighbors;
          _loadingLinkNeighbors = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLinkNeighbors = false);
    }
  }

  void _openLinkedEntity(UserCatalogEntity entity) {
    if (widget.onRecordOpenEntity != null) {
      widget.onRecordOpenEntity!(entity);
      return;
    }
    widget.onWikiLinkTap?.call(
      ParsedRecordLink(
        kind: RecordLinkKind.explicitId,
        raw: '[[${entity.entityId}]]',
        targetEntityId: entity.entityId,
      ),
    );
  }

  void _openLinkedWork(AkashaItem work) {
    if (widget.onRecordOpenWork != null) {
      widget.onRecordOpenWork!(work);
      return;
    }
    widget.onWikiLinkTap?.call(
      ParsedRecordLink(
        kind: RecordLinkKind.explicitId,
        raw: '[[${work.workId}]]',
        targetEntityId: work.workId,
      ),
    );
  }

  void _focusSanctumForLinks() {
    setState(() => _pageView = SanctumPageView.body);
  }

  Future<void> _loadSameDay() async {
    final anchor = _journal?.addedAt ?? _entity.addedAt;
    setState(() => _loadingSameDay = true);
    try {
      final refs = await WorkbenchRecordLinksLoader.loadSameDay(
        anchor: anchor,
        excludePath: _journal?.storagePath,
      );
      if (mounted) {
        setState(() {
          _sameDayRefs = refs;
          _loadingSameDay = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSameDay = false);
    }
  }

  Future<void> _loadIncoming() async {
    final index = widget.linkIndex;
    if (index == null) return;
    setState(() => _loadingIncoming = true);
    try {
      final currentTitle = _journal?.title ?? _entity.title;
      final snapshot = await WorkbenchRecordLinksLoader.loadIncoming(
        linkIndex: index,
        recordEntityId: _entity.entityId,
        currentTitle: currentTitle,
      );
      if (mounted) {
        setState(() {
          _incomingPaths = snapshot.paths;
          _staleLabelRecordCount = snapshot.staleLabelRecordCount;
          _loadingIncoming = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingIncoming = false);
    }
  }

  @override
  void didUpdateWidget(EntityDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      _entity = widget.entity;
      _journal = widget.journal;
      _item = _buildEntityItem(_entity, _journal);
      _preview = _item;
      _draftTags = List<String>.from(_journal?.tags ?? _entity.tags);
      _bodyCtrl.text = _journal?.body ?? '';
      _posterUrlCtrl.text = _journal?.posterPath ?? _entity.posterPath ?? '';
      _fileCtrl.text = _serializeFile();
      _pageView = _bodyCtrl.text.trim().isEmpty
          ? SanctumPageView.body
          : SanctumPageView.preview;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
      _loadIncoming();
      _loadSameDay();
      _loadLinkNeighbors();
      return;
    }
    if (!widget.isDirty &&
        (oldWidget.entity.entityId != widget.entity.entityId ||
            oldWidget.journal?.storagePath != widget.journal?.storagePath)) {
      _entity = widget.entity;
      _journal = widget.journal;
      _item = _buildEntityItem(_entity, _journal);
      _preview = _item;
      _draftTags = List<String>.from(_journal?.tags ?? _entity.tags);
      _bodyCtrl.text = _journal?.body ?? '';
      _posterUrlCtrl.text = _journal?.posterPath ?? _entity.posterPath ?? '';
      _fileCtrl.text = _serializeFile();
      _loadIncoming();
      _loadSameDay();
      _loadLinkNeighbors();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
  }

  void _bindSaveHandler() {
    widget.onBindSave(() => _saveJournal());
  }

  String _serializeFile() {
    final entry = _journal;
    if (entry == null) {
      return EntityJournalParser.serialize(
        entityType: _entity.anchorType,
        entityId: _entity.entityId,
        title: _entity.title,
        body: _bodyCtrl.text,
        addedAt: _entity.addedAt,
        tags: _draftTags,
        posterPath: _posterUrlCtrl.text,
      );
    }
    return EntityJournalParser.serialize(
      entityType: entry.entityType,
      entityId: entry.entityId,
      title: entry.title,
      body: _bodyCtrl.text,
      addedAt: entry.addedAt,
      tags: _draftTags,
      posterPath: _posterUrlCtrl.text,
    );
  }

  void _syncBodyFromEditor() {
    if (_pageView == SanctumPageView.file) {
      final parsed = EntityJournalParser.parse(_fileCtrl.text, '');
      if (parsed != null) {
        _bodyCtrl.text = parsed.body;
        _draftTags = List<String>.from(parsed.tags);
      }
    }
  }

  void _refreshFileEditor() {
    _syncBodyFromEditor();
    _fileCtrl.text = _serializeFile();
  }

  void _onPageViewChanged(SanctumPageView next) {
    if (_pageView == SanctumPageView.file && next != SanctumPageView.file) {
      _syncBodyFromEditor();
    }
    if (next == SanctumPageView.file) {
      _refreshFileEditor();
    }
    setState(() => _pageView = next);
  }

  void _markDirty() {
    widget.onDirtyChanged(true);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autosave.schedule(
      persistEnabled: !_suppressPersist,
      isDirty: () => widget.isDirty,
      isActive: () => mounted,
      save: () => _saveJournal(silent: true),
    );
  }

  @override
  void deactivate() {
    _autosave.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    _autosave.dispose();
    if (!_suppressPersist && widget.isDirty) {
      if (_pageView == SanctumPageView.file) {
        _syncBodyFromEditor();
      }
      widget.onPreserveDraft?.call(
        widget.tabId,
        _entity,
        _journal,
        _draftTags,
        _bodyCtrl.text,
      );
    }
    widget.onBindSave(null);
    _bodyCtrl.dispose();
    _fileCtrl.dispose();
    _posterUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveJournal({bool silent = false}) async {
    if (_suppressPersist || _isSaving) return;
    if (!EntityDetailArchiveOps.isVaultConnected()) {
      final msg = EntityDetailArchiveOps.vaultRequiredSnack(silent: silent);
      if (msg != null && mounted) {
        _showSnack(msg);
      }
      return;
    }

    if (_pageView == SanctumPageView.file) {
      _syncBodyFromEditor();
    }

    final bodyResolve = EntityDetailArchiveOps.resolveBodyForSave(
      rawBody: _bodyCtrl.text,
      posterPath: _posterUrlCtrl.text,
      tags: _draftTags,
    );
    if (bodyResolve.body == null) {
      final msg = EntityDetailArchiveOps.emptyBodySnack(silent: silent);
      if (msg != null && mounted) {
        _showSnack(msg);
      }
      return;
    }
    final body = bodyResolve.body!;
    if (bodyResolve.usedPlaceholder && !silent) {
      _bodyCtrl.text = body;
    }

    final catalog = widget.userCatalog;
    if (catalog != null) {
      await catalog.load();
      if (mounted) {
        EntityTagValidation.showWorkTitleWarningIfNeeded(
          context,
          tags: _draftTags,
          workTitles: EntityTagValidation.buildWorkTitleIndex(
            catalogEntities: catalog.all,
            vaultItems: const [],
          ),
        );
      }
    }

    setState(() => _isSaving = true);
    try {
      final vaultPath = AkashaFileService().vaultPath!;
      final entityDraft =
          _entity.copyWith(tags: _draftTags, posterPath: _posterUrlCtrl.text);
      final outcome = await EntityDetailArchiveOps.persist(
        vaultPath: vaultPath,
        entityDraft: entityDraft,
        existingJournal: _journal,
        body: body,
        tags: _draftTags,
        posterPath: _posterUrlCtrl.text,
        userCatalog: catalog,
        vaultStore: _store,
      );
      final mirrored = outcome.mirrored;
      final saved = outcome.saved;

      if (!mounted) return;
      setState(() {
        _entity = mirrored;
        _journal = saved;
        _item = _buildEntityItem(mirrored, saved);
        _preview = _item;
        _draftTags = List<String>.from(saved.tags);
        _fileCtrl.text = _serializeFile();
        _lastSavedAt = DateTime.now();
        if (!silent && _pageView != SanctumPageView.file) {
          _pageView = SanctumPageView.preview;
        }
      });
      widget.onDirtyChanged(false);
      widget.onSaved(mirrored, saved, silent: silent);
      _loadIncoming();
      _loadSameDay();
      _loadLinkNeighbors();
      if (!silent) {
        _showSnack(EntityDetailArchiveOps.saveSuccessMessage(mirrored));
      }
    } on EntityVaultPathConflict catch (e) {
      if (mounted && !silent) _showSnack(e.userMessage);
    } catch (e) {
      if (mounted && !silent) _showSnack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openIncoming(String path) async {
    final catalog = widget.userCatalog;
    if (catalog == null) return;

    await RecordLinkNavigator.openRecordPath(
      context,
      storagePath: path,
      vaultItems: const [],
      userCatalog: catalog,
      onOpenWork: (item) {
        if (widget.onRecordOpenWork != null) {
          widget.onRecordOpenWork!(item);
          return;
        }
        widget.onWikiLinkTap?.call(
          ParsedRecordLink(
            kind: RecordLinkKind.explicitId,
            raw: '[[${item.workId}]]',
            targetEntityId: item.workId,
          ),
        );
      },
      onOpenEntity: (entity) async {
        if (widget.onRecordOpenEntity != null) {
          await widget.onRecordOpenEntity!(entity);
          return;
        }
        widget.onWikiLinkTap?.call(
          ParsedRecordLink(
            kind: RecordLinkKind.explicitId,
            raw: '[[${entity.entityId}]]',
            targetEntityId: entity.entityId,
          ),
        );
      },
    );
  }

  Future<void> _openSameDay(SameDayRecordRef ref) async {
    final catalog = widget.userCatalog;
    if (ref.kind == RecordKind.workJournal && catalog != null) {
      await RecordLinkNavigator.openRecordPath(
        context,
        storagePath: ref.storagePath,
        vaultItems: const [],
        userCatalog: catalog,
        onOpenWork: (item) {
          if (widget.onRecordOpenWork != null) {
            widget.onRecordOpenWork!(item);
            return;
          }
          widget.onWikiLinkTap?.call(
            ParsedRecordLink(
              kind: RecordLinkKind.explicitId,
              raw: '[[${item.workId}]]',
              targetEntityId: item.workId,
            ),
          );
        },
        onOpenEntity: (entity) async {
          if (widget.onRecordOpenEntity != null) {
            await widget.onRecordOpenEntity!(entity);
            return;
          }
          widget.onWikiLinkTap?.call(
            ParsedRecordLink(
              kind: RecordLinkKind.explicitId,
              raw: '[[${entity.entityId}]]',
              targetEntityId: entity.entityId,
            ),
          );
        },
      );
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${ref.kindLabel} · ${ref.title}'),
        content: Text(
          '${_formatWhen(ref.when.toLocal())}\n${ref.storagePath}',
          style: const TextStyle(fontSize: 12),
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

  String _formatWhen(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:$m';
  }

  Future<void> _confirmDelete() async {
    if (_journal == null || _isSaving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: Text('「${_entity.title}」 entity journal을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final catalog = widget.userCatalog;
    if (catalog == null) {
      _showSnack('catalog 연결이 필요합니다.');
      return;
    }

    setState(() => _suppressPersist = true);
    widget.onDirtyChanged(false);

    final deleted = await EntityDetailArchiveOps.deleteFromVault(
      entry: _journal!,
      userCatalog: catalog,
      vaultStore: _store,
    );
    if (!mounted) return;

    if (deleted) {
      _showSnack('「${_entity.title}」 journal을 삭제했습니다.');
      widget.onDeleted();
    } else {
      setState(() => _suppressPersist = false);
      _showSnack('삭제할 파일을 찾지 못했습니다.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _openPosterCorrection() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (searchCtx) => WebImageSearchDialog(
        initialQuery: _entity.title,
        category: _entity.subtype,
      ),
    );
    if (selected != null) {
      setState(() {
        _posterUrlCtrl.text = selected;
        _updatePreview();
      });
      _markDirty();
    }
  }

  Future<void> _handleAddToLibrary() async {
    if (widget.onAddToLibrary == null) return;
    if (AkashaFileService().vaultPath == null) {
      _showSnack('볼트 연결 후 서재에 담을 수 있습니다.');
      return;
    }
    if (!EntityDetailArchiveOps.hasJournal(_journal)) {
      await _saveJournal();
    }
    if (_journal != null) {
      await widget.onAddToLibrary!(_entity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasJournal = EntityDetailArchiveOps.hasJournal(_journal);
    final saveLabel = hasJournal ? 'md 저장' : 'journal 생성';
    final typeLabel = entityTypeDisplayLabel(_entity.anchorType);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
      },
      child: Actions(
        actions: {
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              _saveJournal();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (FeatureFlags.showWorkbenchBreadcrumb)
                WorkbenchBreadcrumb(
                  segments: [
                    WorkbenchBreadcrumbSegment(
                      label: '서재',
                      onTap: widget.onClose,
                    ),
                    WorkbenchBreadcrumbSegment(label: typeLabel),
                    WorkbenchBreadcrumbSegment(label: _entity.title),
                  ],
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EntityDetailInfoPanel(
                      entity: _entity,
                      preview: _preview,
                      hasJournal: hasJournal,
                      panelWidth: widget.infoPanelWidth,
                      infoPanelLocked: widget.infoPanelLocked,
                      onInfoWidthChanged: widget.onInfoWidthChanged,
                      onToggleInfoLock: widget.onToggleInfoLock,
                      onPosterTap: _openPosterCorrection,
                      posterUrlCtrl: _posterUrlCtrl,
                      onClose: widget.onClose,
                      onFocusSanctum: _focusSanctumForLinks,
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: AkashaColors.workbenchEditor,
                        child: SanctumPagePanel(
                          view: _pageView,
                          onViewChanged: _onPageViewChanged,
                          headerTitle: '기록 본문',
                          previewMarkdown: _bodyCtrl.text,
                          mdFilePath: _journal?.storagePath,
                          isDirty: widget.isDirty,
                          isSaving: _isSaving,
                          lastSavedAt: _lastSavedAt,
                          bodyController: _bodyCtrl,
                          fileController: _fileCtrl,
                          onBodyChanged: _markDirty,
                          onFileChanged: _markDirty,
                          onOpenFileView: _refreshFileEditor,
                          onWikiLinkTap: widget.onWikiLinkTap,
                          onRequestEntityLink: widget.onRequestEntityLink,
                          footer: WorkbenchSaveActions(
                            isSaving: _isSaving,
                            isDirty: widget.isDirty,
                            lastSavedAt: _lastSavedAt,
                            saveLabel: saveLabel,
                            explicitSaveLabel: saveLabel,
                            onSave: () => _saveJournal(),
                            showAddToLibrary: widget.onAddToLibrary != null,
                            libraryLabel: hasJournal
                                ? '서재에 담기'
                                : '저장하고 서재에 담기',
                            onAddToLibrary: _handleAddToLibrary,
                            canDeleteMd: hasJournal,
                            onDeleteArchive: hasJournal ? _confirmDelete : null,
                          ),
                        ),
                      ),
                    ),
                    EntityDetailConnectionsPanel(
                      entity: _entity,
                      linkNeighbors: _linkNeighbors,
                      loadingLinkNeighbors: _loadingLinkNeighbors,
                      draftTags: _draftTags,
                      onOpenLinkedEntity: _openLinkedEntity,
                      onOpenLinkedWork: _openLinkedWork,
                      onGoKnowledgeGraph: widget.onGoKnowledgeGraph,
                      onFocusSanctum: _focusSanctumForLinks,
                      onAddEntityLink: widget.userCatalog != null
                          ? _requestEntityLinkForType
                          : null,
                      onAddWorkLink: widget.userCatalog != null
                          ? _requestWorkLink
                          : null,
                      loadingIncoming: _loadingIncoming,
                      incomingPaths: _incomingPaths,
                      staleLabelRecordCount: _staleLabelRecordCount,
                      onRefreshIncoming: _loadIncoming,
                      onOpenIncoming: _openIncoming,
                      loadingSameDay: _loadingSameDay,
                      sameDayRefs: _sameDayRefs,
                      onOpenSameDay: _openSameDay,
                      onDraftTagsChanged: (tags) {
                        setState(() => _draftTags = tags);
                        _updatePreview();
                        _markDirty();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}
