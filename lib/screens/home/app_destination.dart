import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/l10n/app_localizations.dart';

enum AppDestination { home, explore, library, collections, graph, timeline }

/// Product role for each global destination.
///
/// Navigation surfaces, destination context copy, and browse composition read
/// this metadata instead of inferring meaning from individual widgets.
enum AppDestinationPurpose {
  dashboard,
  discovery,
  archive,
  curation,
  relationships,
  chronology,
}

/// Immutable navigation metadata shared by every global navigation surface.
@immutable
class AppDestinationDefinition {
  const AppDestinationDefinition({
    required this.destination,
    required this.purpose,
    required this.stableId,
    required this.l10nLabelKey,
    required this.fallbackLabel,
    required this.icon,
    required this.available,
    required this.shortcut,
  });

  final AppDestination destination;
  final AppDestinationPurpose purpose;
  final String stableId;
  final String l10nLabelKey;
  final String fallbackLabel;
  final IconData icon;
  final bool available;
  final SingleActivator shortcut;

  String resolveLabel(AppLocalizations? l10n) {
    if (l10n == null) return fallbackLabel;
    return switch (destination) {
      AppDestination.home => l10n.sidebarHome,
      AppDestination.explore => l10n.sidebarExplore,
      AppDestination.library => l10n.sidebarLibrary,
      AppDestination.collections => l10n.sidebarCollections,
      AppDestination.graph => l10n.sidebarGraph,
      AppDestination.timeline => l10n.sidebarTimeline,
    };
  }

  String? resolvePurposeDescription(AppLocalizations? l10n) {
    return switch (purpose) {
      AppDestinationPurpose.discovery =>
        l10n?.destinationExploreDescription ?? '사전과 아카이브에서 다음 기록 대상을 찾습니다.',
      AppDestinationPurpose.archive =>
        l10n?.destinationLibraryDescription ?? '볼트에 보관한 기록과 나만의 서재를 살펴봅니다.',
      AppDestinationPurpose.curation =>
        l10n?.destinationCollectionsDescription ?? '작품과 엔티티를 의도적으로 묶은 컬렉션입니다.',
      _ => null,
    };
  }

  bool get showsBrowseContextHeader => switch (purpose) {
    AppDestinationPurpose.discovery ||
    AppDestinationPurpose.archive ||
    AppDestinationPurpose.curation => true,
    _ => false,
  };

  AppDestinationBinding bind({
    required AppDestination currentDestination,
    required ValueChanged<AppDestination> onSelected,
  }) {
    return AppDestinationBinding(
      definition: this,
      isSelected: destination == currentDestination,
      action: available ? () => onSelected(destination) : null,
    );
  }
}

/// Presentation-ready selection and action state for one destination.
@immutable
class AppDestinationBinding {
  const AppDestinationBinding({
    required this.definition,
    required this.isSelected,
    required this.action,
  });

  final AppDestinationDefinition definition;
  final bool isSelected;
  final VoidCallback? action;

  AppDestination get destination => definition.destination;
}

/// Single ordered source of truth for Sidebar, Dock, and keyboard shortcuts.
abstract final class AppDestinationRegistry {
  static const List<AppDestinationDefinition> ordered = [
    AppDestinationDefinition(
      destination: AppDestination.home,
      purpose: AppDestinationPurpose.dashboard,
      stableId: 'home',
      l10nLabelKey: 'sidebarHome',
      fallbackLabel: 'Home',
      icon: Icons.home_outlined,
      available: true,
      shortcut: SingleActivator(LogicalKeyboardKey.digit1, alt: true),
    ),
    AppDestinationDefinition(
      destination: AppDestination.explore,
      purpose: AppDestinationPurpose.discovery,
      stableId: 'explore',
      l10nLabelKey: 'sidebarExplore',
      fallbackLabel: 'Explore',
      icon: Icons.explore_outlined,
      available: true,
      shortcut: SingleActivator(LogicalKeyboardKey.digit2, alt: true),
    ),
    AppDestinationDefinition(
      destination: AppDestination.library,
      purpose: AppDestinationPurpose.archive,
      stableId: 'library',
      l10nLabelKey: 'sidebarLibrary',
      fallbackLabel: 'Library',
      icon: Icons.menu_book_outlined,
      available: true,
      shortcut: SingleActivator(LogicalKeyboardKey.digit3, alt: true),
    ),
    AppDestinationDefinition(
      destination: AppDestination.collections,
      purpose: AppDestinationPurpose.curation,
      stableId: 'collections',
      l10nLabelKey: 'sidebarCollections',
      fallbackLabel: 'Collections',
      icon: Icons.collections_bookmark_outlined,
      available: true,
      shortcut: SingleActivator(LogicalKeyboardKey.digit4, alt: true),
    ),

    // Restores access to the existing Canvas/connections surface. This does
    // not claim or introduce a new graph engine or visualization feature.
    AppDestinationDefinition(
      destination: AppDestination.graph,
      purpose: AppDestinationPurpose.relationships,
      stableId: 'graph',
      l10nLabelKey: 'sidebarGraph',
      fallbackLabel: 'Graph',
      icon: Icons.hub_outlined,
      available: true,
      shortcut: SingleActivator(LogicalKeyboardKey.digit5, alt: true),
    ),

    // Restores access to the existing Records/Timeline surface. This does not
    // add a new timeline data model or capability.
    AppDestinationDefinition(
      destination: AppDestination.timeline,
      purpose: AppDestinationPurpose.chronology,
      stableId: 'timeline',
      l10nLabelKey: 'sidebarTimeline',
      fallbackLabel: 'Timeline',
      icon: Icons.access_time_outlined,
      available: true,
      shortcut: SingleActivator(LogicalKeyboardKey.digit6, alt: true),
    ),
  ];

  static AppDestinationDefinition definitionFor(AppDestination destination) {
    return ordered.firstWhere((entry) => entry.destination == destination);
  }

  static List<AppDestinationBinding> bindings({
    required AppDestination currentDestination,
    required ValueChanged<AppDestination> onSelected,
  }) {
    return [
      for (final definition in ordered)
        definition.bind(
          currentDestination: currentDestination,
          onSelected: onSelected,
        ),
    ];
  }

  static Map<ShortcutActivator, VoidCallback> shortcutBindings({
    required ValueChanged<AppDestination> onSelected,
    bool Function()? enabled,
  }) {
    return {
      for (final definition in ordered)
        if (definition.available)
          definition.shortcut: () {
            if (enabled?.call() ?? true) {
              onSelected(definition.destination);
            }
          },
    };
  }
}
