import 'package:flutter/material.dart';

import '../../../../models/entity_link_selection.dart';
import '../../../../models/sanctum_cast_entry.dart';
import '../../../../services/markdown_body_merger.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_radius.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/markdown_edit_actions.dart';

/// 워크벤치 중앙 Sanctum 슬롯 섹션 편집 (출연 · 설명 · 감상 · 명장면). 본문 md와 동기화.
class WorkSanctumSectionEditor extends StatefulWidget {
  const WorkSanctumSectionEditor({
    super.key,
    required this.bodyController,
    required this.onChanged,
  });

  final TextEditingController bodyController;
  final VoidCallback onChanged;

  @override
  State<WorkSanctumSectionEditor> createState() =>
      WorkSanctumSectionEditorState();
}

class WorkSanctumSectionEditorState extends State<WorkSanctumSectionEditor> {
  late final TextEditingController _synopsisCtrl;
  late final TextEditingController _memoCtrl;
  late final TextEditingController _quotesCtrl;
  List<SanctumCastEntry> _castEntries = [];
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AkashaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CastSection(
            entries: _castEntries,
            onRoleChanged: _updateCastRole,
            onRemove: _removeCastEntry,
          ),
          const SizedBox(height: AkashaSpacing.md),
          _SectionCard(
            icon: Icons.description_outlined,
            title: '설명',
            hint: '줄거리·세계관·배경을 적어 보세요.',
            controller: _synopsisCtrl,
            minLines: 5,
          ),
          const SizedBox(height: AkashaSpacing.md),
          _SectionCard(
            icon: Icons.rate_review_outlined,
            title: '감상',
            hint: '기록·평가·느낀 점. 우측 「추가」로 [[링크]]를 넣을 수 있습니다.',
            controller: _memoCtrl,
            minLines: 8,
          ),
          const SizedBox(height: AkashaSpacing.md),
          _QuotesSection(
            expanded: _quotesExpanded,
            onToggle: () => setState(() => _quotesExpanded = !_quotesExpanded),
            controller: _quotesCtrl,
          ),
        ],
      ),
    );
  }
}

class _CastSection extends StatelessWidget {
  const _CastSection({
    required this.entries,
    required this.onRoleChanged,
    required this.onRemove,
  });

  final List<SanctumCastEntry> entries;
  final void Function(int index, String role) onRoleChanged;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AkashaColors.surface.withValues(alpha: 0.35),
        borderRadius: AkashaRadius.mdBorder,
        border: Border.all(color: AkashaColors.borderSubtle(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AkashaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16, color: AkashaColors.accent),
                const SizedBox(width: AkashaSpacing.sm),
                Text('출연', style: AkashaTypography.sectionTitle),
              ],
            ),
            const SizedBox(height: AkashaSpacing.sm),
            if (entries.isEmpty)
              Text(
                '우측 「인물 추가」로 출연진을 넣으면 미리보기 상단에 카드로 표시됩니다.',
                style: AkashaTypography.bodySecondary,
              )
            else
              ...List.generate(entries.length, (index) {
                final entry = entries[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == entries.length - 1 ? 0 : AkashaSpacing.sm,
                  ),
                  child: _CastEntryRow(
                    entry: entry,
                    onRoleChanged: (role) => onRoleChanged(index, role),
                    onRemove: () => onRemove(index),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CastEntryRow extends StatefulWidget {
  const _CastEntryRow({
    required this.entry,
    required this.onRoleChanged,
    required this.onRemove,
  });

  final SanctumCastEntry entry;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onRemove;

  @override
  State<_CastEntryRow> createState() => _CastEntryRowState();
}

class _CastEntryRowState extends State<_CastEntryRow> {
  late final TextEditingController _roleCtrl;

  @override
  void initState() {
    super.initState();
    _roleCtrl = TextEditingController(text: widget.entry.role ?? '');
  }

  @override
  void didUpdateWidget(covariant _CastEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.role != widget.entry.role &&
        _roleCtrl.text != (widget.entry.role ?? '')) {
      _roleCtrl.text = widget.entry.role ?? '';
    }
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AkashaColors.workbenchEditor,
        borderRadius: AkashaRadius.smBorder,
        border: Border.all(color: AkashaColors.borderSubtle(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.title,
                    style: AkashaTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _roleCtrl,
                    onChanged: widget.onRoleChanged,
                    style: AkashaTypography.caption,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '역할 (예: 주인공)',
                      hintStyle: AkashaTypography.bodySecondary,
                      border: OutlineInputBorder(
                        borderRadius: AkashaRadius.smBorder,
                        borderSide: BorderSide(
                          color: AkashaColors.borderSubtle(0.08),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onRemove,
              icon: Icon(Icons.close, size: 16, color: Colors.grey[500]),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.controller,
    required this.minLines,
  });

  final IconData icon;
  final String title;
  final String hint;
  final TextEditingController controller;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AkashaColors.surface.withValues(alpha: 0.35),
        borderRadius: AkashaRadius.mdBorder,
        border: Border.all(color: AkashaColors.borderSubtle(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AkashaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AkashaColors.accent),
                const SizedBox(width: AkashaSpacing.sm),
                Text(title, style: AkashaTypography.sectionTitle),
              ],
            ),
            const SizedBox(height: AkashaSpacing.sm),
            TextField(
              controller: controller,
              minLines: minLines,
              maxLines: null,
              style: AkashaTypography.body,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AkashaTypography.bodySecondary,
                filled: true,
                fillColor: AkashaColors.workbenchEditor,
                border: OutlineInputBorder(
                  borderRadius: AkashaRadius.smBorder,
                  borderSide: BorderSide(
                    color: AkashaColors.borderSubtle(0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AkashaRadius.smBorder,
                  borderSide: BorderSide(
                    color: AkashaColors.borderSubtle(0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AkashaRadius.smBorder,
                  borderSide: const BorderSide(color: AkashaColors.accent),
                ),
                contentPadding: const EdgeInsets.all(AkashaSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotesSection extends StatelessWidget {
  const _QuotesSection({
    required this.expanded,
    required this.onToggle,
    required this.controller,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AkashaColors.surface.withValues(alpha: 0.2),
        borderRadius: AkashaRadius.mdBorder,
        border: Border.all(color: AkashaColors.borderSubtle(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: AkashaRadius.mdBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AkashaSpacing.md,
                vertical: AkashaSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote_outlined,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: AkashaSpacing.sm),
                  Text(
                    '명장면 & 명대사',
                    style: AkashaTypography.bodySecondary.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AkashaSpacing.md),
              child: TextField(
                controller: controller,
                minLines: 3,
                maxLines: null,
                style: AkashaTypography.body,
                decoration: InputDecoration(
                  hintText: '한 줄에 한 문장씩 입력하세요.',
                  hintStyle: AkashaTypography.bodySecondary,
                  filled: true,
                  fillColor: AkashaColors.workbenchEditor,
                  border: OutlineInputBorder(
                    borderRadius: AkashaRadius.smBorder,
                    borderSide: BorderSide(
                      color: AkashaColors.borderSubtle(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AkashaRadius.smBorder,
                    borderSide: BorderSide(
                      color: AkashaColors.borderSubtle(0.08),
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(AkashaSpacing.md),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
