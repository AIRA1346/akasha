#!/usr/bin/env python3
"""Rebuild lib/screens/home/home_shell.dart from git HEAD home_screen + Wave 1.1~1.3."""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "lib" / "screens" / "home" / "home_shell.dart"


def load_head_home_screen() -> str:
    raw = subprocess.check_output(
        ["git", "show", "HEAD:lib/screens/home_screen.dart"], cwd=ROOT
    )
    return raw.decode("utf-8")


def replace(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"MISSING block: {label}")
    return text.replace(old, new, 1)


def main() -> None:
    text = load_head_home_screen()

    # ── Wave 1.3: class rename + import path fix (screens/ → screens/home/) ──
    text = text.replace("class HomeScreen extends StatefulWidget", "class HomeShell extends StatefulWidget")
    text = text.replace("const HomeScreen({super.key});", "const HomeShell({super.key});")
    text = text.replace("State<HomeScreen>", "State<HomeShell>")
    text = text.replace("class _HomeScreenState extends State<HomeShell>", "class _HomeShellState extends State<HomeShell>")
    text = text.replace("class _HomeScreenState extends State<HomeScreen>", "class _HomeShellState extends State<HomeShell>")
    text = text.replace("_HomeScreenState", "_HomeShellState")

    text = re.sub(
        r"//  메인 홈 대시보드.*\n// ═+\n",
        "// Home shell — Scaffold · sidebar · workbench 조립 (Wave 1.3)\n",
        text,
        count=1,
    )

    text = text.replace("import '../", "import '../../")
    text = text.replace("import 'home/", "import '")
    text = text.replace("import 'workbench/", "import '../workbench/")

    # Wave 1.2 import cleanup
    text = replace(
        text,
        """import '../../widgets/browse_dashboard_sections.dart';
import '../../widgets/dashboard_sidebar.dart';
import '../../utils/browse_year_groups.dart';
import '../../widgets/fusion_search_dialog.dart';
import '../../widgets/browse_poster_grid.dart';
import 'home_registry_sync.dart';""",
        """import '../../widgets/dashboard_sidebar.dart';
import 'home_registry_sync.dart';
import 'coordinators/home_membership_coordinator.dart';""",
        "imports batch 1",
    )

    text = replace(
        text,
        """import 'dialogs/registry_sync_dialog.dart';
import 'dialogs/vault_settings_dialog.dart';
import 'dialogs/dashboard_edit_dialog.dart';
import 'dialogs/add_work_dialog.dart';
import 'dialogs/catalog_add_contribution_dialog.dart';
import 'dialogs/catalog_contributions_inbox_dialog.dart';
import 'dialogs/clipboard_import_dialog.dart';
import 'dialogs/prompt_templates_dialog.dart';
import '../../services/catalog_contribution_service.dart';
import '../../config/feature_flags.dart';
import '../../widgets/today_recall_card.dart';
import '../../utils/recall_picker.dart';
import 'home_personal_library_controller.dart';
import 'dialogs/personal_library_edit_dialog.dart';""",
        """import 'dialogs/home_dialogs_facade.dart';
import 'views/browse_view.dart';
import 'views/personal_library_view.dart';
import 'dialogs/dashboard_edit_dialog.dart';
import '../../config/feature_flags.dart';
import '../../widgets/today_recall_card.dart';
import '../../utils/recall_picker.dart';
import 'home_personal_library_controller.dart';
import 'dialogs/personal_library_edit_dialog.dart';""",
        "imports batch 2",
    )

    text = replace(
        text,
        """import '../../utils/helpers.dart';
import '../../utils/browse_section_filters.dart';
import '../../utils/browse_category_groups.dart';
import '../../widgets/filter_section.dart';""",
        """import '../../utils/helpers.dart';
import '../../widgets/filter_section.dart';""",
        "imports batch 3",
    )

    text = replace(
        text,
        """import '../../widgets/work_draggable_card.dart';
import '../../widgets/curated_reorder_grid.dart';
import '../../services/user_preferences.dart';""",
        """import '../../widgets/work_draggable_card.dart';
import '../../services/user_preferences.dart';""",
        "imports batch 4",
    )

    # ── Wave 1.1: coordinator field + init ──
    text = replace(
        text,
        """  late final PersonalLibraryMembershipService _libraryMembership =
      PersonalLibraryMembershipService(_personalLibCtrl, WorksRegistryAdapter());
  HomeSectionPreferences _sectionPrefs = HomeSectionPreferences();""",
        """  late final PersonalLibraryMembershipService _libraryMembership =
      PersonalLibraryMembershipService(_personalLibCtrl, WorksRegistryAdapter());
  late final HomeMembershipCoordinator _membershipCoordinator;
  HomeSectionPreferences _sectionPrefs = HomeSectionPreferences();""",
        "coordinator field",
    )

    text = replace(
        text,
        """    );
    _initVault();
    if (FeatureFlags.catalogContributions) {
      _refreshCatalogContributionCount();
    }
    _workbench.addListener(_onWorkbenchChanged);""",
        """    );
    _membershipCoordinator = HomeMembershipCoordinator(
      personalLibraryController: _personalLibCtrl,
      membership: _libraryMembership,
      resolveItemForOpen: _resolveItemForOpen,
      reloadItems: _loadItems,
    );
    _initVault();
    if (FeatureFlags.catalogContributions) {
      _syncCatalogContributionCount();
    }
    _workbench.addListener(_onWorkbenchChanged);""",
        "coordinator init",
    )

    # ── Wave 1.1 PR-2: _addWorkToLibrary → coordinator ──
    text = replace(
        text,
        """    var workItem = _resolveItemForOpen(item);
    if (!fileService.isArchivedInVault(workItem)) {
      try {
        await LibraryMembershipApply.ensureVaultMd(draft: workItem);
        await _loadItems();
        workItem = _resolveItemForOpen(item);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('기록 생성 실패: $e')),
          );
        }
        return;
      }
    }

    final workId = MarkdownParser.ensureWorkId(workItem);
    PersonalLibraryConfig? lib;
    for (final l in _personalLibCtrl.libraries) {
      if (l.id == libraryId) {
        lib = l;
        break;
      }
    }
    if (lib == null || !lib.isCurated) return;

    final already = _libraryMembership.containsWork(lib, workId);
    await _libraryMembership.addWork(libraryId, workId);
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          already ? '이미 「${lib.name}」에 담긴 작품입니다.' : '「${lib.name}」에 담았습니다.',
        ),
        action: switchToLibrary
            ? SnackBarAction(
                label: '보기',
                onPressed: () => _selectPersonalLibrary(libraryId),
              )
            : null,
      ),
    );""",
        """    final outcome = await _membershipCoordinator.addWorkToLibrary(
      libraryId: libraryId,
      item: item,
    );

    if (outcome.vaultMdError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기록 생성 실패: ${outcome.vaultMdError}')),
        );
      }
      return;
    }
    if (outcome.skipped || outcome.libraryName == null) return;
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.alreadyInLibrary
              ? '이미 「${outcome.libraryName}」에 담긴 작품입니다.'
              : '「${outcome.libraryName}」에 담았습니다.',
        ),
        action: switchToLibrary
            ? SnackBarAction(
                label: '보기',
                onPressed: () => _selectPersonalLibrary(libraryId),
              )
            : null,
      ),
    );""",
        "_addWorkToLibrary coordinator",
    )

    # ── Wave 1.1 PR-4: remove _applyWorkLibraryPanel, direct onApply ──
    text = replace(
        text,
        """          ? (input) => _applyWorkLibraryPanel(
                card,
                draft: workItem,
                input: input,
              )
          : null,""",
        """          ? (input) => _membershipCoordinator.applyWorkLibraryPanel(
                card,
                draft: workItem,
                input: input,
                vaultItems: _items,
              )
          : null,""",
        "onApply direct",
    )

    apply_panel_block = re.search(
        r"\n  Future<MembershipApplyResult> _applyWorkLibraryPanel\([\s\S]*?\n  \}\n\n  WorkLibraryMenuRequest _workLibraryMenuRequest\(",
        text,
    )
    if not apply_panel_block:
        raise SystemExit("MISSING _applyWorkLibraryPanel block")
    text = (
        text[: apply_panel_block.start()]
        + "\n  WorkLibraryMenuRequest _workLibraryMenuRequest("
        + text[apply_panel_block.end() :]
    )

    text = text.replace("import '../../services/library_membership_apply.dart';\n", "")

    # onAddWorks glue
    text = replace(
        text,
        """              await _showSearchDialog(context);
              await _loadItems();""",
        """              await _openSearchDialog();
              await _loadItems();""",
        "onAddWorks search",
    )

    # ── Wave 1.2: remove _buildEmptyMainContent, add dialog glue ──
    empty_block = re.search(
        r"\n  Widget _buildEmptyMainContent\(\) \{[\s\S]*?\n  \}\n\n",
        text,
    )
    if not empty_block:
        raise SystemExit("MISSING _buildEmptyMainContent block")

    dialog_glue = """
  Future<void> _syncCatalogContributionCount() async {
    await HomeDialogsFacade.refreshCatalogContributionCount(
      onCount: (count) {
        if (!mounted) return;
        setState(() => _catalogContributionCount = count);
      },
    );
  }

  Future<void> _openSearchDialog() async {
    await HomeDialogsFacade.showSearchDialog(
      context: context,
      localItems: _items,
      onSelectLocal: _openBrowseItem,
      onSelectRemote: _openRegistryWorkForArchive,
      onCustomAdd: (query) => _openAddDialog(initialTitle: query),
      onCatalogPropose: HomeDialogsFacade.catalogProposeCallback(
        context: context,
        refreshContributionCount: _syncCatalogContributionCount,
        showMessage: (msg) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      ),
      onAddLocalToLibrary:
          _canAddToLibrary ? _showAddToLibraryForItem : null,
      onAddRemoteToLibrary:
          _canAddToLibrary ? _addRegistryWorkToLibrary : null,
    );
  }

  Future<void> _openAddDialog({String? initialTitle}) async {
    await HomeDialogsFacade.showAddDialog(
      context: context,
      initialTitle: initialTitle,
      onSavedToVault: (item) async {
        await AkashaFileService().saveItem(item);
        await _loadItems();
      },
      onSavedInMemory: (item) => setState(() => _items.add(item)),
    );
  }

  Future<void> _openRegistryWorkForArchive(RegistryWork work) async {
    if (!mounted) return;
    _openBrowseItem(HomeAutoArchive.itemFromRegistryWork(work));
  }

"""

    text = text[: empty_block.start()] + dialog_glue + text[empty_block.end() :]

    # Fix duplicate build if any - remove old catalogCards block before CallbackShortcuts
    text = replace(
        text,
        """    final dailyRecall = FeatureFlags.showRecallCard && !_isPersonalLibraryMode
        ? RecallPicker.pickDailyRecall(_items)
        : null;

    final List<BrowseCard> catalogCards;
    final List<BrowseCard> hofCards;
    final List<BrowseCard> watchlistCards;
    final BrowseCategoryGroups? categoryGroups;

    if (_isPersonalLibraryMode) {
      final libraryFiltered = filterLibraryCards(filtered, _items);
      if (_isCuratedLibraryActive) {
        catalogCards = _sectionPrefs.librarySort.isManualOrder
            ? libraryFiltered
            : sortBrowseCards(libraryFiltered, _sectionPrefs.librarySort);
      } else {
        catalogCards = sortBrowseCards(libraryFiltered, _sectionPrefs.librarySort);
      }
      hofCards = sortBrowseCards(
        filtered.where((c) => c.item.isHallOfFame).toList(),
        _sectionPrefs.hofSort,
      );
      watchlistCards = sortBrowseCards(
        filterWatchlistCards(filtered, _items),
        _sectionPrefs.watchlistSort,
      );
      categoryGroups = null;
    } else {
      catalogCards = sortBrowseCards(filtered, _sectionPrefs.librarySort);
      hofCards = const [];
      watchlistCards = sortBrowseCards(
        filterWatchlistCards(filtered, _items),
        _sectionPrefs.watchlistSort,
      );
      categoryGroups = BrowseCategoryGroups.fromCards(
        catalogCards,
        _sectionPrefs.librarySort,
        restrictToCategories: _filterCtrl.categories,
      );
    }

    final yearGroups = BrowseYearGroups.fromLibraryCards(
      _isPersonalLibraryMode ? catalogCards : filtered,
      _sectionPrefs.yearlySort,
    );

    return CallbackShortcuts(""",
        """    final dailyRecall = FeatureFlags.showRecallCard && !_isPersonalLibraryMode
        ? RecallPicker.pickDailyRecall(_items)
        : null;

    return CallbackShortcuts(""",
        "remove catalogCards block",
    )

    text = replace(
        text,
        """            onSearch: () => _showSearchDialog(context),
            onClipboardImport: _showClipboardImportDialog,
            onSync: _syncRegistry,
            onSyncSettings: _showCustomUrlDialog,
            onPromptTemplates: () => showPromptTemplatesDialog(context),
            onVaultSettings: _showVaultInfoDialog,
            onClearRegistryCache: _clearRegistryCache,
            onCatalogInbox: FeatureFlags.catalogContributions
                ? _showCatalogContributionsInbox
                : null,""",
        """            onSearch: _openSearchDialog,
            onClipboardImport: _openClipboardImportDialog,
            onSync: _syncRegistry,
            onSyncSettings: _showCustomUrlDialog,
            onPromptTemplates: () => HomeDialogsFacade.showPromptTemplates(context),
            onVaultSettings: _openVaultSettingsDialog,
            onClearRegistryCache: _clearRegistryCache,
            onCatalogInbox: FeatureFlags.catalogContributions
                ? _openCatalogContributionsInbox
                : null,""",
        "app bar callbacks",
    )

    text = replace(
        text,
        """    await showRegistrySyncDialog(
      context,
      isSyncing: _isSyncing,
      lastSyncTime: _lastSyncTime,
      onSyncNow: _syncRegistry,
      onUrlSaved: _refreshLastSyncTime,
    );""",
        """    await HomeDialogsFacade.showRegistrySync(
      context: context,
      isSyncing: _isSyncing,
      lastSyncTime: _lastSyncTime,
      onSyncNow: _syncRegistry,
      onUrlSaved: _refreshLastSyncTime,
    );""",
        "registry sync facade",
    )

    browse_old = re.search(
        r"                    browseContent: !_isPersonalLibraryMode && _isCatalogLoading[\s\S]*?\n                              \),",
        text,
    )
    if not browse_old:
        raise SystemExit("MISSING browseContent block")

    browse_new = """                    browseContent: _isPersonalLibraryMode
                        ? PersonalLibraryView(
                            filteredCards: filtered,
                            allItems: _items,
                            sectionPrefs: _sectionPrefs,
                            displayName: _displayName,
                            isCuratedLibraryActive: _isCuratedLibraryActive,
                            activeLibrary: _personalLibCtrl.activeLibrary,
                            posterCardBuilder: _buildPosterCard,
                            onStateChanged: () => setState(() {}),
                            onCuratedReorder: (cards, oldIndex, newIndex) async {
                              await PersonalLibraryView.applyCuratedGridReorder(
                                membership: _libraryMembership,
                                personalLibCtrl: _personalLibCtrl,
                                visibleCards: cards,
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                              );
                              if (mounted) setState(() {});
                            },
                            onSearch: _openSearchDialog,
                          )
                        : BrowseView(
                            filteredCards: filtered,
                            allItems: _items,
                            sectionPrefs: _sectionPrefs,
                            filterCategories: _filterCtrl.categories,
                            isCatalogLoading: _isCatalogLoading,
                            displayName: _displayName,
                            posterCardBuilder: _buildPosterCard,
                            onStateChanged: () => setState(() {}),
                          ),"""

    text = text[: browse_old.start()] + browse_new + text[browse_old.end() :]

    # Remove _buildGrid through old dialog methods before _selectVaultFolder
    tail_remove = re.search(
        r"\n  // ── 포스터 카드 그리드 ──[\s\S]*?\n  // ── 로컬 볼트\(Vault\) 폴더 선택 ──\n  Future<void> _selectVaultFolder\(\) async \{",
        text,
    )
    if not tail_remove:
        raise SystemExit("MISSING tail dialog/grid block")

    tail_new = """
  Future<void> _openCatalogContributionsInbox() async {
    await HomeDialogsFacade.showCatalogContributionsInbox(context);
    await _syncCatalogContributionCount();
  }

  Future<void> _openVaultSettingsDialog() async {
    await HomeDialogsFacade.showVaultSettings(
      context: context,
      displayName: _displayName,
      autoArchiveRegistry: _autoArchiveRegistry,
      onDisplayNameSaved: (name) => setState(() => _displayName = name),
      onAutoArchiveChanged: (enabled) =>
          setState(() => _autoArchiveRegistry = enabled),
      runAutoArchive: _autoArchiveRegistryWorks,
      reloadItems: () async {
        await _loadPersonalLibraries();
        await _loadItems();
      },
      selectVaultFolder: _selectVaultFolder,
      onRegistryVisibilityChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _openClipboardImportDialog() async {
    await HomeDialogsFacade.showClipboardImport(
      context: context,
      existingItems: _items,
      onItemImportedToVault: (_) async => _loadItems(),
      onItemImportedInMemory: (item) => setState(() => _items.add(item)),
    );
  }

  // ── 로컬 볼트(Vault) 폴더 선택 ──
  Future<void> _selectVaultFolder() async {"""

    text = text[: tail_remove.start()] + tail_new + text[tail_remove.end() :]

    # Remove trailing _showVaultInfoDialog and _showClipboardImportDialog
    text = re.sub(
        r"\n  Future<void> _showVaultInfoDialog\(\) async \{[\s\S]*?\n  \}\n\n  Future<void> _showClipboardImportDialog\(\) async \{[\s\S]*?\n  \}\n\n\}",
        "\n}",
        text,
        count=1,
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8", newline="\n")
    print(f"Wrote {OUT} ({len(text.splitlines())} lines)")


if __name__ == "__main__":
    main()
