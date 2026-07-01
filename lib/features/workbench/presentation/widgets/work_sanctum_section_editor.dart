import 'package:flutter/material.dart';

import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/entity_link_selection.dart';
import '../../../../models/sanctum_cast_entry.dart';
import '../../../../models/sanctum_gallery_entry.dart';
import '../../../../services/markdown_body_merger.dart';
import '../../../../services/sanctum_image_import.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../utils/markdown_edit_actions.dart';
import 'sanctum/sanctum_cast_section_editor.dart';
import 'sanctum/sanctum_gallery_section_editor.dart';
import 'sanctum/sanctum_quotes_section_editor.dart';
import 'sanctum/sanctum_section_card.dart';
import '../../../../utils/app_l10n.dart';

/// 워크벤치 중앙 Sanctum 슬롯 섹션 편집 (출연 · 갤러리 · 설명 · 감상 · 명장면). 본문 md와 동기화.
class WorkSanctumSectionEditor extends StatefulWidget {
  const WorkSanctumSectionEditor({
    super.key,
    required this.bodyController,
    required this.onChanged,
    this.userCatalog,
  });

  final TextEditingController bodyController;
  final VoidCallback onChanged;
  final UserCatalogPort? userCatalog;

  @override
  State<WorkSanctumSectionEditor> createState() =>
      WorkSanctumSectionEditorState();
}

class WorkSanctumSectionEditorState extends State<WorkSanctumSectionEditor> {
  late final TextEditingController _synopsisCtrl;
  late final TextEditingController _memoCtrl;
  late final TextEditingController _quotesCtrl;
  List<SanctumCastEntry> _castEntries = [];
  List<SanctumGalleryEntry> _galleryEntries = [];
  var _quotesExpanded = false;
  var _flushLock = false;

  @override
  void initState() {
    super.initState();
    _synopsisCtrl = TextEditingController();
    _memoCtrl = TextEditingController();
    _quotesCtrl = TextEditingController();
    _loadFromBody();
    widget.bodyController.addListener(_onBodyExternalChange);
    for (final ctrl in [_synopsisCtrl, _memoCtrl, _quotesCtrl]) {
      ctrl.addListener(_onSectionChanged);
    }
  }

  @override
  void dispose() {
    widget.bodyController.removeListener(_onBodyExternalChange);
    _synopsisCtrl.removeListener(_onSectionChanged);
    _memoCtrl.removeListener(_onSectionChanged);
    _quotesCtrl.removeListener(_onSectionChanged);
    _synopsisCtrl.dispose();
    _memoCtrl.dispose();
    _quotesCtrl.dispose();
    super.dispose();
  }

  void insertWikiLink(EntityLinkSelection picked) {
    final patch = MarkdownEditActions.insertWikiLink(
      text: _memoCtrl.text,
      selection: _memoCtrl.selection,
      entityId: picked.entityId,
      title: picked.title,
    );
    _memoCtrl.text = patch.text;
    _memoCtrl.selection = patch.selection;
    _flushToBody();
    widget.onChanged();
  }

  /// 외부에서 본문을 교체한 뒤 섹션 편집기를 다시 읽습니다.
  void reloadFromBody() => _loadFromBody();

  void insertCastEntry(EntityLinkSelection picked, {String? role}) {
    if (_castEntries.any((entry) => entry.entityId == picked.entityId)) return;
    setState(() {
      _castEntries = [
        ..._castEntries,
        SanctumCastEntry(
          entityId: picked.entityId,
          title: picked.title,
          role: role,
        ),
      ];
    });
    _flushToBody();
    widget.onChanged();
  }

  void _onBodyExternalChange() {
    if (_flushLock) return;
    _loadFromBody();
  }

  void _onSectionChanged() {
    if (_flushLock) return;
    _flushToBody();
    widget.onChanged();
  }

  void _loadFromBody() {
    _flushLock = true;
    final slots = MarkdownBodyMerger.parseSlots(widget.bodyController.text);
    _castEntries = List<SanctumCastEntry>.from(slots.cast);
    _galleryEntries = List<SanctumGalleryEntry>.from(slots.gallery);
    _synopsisCtrl.text = slots.synopsis;
    _memoCtrl.text = slots.memo;
    _quotesCtrl.text = slots.quotes.join('\n');
    if (slots.quotes.isNotEmpty) {
      _quotesExpanded = true;
    }
    _flushLock = false;
    if (mounted) setState(() {});
  }

