import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_store.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'entity_detail_save_ops.dart';
import 'entity_detail_save_ui_patch.dart';

/// EntityDetailWorkspace 저장 오케스트레이션 결과.
sealed class EntityDetailSaveOrchestrationResult {
  const EntityDetailSaveOrchestrationResult();
}

class EntityDetailSaveOrchestrationSkipped extends EntityDetailSaveOrchestrationResult {
  const EntityDetailSaveOrchestrationSkipped();
}

class EntityDetailSaveOrchestrationBlocked extends EntityDetailSaveOrchestrationResult {
  const EntityDetailSaveOrchestrationBlocked(this.message);

  final String message;
}

class EntityDetailSaveOrchestrationFailed extends EntityDetailSaveOrchestrationResult {
  const EntityDetailSaveOrchestrationFailed(this.error);

  final Object error;
}

class EntityDetailSaveOrchestrationSucceeded extends EntityDetailSaveOrchestrationResult {
  const EntityDetailSaveOrchestrationSucceeded({
    required this.patch,
    required this.body,
    required this.usedPlaceholder,
  });

  final EntityDetailSaveUiPatch patch;
  final String body;
  final bool usedPlaceholder;
}

/// EntityDetailWorkspace — 검증·persist·UI 패치 생성.
abstract final class EntityDetailSaveOrchestrator {
  static Future<EntityDetailSaveOrchestrationResult> run({
    required bool suppressPersist,
    required bool isSaving,
    required String rawBody,
    required String posterPath,
    required List<String> tags,
    required bool silent,
    required SanctumPageView pageView,
    required void Function() syncBodyFromEditor,
    required UserCatalogEntity entity,
    required EntityJournalEntry? journal,
    required UserCatalogPort? catalog,
    required EntityVaultStore vaultStore,
    required SanctumPageView currentPageView,
    required Future<void> Function() beforePersist,
  }) async {
    if (EntityDetailSaveOps.shouldSkip(
      suppressPersist: suppressPersist,
      isSaving: isSaving,
    )) {
      return const EntityDetailSaveOrchestrationSkipped();
    }

    final prepare = EntityDetailSavePrepareOps.prepare(
      rawBody: rawBody,
      posterPath: posterPath,
      tags: tags,
      silent: silent,
      pageView: pageView,
      syncBodyFromEditor: syncBodyFromEditor,
    );

    switch (prepare) {
      case EntityDetailSaveBlocked(:final message):
        return EntityDetailSaveOrchestrationBlocked(message);
      case EntityDetailSaveReady(:final body, :final usedPlaceholder):
        await beforePersist();
        final result = await EntityDetailSaveOps.run(
          entity: entity,
          journal: journal,
          tags: tags,
          posterPath: posterPath,
          body: body,
          usedPlaceholder: usedPlaceholder,
          catalog: catalog,
          vaultStore: vaultStore,
        );
        return switch (result) {
          EntityDetailSaveSkipped() =>
            const EntityDetailSaveOrchestrationSkipped(),
          EntityDetailSaveFailed(:final error) =>
            EntityDetailSaveOrchestrationFailed(error),
          EntityDetailSaveSucceeded result =>
            EntityDetailSaveOrchestrationSucceeded(
              patch: EntityDetailSaveUiPatch.fromSucceeded(
                result: result,
                currentPageView: currentPageView,
                silent: silent,
              ),
              body: body,
              usedPlaceholder: usedPlaceholder,
            ),
        };
    }
  }
}
