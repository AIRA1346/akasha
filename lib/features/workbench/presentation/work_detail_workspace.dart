import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/record_link.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/link_candidate_service.dart';
import '../../../services/sanctum_body_templates.dart';
import '../../../utils/app_l10n.dart';
import '../../../services/workbench_recovery_draft_store.dart';
import '../../../services/vault_recovery_write_service.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'work_detail_archive_ops.dart';
import 'work_detail_connections_coordinator.dart';
import 'work_detail_delete_flow_ops.dart';
import 'work_detail_draft_bundle.dart';
import 'work_detail_draft_ops.dart';
import 'work_detail_item_hydration.dart';
import 'work_detail_library_ops.dart';
import 'work_detail_link_pick_ops.dart';
import 'work_detail_sanctum_workspace_ops.dart';
import 'work_detail_save_ops.dart';
import 'work_detail_save_orchestrator.dart';
import 'work_detail_save_ui_patch.dart';
import 'workbench_autosave_scheduler.dart';
import 'workbench_linked_record_ops.dart';
import 'workbench_vault.dart';
import 'workbench_vault_disk_ops.dart';
import 'workbench_vault_reload_flow.dart';
import 'workbench_vault_reload_messages.dart';
import 'workbench_workspace_record_nav.dart';
import 'widgets/workbench_save_shortcuts.dart';
import 'widgets/work_detail_workspace_body.dart';
import 'widgets/work_sanctum_section_editor.dart';

part 'work_detail_workspace_ui.part.dart';
part 'work_detail_workspace_vault.part.dart';
part 'work_detail_workspace_links.part.dart';
part 'work_detail_workspace_persist.part.dart';

/// 3열 작품정보 + 4열 Sanctum md (워크벤치 작업 뷰)
class WorkDetailWorkspace extends StatefulWidget {
  final AkashaItem item;
  final String tabId;
  final bool isDirty;
  final double infoPanelWidth;
  final bool infoPanelLocked;
  final UserCatalogPort? userCatalog;
  final RecordLinkPort? linkIndex;
  final List<AkashaItem> vaultItems;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final void Function(AkashaItem saved, {required bool silent, bool dirty})
  onSaved;
  final VoidCallback onDeleted;
  final ValueChanged<bool> onDirtyChanged;
  final Future<void> Function(AkashaItem item)? onAddToLibrary;
  final void Function(Future<void> Function()? save)? onBindSave;
  final void Function(String tabId, AkashaItem draft)? onPreserveDraft;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )?
  onRequestEntityLink;
  final VoidCallback? onClose;
  final VoidCallback? onGoKnowledgeGraph;
  final EntityAnchorType? pendingEntityLinkType;
  final String? pendingEntityLinkWorkId;
  final LinkCandidate? pendingEntityLinkCandidate;
  final bool pendingWorkLinkPick;
  final VoidCallback? onPendingEntityLinkHandled;
  final void Function(AkashaItem item)? onRecordOpenWork;
  final Future<void> Function(UserCatalogEntity entity)? onRecordOpenEntity;

  const WorkDetailWorkspace({
    super.key,
    required this.item,
    required this.tabId,
    this.isDirty = false,
    required this.infoPanelWidth,
    this.infoPanelLocked = false,
    this.userCatalog,
    this.linkIndex,
    this.vaultItems = const [],
    this.onInfoWidthChanged,
    this.onToggleInfoLock,
    required this.onSaved,
    required this.onDeleted,
    required this.onDirtyChanged,
    this.onAddToLibrary,
    this.onBindSave,
    this.onPreserveDraft,
    this.onWikiLinkTap,
    this.onRequestEntityLink,
    this.onClose,
    this.onGoKnowledgeGraph,
    this.pendingEntityLinkType,
    this.pendingEntityLinkWorkId,
    this.pendingEntityLinkCandidate,
    this.pendingWorkLinkPick = false,
    this.onPendingEntityLinkHandled,
    this.onRecordOpenWork,
    this.onRecordOpenEntity,
  });

  @override
  State<WorkDetailWorkspace> createState() => _WorkDetailWorkspaceState();
}

