import 'package:flutter/material.dart';

import '../../widgets/dashboard_sidebar.dart';
import '../../services/file_service.dart';

/// 홈 화면 AppBar (검색·동기화·볼트·AI 도구)
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSidebarOpen;
  final bool isSyncing;
  final VoidCallback onToggleSidebar;
  final VoidCallback onSearch;
  final VoidCallback onClipboardImport;
  final VoidCallback? onTimelineCapture;
  final VoidCallback onSync;
  final VoidCallback onSyncSettings;
  final VoidCallback onPromptTemplates;
  final VoidCallback onVaultSettings;
  final VoidCallback onClearRegistryCache;
  final VoidCallback? onCatalogInbox;
  final int catalogContributionCount;
  final bool showLibraryThemeButton;
  final VoidCallback? onLibraryTheme;
  final Color? libraryThemeAccent;

  const HomeAppBar({
    super.key,
    required this.isSidebarOpen,
    required this.isSyncing,
    required this.onToggleSidebar,
    required this.onSearch,
    required this.onClipboardImport,
    this.onTimelineCapture,
    required this.onSync,
    required this.onSyncSettings,
    required this.onPromptTemplates,
    required this.onVaultSettings,
    required this.onClearRegistryCache,
    this.onCatalogInbox,
    this.catalogContributionCount = 0,
    this.showLibraryThemeButton = false,
    this.onLibraryTheme,
    this.libraryThemeAccent,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final vaultLinked = AkashaFileService().vaultPath != null;

    return AppBar(
      leading: IconButton(
        icon: Icon(isSidebarOpen ? Icons.menu_open : Icons.menu),
        tooltip: '사이드바 토글 (Tab)',
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
        if (showLibraryThemeButton && onLibraryTheme != null)
          IconButton(
            icon: Icon(
              Icons.palette_outlined,
              color: libraryThemeAccent ?? DashboardSidebar.personalAccent,
            ),
            tooltip: '서재 테마',
            onPressed: onLibraryTheme,
          ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '검색',
          onPressed: onSearch,
        ),
        if (vaultLinked && onTimelineCapture != null)
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            tooltip: '타임라인 기록',
            onPressed: onTimelineCapture,
          ),
        if (onCatalogInbox != null)
          IconButton(
            tooltip: '카탈로그 제안함',
            onPressed: onCatalogInbox,
            icon: Badge(
              isLabelVisible: catalogContributionCount > 0,
              label: Text('$catalogContributionCount'),
              child: const Icon(Icons.inbox_outlined),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.smart_toy_outlined),
          tooltip: 'AI 마크다운 가져오기',
          onPressed: onClipboardImport,
        ),
        if (isSyncing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: '글로벌 작품 사전 동기화 (길게 눌러 설정)',
            onPressed: onSync,
            onLongPress: onSyncSettings,
          ),
        IconButton(
          icon: const Icon(Icons.copy_all),
          tooltip: 'AI 프롬프트 템플릿 복사',
          onPressed: onPromptTemplates,
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: '글로벌 사전 JSON 캐시 삭제 (이미지 파일 아님)',
          onPressed: onClearRegistryCache,
        ),
        IconButton(
          icon: Icon(
            vaultLinked ? Icons.folder : Icons.folder_open_outlined,
            color: vaultLinked ? Colors.tealAccent : null,
          ),
          tooltip: '로컬 폴더(Vault) 설정',
          onPressed: onVaultSettings,
        ),
      ],
    );
  }
}
