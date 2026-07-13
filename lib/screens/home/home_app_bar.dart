import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../utils/app_l10n.dart';

enum _HomeAppBarMenuAction {
  sync,
  syncSettings,
  clipboardImport,
  promptTemplates,
  clearRegistryCache,
  timelineCapture,
}

/// 홈 화면 AppBar — 볼트·제안함은 노출, 나머지 도구는 overflow 메뉴.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.isSidebarOpen,
    required this.isSyncing,
    required this.vaultLinked,
    required this.onToggleSidebar,
    required this.onClipboardImport,
    this.onTimelineCapture,
    required this.onSync,
    required this.onSyncSettings,
    required this.onPromptTemplates,
    required this.onVaultSettings,
    required this.onClearRegistryCache,
    this.onCatalogInbox,
    this.catalogContributionCount = 0,
    required this.onSettings,
    this.currencySlot,
    this.avatarSlot,
    this.toolbarHeight = 64,
  });

  final bool isSidebarOpen;
  final bool isSyncing;
  final bool vaultLinked;
  final VoidCallback onToggleSidebar;
  final VoidCallback onClipboardImport;
  final VoidCallback? onTimelineCapture;
  final VoidCallback onSync;
  final VoidCallback onSyncSettings;
  final VoidCallback onPromptTemplates;
  final VoidCallback onVaultSettings;
  final VoidCallback onClearRegistryCache;
  final VoidCallback? onCatalogInbox;
  final int catalogContributionCount;
  final VoidCallback onSettings;
  final Widget? currencySlot;
  final Widget? avatarSlot;
  final double toolbarHeight;

  bool get _showTimelineCapture =>
      FeatureFlags.showTimeline && vaultLinked && onTimelineCapture != null;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  void _onMenuSelected(_HomeAppBarMenuAction action) {
    switch (action) {
      case _HomeAppBarMenuAction.sync:
        if (!isSyncing) onSync();
      case _HomeAppBarMenuAction.syncSettings:
        onSyncSettings();
      case _HomeAppBarMenuAction.clipboardImport:
        onClipboardImport();
      case _HomeAppBarMenuAction.promptTemplates:
        onPromptTemplates();
      case _HomeAppBarMenuAction.clearRegistryCache:
        onClearRegistryCache();
      case _HomeAppBarMenuAction.timelineCapture:
        onTimelineCapture?.call();
    }
  }

  List<PopupMenuEntry<_HomeAppBarMenuAction>> _buildOverflowMenuItems(
    BuildContext context,
  ) {
    final l10n = lookupAppL10n(context);
    return [
      PopupMenuItem(
        value: _HomeAppBarMenuAction.sync,
        enabled: !isSyncing,
        child: _OverflowMenuRow(
          icon: Icons.sync,
          label: l10n?.appBarSyncRegistry ?? '글로벌 작품 사전 동기화',
          trailing: isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
      ),
      PopupMenuItem(
        value: _HomeAppBarMenuAction.syncSettings,
        child: _OverflowMenuRow(
          icon: Icons.settings_ethernet,
          label: l10n?.appBarSyncUrlSettings ?? '사전 동기화 URL 설정',
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: _HomeAppBarMenuAction.clipboardImport,
        child: _OverflowMenuRow(
          icon: Icons.smart_toy_outlined,
          label: l10n?.appBarClipboardImport ?? 'AI 마크다운 가져오기',
        ),
      ),
      PopupMenuItem(
        value: _HomeAppBarMenuAction.promptTemplates,
        child: _OverflowMenuRow(
          icon: Icons.copy_all,
          label: l10n?.appBarPromptTemplates ?? 'AI 프롬프트 템플릿 복사',
        ),
      ),
      if (_showTimelineCapture) ...[
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _HomeAppBarMenuAction.timelineCapture,
          child: _OverflowMenuRow(
            icon: Icons.edit_note_outlined,
            label: l10n?.appBarTimelineCapture ?? '타임라인 기록',
          ),
        ),
      ],
      const PopupMenuDivider(),
      PopupMenuItem(
        value: _HomeAppBarMenuAction.clearRegistryCache,
        child: _OverflowMenuRow(
          icon: Icons.delete_sweep_outlined,
          label:
              l10n?.appBarClearRegistryCache ?? '글로벌 사전 JSON 캐시 삭제 (이미지 파일 아님)',
          destructive: true,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return AppBar(
      key: const ValueKey('home-shell-app-bar'),
      toolbarHeight: toolbarHeight,
      leading: IconButton(
        icon: Icon(isSidebarOpen ? Icons.menu_open : Icons.menu),
        tooltip: l10n?.appBarToggleSidebar ?? '사이드바 토글 (Ctrl+B)',
        onPressed: onToggleSidebar,
      ),
      title: const Text(
        'A K A S H A',
        style: TextStyle(
          fontWeight: FontWeight.w300,
          letterSpacing: 6,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        if (onCatalogInbox != null)
          IconButton(
            tooltip: l10n?.appBarCatalogInbox ?? '카탈로그 제안함',
            onPressed: onCatalogInbox,
            icon: Badge(
              isLabelVisible: catalogContributionCount > 0,
              label: Text('$catalogContributionCount'),
              child: const Icon(Icons.inbox_outlined),
            ),
          ),
        if (isSyncing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        IconButton(
          icon: Icon(
            vaultLinked ? Icons.folder : Icons.folder_open_outlined,
            color: vaultLinked ? Colors.tealAccent : null,
          ),
          tooltip: l10n?.appBarVaultSettings ?? '로컬 폴더(Vault) 설정',
          onPressed: onVaultSettings,
        ),
        PopupMenuButton<_HomeAppBarMenuAction>(
          tooltip: l10n?.appBarMoreToolsTooltip ?? '도구 더보기',
          onSelected: _onMenuSelected,
          itemBuilder: (context) => _buildOverflowMenuItems(context),
          icon: const Icon(Icons.more_vert),
        ),
        HomeUtilityCluster(
          currencySlot: currencySlot,
          onSettings: onSettings,
          avatarSlot: avatarSlot,
        ),
      ],
    );
  }
}

/// Production utility slot contract. Missing providers stay absent rather than
/// rendering placeholder balances or identities.
class HomeUtilityCluster extends StatelessWidget {
  const HomeUtilityCluster({
    super.key,
    required this.onSettings,
    this.currencySlot,
    this.avatarSlot,
  });

  final Widget? currencySlot;
  final VoidCallback onSettings;
  final Widget? avatarSlot;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    return Row(
      key: const ValueKey('home-utility-cluster'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ?currencySlot,
        IconButton(
          key: const ValueKey('home-utility-settings'),
          tooltip: l10n?.appPreferencesTitle ?? 'Settings',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
        ?avatarSlot,
      ],
    );
  }
}

class _OverflowMenuRow extends StatelessWidget {
  const _OverflowMenuRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : null;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: color)),
        ),
        ?trailing,
      ],
    );
  }
}
