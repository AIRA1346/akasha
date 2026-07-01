import 'dart:async';

import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/ports/entity_registry_port.dart';
import '../core/ports/registry_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/enums.dart';
import '../models/registry_work.dart';
import '../services/fusion_search_sections.dart';
import '../services/fusion_search_service.dart';
import '../services/registry_visibility_service.dart';
import '../services/user_registry_preferences.dart';
import '../theme/akasha_colors.dart';
import 'fusion_remote_search_entry.dart';
import 'fusion_search_dialog_tiles.dart';
import '../utils/app_l10n.dart';

part 'fusion_search_dialog_search.dart';

/// Fusion: 로컬 아카이브 · user local · 글로벌 사전 · 직접 추가 CTA.
class FusionSearchDialog extends StatefulWidget {
  final List<AkashaItem> localItems;
  final UserCatalogPort userCatalog;
  final RegistryPort registry;
  final EntityRegistryPort? entityRegistry;
  final void Function(AkashaItem item) onSelectLocal;
  final Future<void> Function(RegistryWork work) onSelectRemote;
  final void Function(String query) onCustomAdd;
  final void Function(String query)? onCatalogPropose;
  final Future<void> Function(AkashaItem item)? onAddLocalToLibrary;
  final Future<void> Function(RegistryWork work)? onAddRemoteToLibrary;
  final Future<void> Function(RegistryWork work)? onPromoteCatalogEntity;

  const FusionSearchDialog({
    super.key,
    required this.localItems,
    required this.userCatalog,
    required this.registry,
    this.entityRegistry,
    required this.onSelectLocal,
    required this.onSelectRemote,
    required this.onCustomAdd,
    this.onCatalogPropose,
    this.onAddLocalToLibrary,
    this.onAddRemoteToLibrary,
    this.onPromoteCatalogEntity,
  });

  @override
  State<FusionSearchDialog> createState() => _FusionSearchDialogState();
}

abstract class _FusionSearchDialogStateBase extends State<FusionSearchDialog> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<AkashaItem> _localWorkResults = [];
  List<EntityJournalEntry> _localEntityResults = [];
  List<FusionRegistryHit> _catalogHits = [];
  List<FusionRegistryHit> _globalHits = [];
  bool _isSearching = false;
  String? _searchError;
}