  void _flushToBody() {
    final quotes = _quotesCtrl.text
        .split('\n')
        .map((line) => line.trim().replaceFirst(RegExp(r'^>\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();

    final merged = MarkdownBodyMerger.mergeBody(
      bodyRaw: widget.bodyController.text,
      cast: _castEntries,
      gallery: _galleryEntries,
      synopsis: _synopsisCtrl.text,
      quotes: quotes,
      memo: _memoCtrl.text,
    );

    if (merged == widget.bodyController.text) return;

    _flushLock = true;
    widget.bodyController.text = merged;
    _flushLock = false;
  }

  void _updateCastRole(int index, String role) {
    final entry = _castEntries[index];
    final nextRole = role.trim();
    _castEntries[index] = SanctumCastEntry(
      entityId: entry.entityId,
      title: entry.title,
      role: nextRole.isEmpty ? null : nextRole,
    );
    _flushToBody();
    widget.onChanged();
  }

  void _removeCastEntry(int index) {
    setState(() {
      _castEntries = List<SanctumCastEntry>.from(_castEntries)..removeAt(index);
    });
    _flushToBody();
    widget.onChanged();
  }

  Future<void> _importGalleryPaths(List<String> paths) async {
    if (paths.isEmpty) return;
    setState(() {
      _galleryEntries = [
        ..._galleryEntries,
        for (final path in paths) SanctumGalleryEntry(imagePath: path),
      ];
    });
    _flushToBody();
    widget.onChanged();
  }

  Future<void> _addGalleryImage() async {
    final l10n = lookupAppL10n(context);
    if (!SanctumImageImport.canImport) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorAddImageVaultRequired ??
                '이미지 추가는 Sanctum 볼트 연결 후 사용할 수 있습니다.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final path = await SanctumImageImport.pickAndImport();
    if (!mounted || path == null) return;
    await _importGalleryPaths([path]);
  }

  Future<void> _pasteGalleryFromClipboard() async {
    final l10n = lookupAppL10n(context);
    if (!SanctumImageImport.canImport) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorPasteVaultRequired ??
                '붙여넣기는 Sanctum 볼트 연결 후 사용할 수 있습니다.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final imported = await SanctumImageImport.importFromClipboard();
    if (!mounted) return;
    if (imported.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.errorNoImageInClipboard ?? '클립보드에 이미지가 없습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    await _importGalleryPaths(imported);
  }

  void _removeGalleryEntry(int index) {
    setState(() {
      _galleryEntries = List<SanctumGalleryEntry>.from(_galleryEntries)
        ..removeAt(index);
    });
    _flushToBody();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AkashaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SanctumCastSectionEditor(
            entries: _castEntries,
            userCatalog: widget.userCatalog,
            onRoleChanged: _updateCastRole,
            onRemove: _removeCastEntry,
          ),
          const SizedBox(height: AkashaSpacing.md),
          SanctumGallerySectionEditor(
            entries: _galleryEntries,
            onAdd: _addGalleryImage,
            onPaste: _pasteGalleryFromClipboard,
            onImportPaths: _importGalleryPaths,
            onRemove: _removeGalleryEntry,
          ),
          const SizedBox(height: AkashaSpacing.md),
          SanctumSectionCard(
            icon: Icons.description_outlined,
            title: l10n != null
                ? l10n.workbenchSynopsisSectionTitle.replaceAll('📋', '').trim()
                : '설명',
            hint: l10n?.hintSynopsisEditor ?? '줄거리·세계관·배경을 적어 보세요.',
            controller: _synopsisCtrl,
            minLines: 5,
          ),
          const SizedBox(height: AkashaSpacing.md),
          SanctumSectionCard(
            icon: Icons.rate_review_outlined,
            title: l10n != null
                ? l10n.workbenchMemoSectionTitle.replaceAll('📝', '').trim()
                : '감상',
            hint:
                l10n?.hintMemoEditor ??
                '기록·평가·느낀 점. 우측 「추가」로 [[링크]]를 넣을 수 있습니다.',
            controller: _memoCtrl,
            minLines: 8,
          ),
          const SizedBox(height: AkashaSpacing.md),
          SanctumQuotesSectionEditor(
            expanded: _quotesExpanded,
            onToggle: () => setState(() => _quotesExpanded = !_quotesExpanded),
            controller: _quotesCtrl,
          ),
        ],
      ),
    );
  }
}
