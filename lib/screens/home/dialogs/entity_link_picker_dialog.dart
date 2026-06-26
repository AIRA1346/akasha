import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/catalog_entity_add_result.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_archive_service.dart';
import '../../../services/entity_link_picker_candidates.dart';
import '../../../services/entity_seed_catalog_promotion.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../services/entity_vault_path_conflict.dart';
import '../../../services/file_service.dart';
import '../../../services/link_candidate_service.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/entity_tag_validation.dart';
import '../../../widgets/fusion_search_dialog_tiles.dart';
import 'add_catalog_entity_dialog.dart';
import 'entity_link_picker_dialog_widgets.dart';

part 'entity_link_picker_dialog_actions.dart';

/// R2-B — Work Sanctum Entity link picker (선택만 · markdown 삽입은 Step 2).
Future<EntityLinkSelection?> showEntityLinkPickerDialog(
  BuildContext context, {
  required UserCatalogPort userCatalog,
  EntityVaultLoader? entityLoader,
  String? initialQuery,
  EntityAnchorType? anchorTypeFilter,
  AkashaItem? workContext,
  List<AkashaItem> vaultItems = const [],
}) {
  return showDialog<EntityLinkSelection>(
    context: context,
    builder: (ctx) => EntityLinkPickerDialog(
      userCatalog: userCatalog,
      entityLoader: entityLoader,
      initialQuery: initialQuery,
      anchorTypeFilter: anchorTypeFilter,
      workContext: workContext,
      vaultItems: vaultItems,
    ),
  );
}

class EntityLinkPickerDialog extends StatefulWidget {
  const EntityLinkPickerDialog({
    super.key,
    required this.userCatalog,
    this.entityLoader,
    this.initialQuery,
    this.anchorTypeFilter,
    this.workContext,
    this.vaultItems = const [],
  });

  final UserCatalogPort userCatalog;
  final EntityVaultLoader? entityLoader;
  final String? initialQuery;
  final EntityAnchorType? anchorTypeFilter;
  final AkashaItem? workContext;
  final List<AkashaItem> vaultItems;

  @override
  State<EntityLinkPickerDialog> createState() => _EntityLinkPickerDialogState();
}

abstract class _EntityLinkPickerDialogStateBase extends State<EntityLinkPickerDialog> {
  late final TextEditingController _queryCtrl;
  List<EntityLinkPickerCandidate> _candidates = const [];
  List<LinkCandidate> _recommendations = const [];
  var _loading = true;
  var _tab = 0;
  var _creating = false;
}

class _EntityLinkPickerDialogState extends _EntityLinkPickerDialogStateBase
    with _EntityLinkPickerDialogActions {
  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialQuery ?? '');
    _queryCtrl.addListener(_onQueryChanged);
    _reload();
  }

  @override
  void dispose() {
    _queryCtrl.removeListener(_onQueryChanged);
    _queryCtrl.dispose();
    super.dispose();
  }

  bool get _canCreateNew =>
      widget.anchorTypeFilter != null &&
      widget.anchorTypeFilter != EntityAnchorType.work;

  @override
  Widget build(BuildContext context) {
    final hasRecommendations = _recommendations.isNotEmpty;
    final hasCandidates = _candidates.isNotEmpty;
    final showEmpty = !hasRecommendations && !hasCandidates;

    return AlertDialog(
      title: Text(_dialogTitle()),
      content: SizedBox(
        width: 420,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_canCreateNew) ...[
              Row(
                children: [
                  EntityLinkPickerTab(
                    label: '기존 연결',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 8),
                  EntityLinkPickerTab(
                    label: '새로 만들기',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (_tab == 0 || !_canCreateNew) ...[
              TextField(
                controller: _queryCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '이름 · 별칭 검색',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitleText(),
                style: TextStyle(fontSize: 11, color: AkashaColors.textMuted),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : showEmpty
                        ? Center(
                            child: Text(
                              _queryCtrl.text.trim().isEmpty
                                  ? '연결할 Entity가 없습니다.'
                                  : '「${_queryCtrl.text.trim()}」과(와) 일치하는 항목이 없습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AkashaColors.textMuted,
                              ),
                            ),
                          )
                        : ListView(
                            children: [
                              if (hasRecommendations) ...[
                                const EntityLinkPickerSectionLabel('이 작품과 관련'),
                                ..._recommendations.map(
                                  (item) => EntityLinkRecommendationTile(
                                    candidate: item,
                                    onTap: () => _selectRecommendation(item),
                                  ),
                                ),
                                if (hasCandidates) ...[
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  const EntityLinkPickerSectionLabel('검색 결과'),
                                ],
                              ],
                              ..._candidates.map(
                                (item) => EntityLinkCandidateTile(
                                  candidate: item,
                                  onTap: () => _select(item),
                                ),
                              ),
                            ],
                          ),
              ),
            ] else
              Expanded(child: _buildCreateTab()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }

  Widget _buildCreateTab() {
    final type = widget.anchorTypeFilter!;
    final typeLabel = entityTypeBadgeLabel(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '카탈로그에 없는 $typeLabel을(를) 새로 등록하고, 이 작품 본문에 바로 연결합니다.',
          style: TextStyle(fontSize: 12, color: AkashaColors.textSecondary),
        ),
        const SizedBox(height: 16),
        if (_queryCtrl.text.trim().isNotEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              FusionSearchEntityIcons.forType(type),
              size: 20,
              color: AkashaColors.accent,
            ),
            title: Text(
              _queryCtrl.text.trim(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '검색어를 이름으로 사용',
              style: TextStyle(fontSize: 10, color: AkashaColors.textMuted),
            ),
          ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _creating ? null : _createNewEntity,
          icon: _creating
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add, size: 16),
          label: Text('$typeLabel 새로 만들기'),
        ),
      ],
    );
  }

  String _dialogTitle() {
    return switch (widget.anchorTypeFilter) {
      EntityAnchorType.person => '인물 추가',
      EntityAnchorType.event => '사건 추가',
      EntityAnchorType.concept => '개념 추가',
      EntityAnchorType.place => '장소 추가',
      EntityAnchorType.organization => '조직 추가',
      _ => 'Entity 연결',
    };
  }

  String _subtitleText() {
    if (_recommendations.isNotEmpty) {
      return '추천 후보 · Person · Event · Concept · Place · Org';
    }
    if (_candidates.any((c) => c.isSeed)) {
      return '내 카탈로그에 없습니다 · 사전 인물에서 연결할 수 있습니다';
    }
    return '카탈로그 · Person · Event · Concept · Place · Org';
  }
}
