import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/archiving/record_link.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_archive_service.dart';
import '../../../services/entity_journal_parser.dart';
import '../../../services/entity_vault_path_conflict.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/file_service.dart';
import '../../../utils/entity_tag_validation.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'entity_detail_info_panel.dart';

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
    required this.onSaved,
    required this.onDeleted,
    required this.onDirtyChanged,
    required this.onBindSave,
    this.onPreserveDraft,
    this.onInfoWidthChanged,
    this.onToggleInfoLock,
    this.onWikiLinkTap,
    this.onRequestEntityLink,
  });

  final UserCatalogEntity entity;
  final EntityJournalEntry? journal;
  final String tabId;
  final bool isDirty;
  final double infoPanelWidth;
  final bool infoPanelLocked;
  final UserCatalogPort? userCatalog;
  final void Function(
    UserCatalogEntity entity,
    EntityJournalEntry? journal,
  ) onSaved;
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

  @override
  State<EntityDetailWorkspace> createState() => _EntityDetailWorkspaceState();
}

class _EntityDetailWorkspaceState extends State<EntityDetailWorkspace> {
  static final _store = EntityVaultStore();

  late UserCatalogEntity _entity;
  EntityJournalEntry? _journal;
  late List<String> _draftTags;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _fileCtrl;
  SanctumPageView _pageView = SanctumPageView.preview;
  bool _isSaving = false;
  bool _suppressPersist = false;
  DateTime? _lastSavedAt;
  Timer? _autoSaveTimer;

  static const _autoSaveDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _entity = widget.entity;
    _journal = widget.journal;
    _draftTags = List<String>.from(_journal?.tags ?? _entity.tags);
    _bodyCtrl = TextEditingController(text: _journal?.body ?? '');
    _fileCtrl = TextEditingController(text: _serializeFile());
    _pageView = _bodyCtrl.text.trim().isEmpty
        ? SanctumPageView.body
        : SanctumPageView.preview;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
  }

  @override
  void didUpdateWidget(EntityDetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabId != widget.tabId) {
      _entity = widget.entity;
      _journal = widget.journal;
      _draftTags = List<String>.from(_journal?.tags ?? _entity.tags);
      _bodyCtrl.text = _journal?.body ?? '';
      _fileCtrl.text = _serializeFile();
      _pageView = _bodyCtrl.text.trim().isEmpty
          ? SanctumPageView.body
          : SanctumPageView.preview;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindSaveHandler());
      return;
    }
    if (!widget.isDirty &&
        (oldWidget.entity.entityId != widget.entity.entityId ||
            oldWidget.journal?.storagePath != widget.journal?.storagePath)) {
      _entity = widget.entity;
      _journal = widget.journal;
      _draftTags = List<String>.from(_journal?.tags ?? _entity.tags);
      _bodyCtrl.text = _journal?.body ?? '';
      _fileCtrl.text = _serializeFile();
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
      );
    }
    return EntityJournalParser.serialize(
      entityType: entry.entityType,
      entityId: entry.entityId,
      title: entry.title,
      body: _bodyCtrl.text,
      addedAt: entry.addedAt,
      tags: _draftTags,
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
    _autoSaveTimer?.cancel();
    if (_suppressPersist) return;
    if (AkashaFileService().vaultPath == null) return;
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      if (!mounted || !widget.isDirty) return;
      unawaited(_saveJournal(silent: true));
    });
  }

  @override
  void deactivate() {
    _autoSaveTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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
    super.dispose();
  }

  Future<void> _saveJournal({bool silent = false}) async {
    if (_suppressPersist || _isSaving) return;
    final vaultPath = AkashaFileService().vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      if (!silent && mounted) {
        _showSnack('볼트를 먼저 연결해 주세요.');
      }
      return;
    }

    if (_pageView == SanctumPageView.file) {
      _syncBodyFromEditor();
    }

    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) {
      if (!silent && mounted) {
        _showSnack('본문을 입력해 주세요.');
      }
      return;
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
      final entityDraft = _entity.copyWith(tags: _draftTags);
      EntityJournalEntry saved;
      if (_journal == null) {
        saved = await _store.saveCatalogEntity(
          vaultPath: vaultPath,
          entity: entityDraft,
          body: body,
        );
      } else {
        saved = await _store.updateEntry(
          entry: _journal!,
          body: body,
          tags: _draftTags,
        );
      }

      var mirrored = entityDraft;
      if (catalog != null) {
        mirrored = await EntityArchiveService.syncCatalogFromJournal(
          draft: entityDraft,
          entry: saved,
          userCatalog: catalog,
        );
      }

      if (!mounted) return;
      setState(() {
        _entity = mirrored;
        _journal = saved;
        _draftTags = List<String>.from(saved.tags);
        _fileCtrl.text = _serializeFile();
        _lastSavedAt = DateTime.now();
        if (!silent && _pageView != SanctumPageView.file) {
          _pageView = SanctumPageView.preview;
        }
      });
      widget.onDirtyChanged(false);
      widget.onSaved(mirrored, saved);
      if (!silent) {
        _showSnack('"${mirrored.title}" entity journal을 저장했습니다.');
      }
    } on EntityVaultPathConflict catch (e) {
      if (mounted && !silent) _showSnack(e.userMessage);
    } catch (e) {
      if (mounted && !silent) _showSnack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

    final deleted = await EntityArchiveService.deleteArchivedEntity(
      entry: _journal!,
      userCatalog: catalog,
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

  @override
  Widget build(BuildContext context) {
    final hasJournal = _journal != null;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EntityDetailInfoPanel(
                entity: _entity,
                hasJournal: hasJournal,
                panelWidth: widget.infoPanelWidth,
                infoPanelLocked: widget.infoPanelLocked,
                draftTags: _draftTags,
                isSaving: _isSaving,
                onInfoWidthChanged: widget.onInfoWidthChanged,
                onToggleInfoLock: widget.onToggleInfoLock,
                onDraftTagsChanged: (tags) {
                  setState(() => _draftTags = tags);
                  _markDirty();
                },
                onSave: () => _saveJournal(),
                canDeleteMd: hasJournal,
                onDeleteArchive: hasJournal ? _confirmDelete : null,
              ),
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFF12121A),
                  child: SanctumPagePanel(
                    view: _pageView,
                    onViewChanged: _onPageViewChanged,
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
                  ),
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
