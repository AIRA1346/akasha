import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/archiving/record_link.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/poster_url_localizer.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'entity_detail_archive_ops.dart';
import 'entity_detail_connections_coordinator.dart';
import 'entity_detail_delete_flow_ops.dart';
import 'entity_detail_draft_ops.dart';
import 'entity_detail_library_ops.dart';
import 'entity_detail_link_pick_ops.dart';
import 'entity_detail_sanctum_ops.dart';
import 'entity_detail_save_ops.dart';
import 'entity_detail_save_orchestrator.dart';
import 'entity_detail_save_ui_patch.dart';
import 'workbench_autosave_scheduler.dart';
import 'workbench_linked_record_ops.dart';
import 'workbench_vault.dart';
import 'workbench_vault_disk_ops.dart';
import 'workbench_vault_reload_flow.dart';
import 'workbench_vault_reload_messages.dart';
import 'workbench_workspace_record_nav.dart';
import 'widgets/entity_detail_workspace_body.dart';
import 'widgets/workbench_save_shortcuts.dart';

part 'entity_detail_workspace_ui.part.dart';
part 'entity_detail_workspace_vault.part.dart';
part 'entity_detail_workspace_links.part.dart';
part 'entity_detail_workspace_persist.part.dart';

final _entityDetailVaultStore = EntityVaultStore();

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

abstract class _EntityDetailWorkspaceStateBase extends State<EntityDetailWorkspace> {
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
  StreamSubscription<void>? _vaultSub;
  late final EntityDetailConnectionsCoordinator _connections;

  bool get _externalChangePending => _connections.externalChangePending;

  void _refreshRecordLinks() {
    _connections.refreshAll(
      entity: _entity,
      journal: _journal,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }

  EntityItem _buildEntityItem(UserCatalogEntity entity, EntityJournalEntry? journal) =>
      EntityDetailDraftOps.buildEntityItem(entity, journal);

  void _applySnapshot(EntityDetailWorkspaceSnapshot snapshot) {
    _entity = snapshot.entity;
    _journal = snapshot.journal;
    _item = snapshot.item;
    _preview = snapshot.preview;
    _draftTags = snapshot.draftTags;
    _pageView = snapshot.pageView;
    _bodyCtrl.text = snapshot.bodyText;
    _posterUrlCtrl.text = snapshot.posterText;
    _fileCtrl.text = snapshot.fileText;
  }

  void _updatePreview() {
    setState(() {
      _preview = EntityDetailDraftOps.buildPreviewItem(
        entity: _entity,
        journal: _journal,
        posterPath: _posterUrlCtrl.text,
        tags: _draftTags,
        bodyRaw: _bodyCtrl.text,
      );
    });
  }
}

class _EntityDetailWorkspaceState extends _EntityDetailWorkspaceStateBase
    with
        _EntityDetailWorkspacePersist,
        _EntityDetailWorkspaceVault,
        _EntityDetailWorkspaceLinks {
  @override
  void initState() {
    super.initState();
    _connections = EntityDetailConnectionsCoordinator(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _entity = widget.entity;
    _journal = widget.journal;
    final snapshot = EntityDetailWorkspaceSnapshot.fromProps(
      entity: _entity,
      journal: _journal,
    );
    _item = snapshot.item;
    _preview = snapshot.preview;
    _draftTags = snapshot.draftTags;
    _bodyCtrl = TextEditingController(text: snapshot.bodyText);
    _posterUrlCtrl = TextEditingController(text: snapshot.posterText);
    _posterUrlCtrl.addListener(_updatePreview);
    _fileCtrl = TextEditingController(text: snapshot.fileText);
    _pageView = snapshot.pageView;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
    _vaultSub = WorkbenchVault.port.onVaultUpdated.listen((_) {
      _onVaultDiskChanged();
    });
    _connections.refreshDiskMtime(_journal?.storagePath);
    _refreshRecordLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRunPendingEntityLinkPick();
    });
  }

  @override
  void didUpdateWidget(EntityDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      final snapshot = EntityDetailWorkspaceSnapshot.fromProps(
        entity: widget.entity,
        journal: widget.journal,
      );
      setState(() {
        _applySnapshot(snapshot);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
      _refreshRecordLinks();
      _connections.refreshDiskMtime(_journal?.storagePath);
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
      _connections.loadIncoming(
        entity: _entity,
        journal: _journal,
        linkIndex: widget.linkIndex,
      );
      _connections.loadSameDay(entity: _entity, journal: _journal);
      _connections.loadLinkNeighbors(
        entity: _entity,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      );
      _connections.refreshDiskMtime(_journal?.storagePath);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
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
    _vaultSub?.cancel();
    _bodyCtrl.dispose();
    _fileCtrl.dispose();
    _posterUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorkbenchSaveShortcuts(
      onSave: () => _saveJournal(),
      child: _buildEntityDetailWorkspaceBody(this),
    );
  }
}
