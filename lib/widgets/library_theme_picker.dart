import 'package:flutter/material.dart';

import '../models/library_theme.dart';
import '../services/entitlement_service.dart';
import '../services/library_theme_preferences.dart';

/// 나만의 서재 테마 선택 바텀시트 + IAP 안내.
Future<LibraryTheme?> showLibraryThemePicker(
  BuildContext context, {
  required LibraryTheme current,
}) async {
  await EntitlementService.instance.load();
  final entitlements = EntitlementService.instance;

  return showModalBottomSheet<LibraryTheme>(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '서재 테마',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '기본 테마는 무료 · 프리미엄 테마는 Steam IAP',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
              ...LibraryTheme.all.map((theme) {
                final locked = !entitlements.canUseTheme(theme);
                final selected = current.id == theme.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.backgroundColor,
                    child: Icon(
                      locked ? Icons.lock_outline : Icons.palette_outlined,
                      color: theme.accentColor,
                      size: 18,
                    ),
                  ),
                  title: Text(theme.name),
                  trailing: selected
                      ? Icon(Icons.check, color: theme.accentColor)
                      : null,
                  onTap: () async {
                    if (locked) {
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        await _promptIapPurchase(context, theme);
                      }
                      return;
                    }
                    await LibraryThemePreferences.save(theme);
                    if (ctx.mounted) Navigator.pop(ctx, theme);
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _promptIapPurchase(BuildContext context, LibraryTheme theme) async {
  final bought = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('프리미엄 서재 테마'),
      content: Text(
        '「${theme.name}」 테마는 서재 꾸미기 팩(IAP)에 포함됩니다.\n'
        'Steam에서 인앱 구매로 해제됩니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Steam에서 구매'),
        ),
      ],
    ),
  );

  if (bought != true || !context.mounted) return;

  final success = await EntitlementService.instance
      .purchaseCosmetic(EntitlementService.libraryThemePackId);
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? '구매가 완료되었습니다.'
            : 'Steam IAP 연동 전입니다. 출시 빌드에서 활성화됩니다.',
      ),
    ),
  );
}
