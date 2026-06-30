part of 'home_dialogs_coordinator.dart';

Future<void> _homeDialogsCoordinatorOpenCatalogContributionsInbox(
  HomeDialogsCoordinator coord,
) async {
  await HomeDialogsFacade.showCatalogContributionsInbox(coord.hostContext());
  await coord.catalog.syncCatalogContributionCount();
}

Future<void> _homeDialogsCoordinatorOpenTimelineQuickCapture(
  HomeDialogsCoordinator coord,
) async {
  final saved = await HomeDialogsFacade.showTimelineQuickCapture(
    context: coord.hostContext(),
    localItems: coord.getItems(),
    isVaultLinked: coord.vault.isVaultLinked,
    showMessage: coord.showMessage,
  );
  if (saved && coord.isMounted()) coord.navigation.onTimelineQuickCaptureSaved();
}

Future<void> _homeDialogsCoordinatorOpenJournalQuickCapture(
  HomeDialogsCoordinator coord,
) async {
  final saved = await HomeDialogsFacade.showJournalQuickCapture(
    context: coord.hostContext(),
    isVaultLinked: coord.vault.isVaultLinked,
    showMessage: coord.showMessage,
  );
  if (saved && coord.isMounted()) coord.navigation.onJournalQuickCaptureSaved();
}
