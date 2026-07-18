import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/build_identity.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_spacing.dart';
import '../theme/akasha_typography.dart';

class BuildIdentityDockLabel extends StatelessWidget {
  const BuildIdentityDockLabel({
    super.key,
    required this.identity,
    this.condensed = false,
  });

  final BuildIdentity identity;
  final bool condensed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.akashaPalette;
    final label = condensed
        ? identity.versionLabel
        : identity.summaryLabel(
            localLabel: l10n.buildIdentityLocal,
            steamCheckingLabel: l10n.buildIdentitySteamChecking,
          );
    if (label.isEmpty) return const SizedBox.shrink();

    return Tooltip(
      message: l10n.buildIdentityCopy,
      child: Semantics(
        key: const ValueKey('build-identity-dock-label'),
        button: true,
        liveRegion: identity.steamState == SteamBuildIdentityState.checking,
        label: '${l10n.buildIdentityCopy}: $label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => unawaited(_copyBuildIdentity(context, identity)),
            child: Container(
              height: double.infinity,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: palette.borderSubtle(0.44)),
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: palette.textMuted,
                  fontFamily: 'Consolas',
                  fontSize: condensed ? 10 : 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BuildIdentityInfoSection extends StatelessWidget {
  const BuildIdentityInfoSection({super.key, required this.identity});

  final BuildIdentity identity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unavailable = l10n.buildIdentityUnavailable;
    final steamValue = switch (identity.steamState) {
      SteamBuildIdentityState.available =>
        identity.steamBuildId?.toString() ?? unavailable,
      SteamBuildIdentityState.local => l10n.buildIdentityLocal,
      SteamBuildIdentityState.checking => l10n.buildIdentitySteamChecking,
      SteamBuildIdentityState.unavailable => unavailable,
    };

    return Column(
      key: const ValueKey('build-identity-app-info'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.buildIdentityAppInfoTitle,
                style: AkashaTypography.settingsLabel,
              ),
            ),
            IconButton(
              key: const ValueKey('build-identity-copy-button'),
              onPressed: () => unawaited(_copyBuildIdentity(context, identity)),
              tooltip: l10n.buildIdentityCopy,
              icon: const Icon(Icons.copy_outlined, size: 18),
            ),
          ],
        ),
        const SizedBox(height: AkashaSpacing.xs),
        _BuildIdentityRow(
          label: l10n.buildIdentityVersion,
          value: identity.version.trim().isEmpty
              ? unavailable
              : identity.version.trim(),
        ),
        _BuildIdentityRow(
          label: l10n.buildIdentityBuildNumber,
          value: identity.buildNumber.trim().isEmpty
              ? unavailable
              : identity.buildNumber.trim(),
        ),
        _BuildIdentityRow(
          label: l10n.buildIdentitySteamBuildId,
          value: steamValue,
        ),
        _BuildIdentityRow(
          label: l10n.buildIdentityGitCommit,
          value: identity.gitCommitShort ?? unavailable,
        ),
        _BuildIdentityRow(
          label: l10n.buildIdentityBuildMode,
          value: identity.buildMode == 'unknown'
              ? unavailable
              : identity.buildMode,
        ),
        _BuildIdentityRow(
          label: l10n.buildIdentityExecutionEnvironment,
          value: identity.executionEnvironment == 'unknown'
              ? unavailable
              : identity.executionEnvironment,
        ),
      ],
    );
  }
}

class _BuildIdentityRow extends StatelessWidget {
  const _BuildIdentityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AkashaTypography.caption.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AkashaSpacing.md),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: TextStyle(
                color: palette.textMuted,
                fontFamily: 'Consolas',
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _copyBuildIdentity(
  BuildContext context,
  BuildIdentity identity,
) async {
  final l10n = AppLocalizations.of(context);
  await Clipboard.setData(
    ClipboardData(
      text: identity.copyText(
        localLabel: l10n.buildIdentityLocal,
        unavailableLabel: l10n.buildIdentityUnavailable,
        checkingLabel: l10n.buildIdentitySteamChecking,
      ),
    ),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.buildIdentityCopied)));
}
