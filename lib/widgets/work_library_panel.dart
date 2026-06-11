import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/membership_apply_result.dart';
import '../models/personal_library_config.dart';
import '../services/personal_library_membership_service.dart';

/// 서재 멤버십 체크리스트 + (선택) 표시 숨기기 — popover/dialog 공통 본문
class WorkLibraryPanel extends StatefulWidget {
  final String displayTitle;
  final List<String> singleWorkIds;
  final List<String> entireIpWorkIds;
  final bool showIpScopeOption;
  final PersonalLibraryMembershipService membership;
  final String? activeLibraryId;
  final Future<PersonalLibraryConfig?> Function()? onCreateLibrary;
  final VoidCallback? onHideFromRegistry;
  final VoidCallback? onHideFranchise;
  final void Function(MembershipApplyResult result)? onApplied;
  final VoidCallback? onCancel;

  const WorkLibraryPanel({
    super.key,
    required this.displayTitle,
    required this.singleWorkIds,
    required this.entireIpWorkIds,
    required this.showIpScopeOption,
    required this.membership,
    this.activeLibraryId,
    this.onCreateLibrary,
    this.onHideFromRegistry,
    this.onHideFranchise,
    this.onApplied,
    this.onCancel,
  });

  bool get hasLibrarySection => membership.curatedLibraries.isNotEmpty;

  bool get hasHideSection =>
      onHideFromRegistry != null || onHideFranchise != null;

  @override
  State<WorkLibraryPanel> createState() => _WorkLibraryPanelState();
}

class _WorkLibraryPanelState extends State<WorkLibraryPanel> {
  var _useEntireIp = false;
  late Map<String, bool> _checked;
  late Map<String, bool> _initialChecked;
  var _applying = false;
  var _hideExpanded = false;

  @override
  void initState() {
    super.initState();
    _syncCheckedFromMembership();
  }

  List<String> get _effectiveIds =>
      widget.showIpScopeOption && _useEntireIp
          ? widget.entireIpWorkIds
          : widget.singleWorkIds;

  void _syncCheckedFromMembership() {
    final ids = _effectiveIds;
    _initialChecked = {
      for (final lib in widget.membership.curatedLibraries)
        lib.id: widget.membership.librariesContainingAll(ids).contains(lib.id),
    };
    _checked = Map<String, bool>.from(_initialChecked);
  }

  List<PersonalLibraryConfig> get _sortedLibraries {
    final list = List<PersonalLibraryConfig>.from(
      widget.membership.curatedLibraries,
    )..sort((a, b) {
        final active = widget.activeLibraryId;
        if (active != null) {
          if (a.id == active) return -1;
          if (b.id == active) return 1;
        }
        return a.name.compareTo(b.name);
      });
    return list;
  }

  bool get _hasDiff {
    for (final lib in widget.membership.curatedLibraries) {
      if ((_checked[lib.id] ?? false) != (_initialChecked[lib.id] ?? false)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _apply() async {
    if (_applying || !_hasDiff) return;
    setState(() => _applying = true);
    try {
      final result = await widget.membership.applyCheckboxDiff(
        workIds: _effectiveIds,
        desiredChecked: _checked,
        initialChecked: _initialChecked,
      );
      if (!mounted) return;
      widget.onApplied?.call(result);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  String? _librarySubtitle(PersonalLibraryConfig lib) {
    final ids = _effectiveIds;
    if (ids.length <= 1) return '${lib.memberOrder.length}작';
    final contained = widget.membership.countContainedWorkIds(lib, ids);
    if (contained == 0) return '${lib.memberOrder.length}작';
    if (contained < ids.length) {
      return '$contained/${ids.length} 매체 · ${lib.memberOrder.length}작';
    }
    return '${lib.memberOrder.length}작';
  }

  @override
  Widget build(BuildContext context) {
    final libraries = _sortedLibraries;
    final activeId = widget.activeLibraryId;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onCancel?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text(
                    widget.displayTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.hasLibrarySection) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      '나만의 서재',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.showIpScopeOption) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text(
                              widget.singleWorkIds.length == 1
                                  ? '이 매체만'
                                  : '선택 매체',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text(
                              'IP 전체 (${widget.entireIpWorkIds.length})',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                        selected: {_useEntireIp},
                        onSelectionChanged: (selected) {
                          setState(() {
                            _useEntireIp = selected.first;
                            _syncCheckedFromMembership();
                          });
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      children: [
                        for (final lib in libraries)
                          CheckboxListTile(
                            value: _checked[lib.id] ?? false,
                            onChanged: _applying
                                ? null
                                : (v) => setState(
                                      () => _checked[lib.id] = v ?? false,
                                    ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lib.name,
                                    style: TextStyle(
                                      fontWeight: lib.id == activeId
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (lib.id == activeId)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amberAccent
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '현재 서재',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              _librarySubtitle(lib) ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                      ],
                    ),
                  ),
                  if (widget.onCreateLibrary != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _applying
                            ? null
                            : () async {
                                final created = await widget.onCreateLibrary!();
                                if (created == null || !mounted) return;
                                setState(() {
                                  _checked[created.id] = true;
                                  _initialChecked[created.id] = false;
                                });
                              },
                        icon: const Icon(Icons.add_box_outlined, size: 16),
                        label: const Text(
                          '새 서재 만들기…',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ] else if (widget.onCreateLibrary != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'curated 서재가 없습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                if (widget.hasHideSection) ...[
                  const Divider(height: 1),
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      '표시 안 함',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    initiallyExpanded: _hideExpanded,
                    onExpansionChanged: (v) =>
                        setState(() => _hideExpanded = v),
                    children: [
                      if (widget.onHideFranchise != null)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.layers_clear_outlined,
                              size: 18),
                          title: const Text(
                            'IP 전체 숨기기',
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            widget.onCancel?.call();
                            widget.onHideFranchise!();
                          },
                        ),
                      if (widget.onHideFromRegistry != null)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.visibility_off_outlined,
                              size: 18),
                          title: Text(
                            widget.onHideFranchise != null
                                ? '대표 매체만 숨기기'
                                : '이 매체 숨기기',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            widget.onCancel?.call();
                            widget.onHideFromRegistry!();
                          },
                        ),
                    ],
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _applying ? null : () => widget.onCancel?.call(),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      if (widget.hasLibrarySection)
                        FilledButton(
                          onPressed: _applying || !_hasDiff ? null : _apply,
                          child: _applying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('적용'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
