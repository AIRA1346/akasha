import 'package:flutter/material.dart';

import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';
import '../app_destination.dart';
import '../shell_layout_spec.dart';
import 'preview_panel_layout.dart';

/// Immutable data exposed to the persistent Home inspector.
///
/// New inspector modules consume this snapshot rather than depending on the
/// Home shell controller or adding another callback to [HomeShellBody].
@immutable
class HomeInspectorSnapshot {
  const HomeInspectorSnapshot({
    required this.destination,
    required this.vaultLinked,
    required this.archiveCount,
    required this.collectionCount,
    required this.recentCount,
  });

  final AppDestination destination;
  final bool vaultLinked;
  final int archiveCount;
  final int collectionCount;
  final int recentCount;
}

/// A self-contained contribution to the default inspector surface.
///
/// Feature-specific sections can be added to the registry without changing
/// the shell geometry or the work/entity preview implementations.
abstract interface class HomeInspectorModule {
  String get id;
  int get priority;

  bool supports(HomeInspectorSnapshot snapshot);
  Widget build(BuildContext context, HomeInspectorSnapshot snapshot);
}

abstract final class HomeInspectorModuleRegistry {
  static const List<HomeInspectorModule> builtIn = [
    _DestinationInspectorModule(),
    _ArchiveSummaryInspectorModule(),
    _VaultStatusInspectorModule(),
  ];
}

/// Keeps default and contextual inspector contents mounted while switching
/// which one is visible. Utility surfaces can therefore reveal the default
/// context without resetting an open preview's local state.
class HomeInspectorRail extends StatelessWidget {
  const HomeInspectorRail({
    super.key,
    required this.defaultPanel,
    required this.showContextual,
    this.contextualPanel,
  });

  final Widget defaultPanel;
  final Widget? contextualPanel;
  final bool showContextual;

  @override
  Widget build(BuildContext context) {
    final contextualVisible = showContextual && contextualPanel != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: contextualVisible,
          child: TickerMode(enabled: !contextualVisible, child: defaultPanel),
        ),
        if (contextualPanel case final panel?)
          Offstage(
            offstage: !contextualVisible,
            child: TickerMode(enabled: contextualVisible, child: panel),
          ),
      ],
    );
  }
}

/// Default content for the right-hand inspector when nothing is selected.
class HomeInspectorPanel extends StatelessWidget {
  const HomeInspectorPanel({
    super.key,
    required this.width,
    required this.presentation,
    required this.snapshot,
    this.modules = HomeInspectorModuleRegistry.builtIn,
  });

  static const panelKey = ValueKey<String>('home-default-inspector');

  final double width;
  final ShellPreviewPresentation presentation;
  final HomeInspectorSnapshot snapshot;
  final List<HomeInspectorModule> modules;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final visibleModules =
        modules
            .where((module) => module.supports(snapshot))
            .toList(growable: false)
          ..sort((a, b) => a.priority.compareTo(b.priority));

    return PreviewPanelSurface(
      width: width,
      presentation: presentation,
      child: Semantics(
        container: true,
        label: l10n?.inspectorTitle ?? 'Context inspector',
        child: Column(
          key: panelKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AkashaSpacing.previewPanelHeader,
              child: Row(
                children: [
                  Icon(
                    Icons.view_sidebar_outlined,
                    size: 18,
                    color: palette.accent,
                  ),
                  const SizedBox(width: AkashaSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n?.inspectorTitle ?? 'Context inspector',
                      style: AkashaTypography.dashboardPanelTitle.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.borderSubtle(0.36)),
            Expanded(
              child: ListView.separated(
                padding: PreviewPanelLayoutSpec.railContentPadding,
                itemCount: visibleModules.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AkashaSpacing.md),
                itemBuilder: (context, index) =>
                    visibleModules[index].build(context, snapshot),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationInspectorModule implements HomeInspectorModule {
  const _DestinationInspectorModule();

  @override
  String get id => 'destination-context';

  @override
  int get priority => 10;

  @override
  bool supports(HomeInspectorSnapshot snapshot) => true;

  @override
  Widget build(BuildContext context, HomeInspectorSnapshot snapshot) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final definition = AppDestinationRegistry.definitionFor(
      snapshot.destination,
    );

    return _InspectorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(definition.icon, size: 18, color: palette.accent),
              const SizedBox(width: AkashaSpacing.sm),
              Expanded(
                child: Text(
                  definition.resolveLabel(l10n),
                  style: AkashaTypography.buttonLabel.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AkashaSpacing.sm),
          Text(
            definition.resolvePurposeDescription(l10n) ??
                (l10n?.inspectorHomeDescription ??
                    'Review the current archive context and recent activity.'),
            style: AkashaTypography.bodySecondary.copyWith(
              color: palette.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveSummaryInspectorModule implements HomeInspectorModule {
  const _ArchiveSummaryInspectorModule();

  @override
  String get id => 'archive-summary';

  @override
  int get priority => 20;

  @override
  bool supports(HomeInspectorSnapshot snapshot) => true;

  @override
  Widget build(BuildContext context, HomeInspectorSnapshot snapshot) {
    final l10n = lookupAppL10n(context);
    return _InspectorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n?.inspectorArchiveSummary ?? 'Archive summary',
            style: AkashaTypography.sectionLabel.copyWith(
              color: context.akashaPalette.textMuted,
            ),
          ),
          const SizedBox(height: AkashaSpacing.md),
          _InspectorMetric(
            icon: Icons.inventory_2_outlined,
            label: l10n?.inspectorRecords ?? 'Records',
            value: snapshot.archiveCount,
          ),
          const SizedBox(height: AkashaSpacing.sm),
          _InspectorMetric(
            icon: Icons.collections_bookmark_outlined,
            label: l10n?.sidebarCollections ?? 'Collections',
            value: snapshot.collectionCount,
          ),
          const SizedBox(height: AkashaSpacing.sm),
          _InspectorMetric(
            icon: Icons.history_rounded,
            label: l10n?.inspectorRecent ?? 'Recent',
            value: snapshot.recentCount,
          ),
        ],
      ),
    );
  }
}

class _VaultStatusInspectorModule implements HomeInspectorModule {
  const _VaultStatusInspectorModule();

  @override
  String get id => 'vault-status';

  @override
  int get priority => 30;

  @override
  bool supports(HomeInspectorSnapshot snapshot) => true;

  @override
  Widget build(BuildContext context, HomeInspectorSnapshot snapshot) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final linked = snapshot.vaultLinked;
    return _InspectorCard(
      child: Row(
        children: [
          Icon(
            linked ? Icons.cloud_done_outlined : Icons.folder_off_outlined,
            size: 18,
            color: linked ? palette.success : palette.warning,
          ),
          const SizedBox(width: AkashaSpacing.sm),
          Expanded(
            child: Text(
              linked
                  ? (l10n?.inspectorVaultConnected ?? 'Local vault connected')
                  : (l10n?.inspectorVaultDisconnected ??
                        'Connect a local vault to start archiving'),
              style: AkashaTypography.bodySecondary.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorCard extends StatelessWidget {
  const _InspectorCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: AkashaRadius.lgBorder,
        border: Border.all(color: palette.borderSubtle(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AkashaSpacing.md),
        child: child,
      ),
    );
  }
}

class _InspectorMetric extends StatelessWidget {
  const _InspectorMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Row(
      children: [
        Icon(icon, size: 16, color: palette.textMuted),
        const SizedBox(width: AkashaSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AkashaTypography.bodySecondary.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
        Text(
          '$value',
          style: AkashaTypography.bodyEmphasis.copyWith(color: palette.accent),
        ),
      ],
    );
  }
}
