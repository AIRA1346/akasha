import 'package:flutter/material.dart';

import '../models/library_theme.dart';
import '../services/library_theme_preferences.dart';
import '../theme/akasha_colors.dart';

/// 앱 테마 선택 바텀시트.
Future<LibraryTheme?> showLibraryThemePicker(
  BuildContext context, {
  required LibraryTheme current,
}) async {
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
                '앱 테마',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '현재 제공되는 앱 테마는 모두 무료입니다.',
                style: TextStyle(fontSize: 12, color: AkashaColors.textMuted),
              ),
              const SizedBox(height: 12),
              ...LibraryTheme.all.map((theme) {
                final selected = current.id == theme.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.backgroundColor,
                    child: Icon(
                      Icons.palette_outlined,
                      color: theme.accentColor,
                      size: 18,
                    ),
                  ),
                  title: Text(theme.name),
                  trailing: selected
                      ? Icon(Icons.check, color: theme.accentColor)
                      : null,
                  onTap: () async {
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
