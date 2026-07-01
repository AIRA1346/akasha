import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/app_lifecycle.dart';
import '../../../services/user_preferences.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';

Future<void> showAppPreferencesDialog(
  BuildContext context, {
  VoidCallback? onOpenAppTheme,
  VoidCallback? onOpenVaultSettings,
  VoidCallback? onQuit,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var localScale = UserPreferences.uiScaleListenable.value;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          final percent = (localScale * 100).round();

          Future<void> persistScale(double value) async {
            final scale = UserPreferences.normalizeUiScale(value);
            await UserPreferences.setUiScale(scale);
            if (!context.mounted) return;
            setDialogState(() => localScale = scale);
          }

          void closeThen(VoidCallback? action) {
            Navigator.of(dialogContext).pop();
            if (action == null) return;
            WidgetsBinding.instance.addPostFrameCallback((_) => action());
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.tune, size: 20, color: AkashaColors.accent),
                SizedBox(width: AkashaSpacing.sm),
                Text('환경설정'),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '표시 배율',
                          style: AkashaTypography.settingsLabel,
                        ),
                      ),
                      Text('$percent%', style: AkashaTypography.bodyEmphasis),
                    ],
                  ),
                  Slider(
                    value: localScale,
                    min: UserPreferences.minUiScale,
                    max: UserPreferences.maxUiScale,
                    divisions: 7,
                    label: '$percent%',
                    onChanged: (value) {
                      setDialogState(() => localScale = value);
                    },
                    onChangeEnd: persistScale,
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            persistScale(UserPreferences.defaultUiScale),
                        child: const Text('100%로 재설정'),
                      ),
                      const SizedBox(width: AkashaSpacing.sm),
                      const Expanded(
                        child: Text(
                          '앱 전체 글자와 주요 컨트롤 크기를 조정합니다.',
                          style: AkashaTypography.caption,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('앱 테마'),
                    subtitle: const Text('색상 팔레트를 바꿉니다.'),
                    onTap: onOpenAppTheme == null
                        ? null
                        : () => closeThen(onOpenAppTheme),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder_open_outlined),
                    title: const Text('볼트 설정'),
                    subtitle: const Text('저장 폴더, 백업, 휴지통을 관리합니다.'),
                    onTap: onOpenVaultSettings == null
                        ? null
                        : () => closeThen(onOpenVaultSettings),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (onQuit != null) {
                    onQuit();
                  } else {
                    unawaited(quitAkashaApp());
                  }
                },
                icon: const Icon(Icons.power_settings_new),
                label: const Text('종료'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('닫기'),
              ),
            ],
          );
        },
      );
    },
  );
}