abstract class _WorkDetailWorkspaceStateBase
    extends State<WorkDetailWorkspace> {
  late AkashaItem _item;
  bool _isSaving = false;

  late double _draftRating;
  late String _draftWorkStatus;
  late String _draftMyStatus;
  late bool _draftHallOfFame;
  List<String> _draftTags = [];
  Set<String> _registryTags = {};

  late TextEditingController _titleCtrl;
  late TextEditingController _posterUrlCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _fileCtrl;
  SanctumPageView _pageView = SanctumPageView.preview;

  StreamSubscription<void>? _vaultSub;
  late final WorkDetailConnectionsCoordinator _connections;
  DateTime? _lastSavedAt;
  final WorkbenchAutosaveScheduler _autosave = WorkbenchAutosaveScheduler();
  final WorkbenchRecoveryDraftStore _recoveryDraftStore =
      const WorkbenchRecoveryDraftStore();
  Timer? _recoveryDraftTimer;
  bool _recoveryPromptShown = false;
  bool _suppressPersist = false;

  final GlobalKey<WorkSanctumSectionEditorState> _sectionEditorKey =
      GlobalKey<WorkSanctumSectionEditorState>();

  bool get _externalChangePending => _connections.externalChangePending;

  WorkDetailDraftBundle get _draft => WorkDetailDraftBundle(
    item: _item,
    pageView: _pageView,
    titleCtrl: _titleCtrl,
    bodyCtrl: _bodyCtrl,
    fileCtrl: _fileCtrl,
    posterUrlCtrl: _posterUrlCtrl,
    draftRating: _draftRating,
    draftWorkStatus: _draftWorkStatus,
    draftMyStatus: _draftMyStatus,
    draftHallOfFame: _draftHallOfFame,
    draftTags: _draftTags,
  );

  void _refreshRecordLinks() {
    _connections.refreshAll(
      work: _item,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }

  void _applyItem(
    AkashaItem item, {
    required bool resetPageView,
    bool preserveBodyEditor = false,
  }) {
    WorkDetailItemHydration.fromItem(
      item,
      resetPageView: resetPageView,
      preserveBodyEditor: preserveBodyEditor,
      currentBodyText: _bodyCtrl.text,
      currentPageView: _pageView,
    ).writeTo(
      setItem: (next) => _item = next,
      titleCtrl: _titleCtrl,
      posterUrlCtrl: _posterUrlCtrl,
      bodyCtrl: _bodyCtrl,
      setPageView: (view) => _pageView = view,
      setDraftState: (tags, registry, rating, workStatus, myStatus, hall) {
        _draftTags = tags;
        _registryTags = registry;
        _draftRating = rating;
        _draftWorkStatus = workStatus;
        _draftMyStatus = myStatus;
        _draftHallOfFame = hall;
      },
    );
    _draft.refreshFullFileEditor();
    _connections.refreshDiskMtime(_item.filePath);
    _connections.loadLinkNeighbors(
      work: _item,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }
}

class _WorkDetailWorkspaceState extends _WorkDetailWorkspaceStateBase
    with
        _WorkDetailWorkspacePersist,
        _WorkDetailWorkspaceVault,
        _WorkDetailWorkspaceLinks {
  @override
  void initState() {
    super.initState();
    _connections = WorkDetailConnectionsCoordinator(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _titleCtrl = TextEditingController();
    _posterUrlCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _fileCtrl = TextEditingController();
    _applyItem(widget.item, resetPageView: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
    _vaultSub = WorkbenchVault.port.onVaultUpdated.listen((_) {
      _onVaultDiskChanged();
    });
    _connections.refreshDiskMtime(_item.filePath);
    _refreshRecordLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeOfferRecoveryDraft();
      _maybeRunPendingEntityLinkPick();
    });
  }

  @override
  void didUpdateWidget(WorkDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      _applyItem(widget.item, resetPageView: true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
      _refreshRecordLinks();
      return;
    }
    if (!widget.isDirty &&
        !WorkDetailDraftOps.sameItemSnapshot(oldWidget.item, widget.item)) {
      _applyItem(
        widget.item,
        resetPageView: false,
        preserveBodyEditor: _pageView == SanctumPageView.body,
      );
      _connections.loadIncoming(work: _item, linkIndex: widget.linkIndex);
      _connections.loadSameDay(work: _item);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
  }

  @override
  void deactivate() {
    _autosave.cancel();
    _recoveryDraftTimer?.cancel();
    if (!_suppressPersist) {
      _flushAutoSaveIfNeeded();
      if (widget.isDirty) {
        unawaited(_saveRecoveryDraftNow());
      }
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _autosave.dispose();
    _recoveryDraftTimer?.cancel();
    if (!_suppressPersist && widget.isDirty) {
      if (_pageView == SanctumPageView.file) {
        WorkDetailDraftOps.applyFileEditorToItem(
          item: _item,
          titleCtrl: _titleCtrl,
          bodyCtrl: _bodyCtrl,
          fileCtrl: _fileCtrl,
        );
      } else {
        WorkDetailDraftOps.syncBodyFromEditor(_item, _bodyCtrl);
      }
      widget.onPreserveDraft?.call(widget.tabId, _draft.buildSaveDraft());
    }
    _vaultSub?.cancel();
    widget.onBindSave?.call(null);
    _titleCtrl.dispose();
    _posterUrlCtrl.dispose();
    _bodyCtrl.dispose();
    _fileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorkbenchSaveShortcuts(
      onSave: _saveArchive,
      child: _buildWorkDetailWorkspaceBody(this),
    );
  }
}