class _FusionSearchDialogState extends _FusionSearchDialogStateBase
    with _FusionSearchDialogSearch {
  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final query = _ctrl.text.trim();
    final groups = FusionSearchSections.group(
      localWork: _localWorkResults,
      localEntity: _localEntityResults,
      catalogHits: _catalogHits,
      globalHits: _globalHits,
    );
    final showCustomCta =
        query.isNotEmpty && !_isSearching && !groups.hasAnyHits;

    return AlertDialog(
      title: Text(l10n?.searchTitle ?? '🔍 검색'),
      content: SizedBox(
        width: 440,
        height: 460,
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n?.hintSearchEverything ?? '제목, 작가, 태그, Entity…',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onQueryChanged,
            ),
            if (_searchError != null) ...[
              const SizedBox(height: 8),
              Text(
                _searchError!,
                style: TextStyle(fontSize: 11, color: Colors.orange[300]),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: query.isEmpty
                  ? Center(
                      child: Text(
                        l10n?.hintSearchExplain ??
                            '검색어를 입력하세요.\n로컬 아카이브 · 내 등록 · 글로벌 사전을 함께 검색합니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AkashaColors.textMuted,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        if (groups.localWork.isNotEmpty) ...[
                          FusionSearchSectionLabel(
                            l10n?.sectionMyArchiveWork ?? '📂 내 아카이브 — Work',
                            groups.localWork.length,
                          ),
                          ...groups.localWork.map(
                            (item) => FusionSearchLocalWorkTile(
                              item: item,
                              onSelect: () {
                                Navigator.pop(context);
                                widget.onSelectLocal(item);
                              },
                              onAddToLibrary: widget.onAddLocalToLibrary == null
                                  ? null
                                  : () => widget.onAddLocalToLibrary!(item),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (groups.localEntity.isNotEmpty) ...[
                          FusionSearchSectionLabel(
                            l10n?.sectionMyArchiveEntity ??
                                '📂 내 아카이브 — Entity',
                            groups.localEntity.length,
                          ),
                          ...groups.localEntity.map(
                            (entry) => FusionSearchLocalEntityTile(
                              entry: entry,
                              onSelect: () {
                                Navigator.pop(context);
                                widget.onSelectRemote(
                                  registryWorkFromEntityEntry(entry),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (groups.catalogWork.isNotEmpty) ...[
                          FusionSearchSectionLabel(
                            l10n?.sectionMyArchiveWorkRegisteredOnly ??
                                '📂 내 아카이브 — Work (등록만)',
                            groups.catalogWork.length,
                          ),
                          ...groups.catalogWork.map(
                            (hit) => FusionSearchRemoteTile(
                              entry: entryFromHit(hit),
                              onSelectRemote: widget.onSelectRemote,
                              onAddRemoteToLibrary: widget.onAddRemoteToLibrary,
                              onPromoteCatalogEntity:
                                  widget.onPromoteCatalogEntity,
                              onRemoteTap: _handleRemoteTap,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (groups.catalogEntityOnly.isNotEmpty) ...[
                          FusionSearchSectionLabel(
                            l10n?.sectionNotArchived ?? '⏳ 아카이브되지 않음',
                            groups.catalogEntityOnly.length,
                          ),
                          ...groups.catalogEntityOnly.map(
                            (hit) => FusionSearchRemoteTile(
                              entry: entryFromHit(hit),
                              onSelectRemote: widget.onSelectRemote,
                              onAddRemoteToLibrary: widget.onAddRemoteToLibrary,
                              onPromoteCatalogEntity:
                                  widget.onPromoteCatalogEntity,
                              onRemoteTap: _handleRemoteTap,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (groups.globalWork.isNotEmpty) ...[
                          FusionSearchSectionLabel(
                            l10n?.sectionGlobalRegistryWork ??
                                '🌐 글로벌 사전 — Work',
                            groups.globalWork.length,
                          ),
                          ...groups.globalWork.map(
                            (hit) => FusionSearchRemoteTile(
                              entry: entryFromHit(hit),
                              onSelectRemote: widget.onSelectRemote,
                              onAddRemoteToLibrary: widget.onAddRemoteToLibrary,
                              onPromoteCatalogEntity:
                                  widget.onPromoteCatalogEntity,
                              onRemoteTap: _handleRemoteTap,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (groups.globalEntity.isNotEmpty) ...[
                          FusionSearchSectionLabel(
                            l10n?.sectionGlobalRegistryEntity ??
                                '🌐 글로벌 — Entity',
                            groups.globalEntity.length,
                          ),
                          ...groups.globalEntity.map(
                            (hit) => FusionSearchRemoteTile(
                              entry: entryFromHit(hit),
                              onSelectRemote: widget.onSelectRemote,
                              onAddRemoteToLibrary: widget.onAddRemoteToLibrary,
                              onPromoteCatalogEntity:
                                  widget.onPromoteCatalogEntity,
                              onRemoteTap: _handleRemoteTap,
                            ),
                          ),
                        ],
                        if (showCustomCta) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onCustomAdd(query);
                                  },
                                  icon: const Icon(Icons.person_add_outlined),
                                  label: Text(
                                    l10n?.actionAddCustomWithType ??
                                        '직접 추가 (유형 선택)',
                                  ),
                                ),
                                if (widget.onCatalogPropose != null) ...[
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      widget.onCatalogPropose!(query);
                                    },
                                    icon: const Icon(
                                      Icons.library_add_outlined,
                                    ),
                                    label: Text(
                                      l10n?.actionProposeToGlobalRegistry ??
                                          '글로벌 사전에 추가 제안',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (!_isSearching &&
                            query.isNotEmpty &&
                            !groups.hasAnyHits &&
                            _searchError == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text(
                                l10n?.noSearchResults ?? '검색 결과가 없습니다.',
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.actionClose ?? '닫기'),
        ),
      ],
    );
  }
}
