import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_archive_service.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/file_service.dart';

const kEntityJournalPlaceholderBody = '(기록 대기중)';

class EntityBodyResolveResult {
  const EntityBodyResolveResult({
    required this.body,
    this.usedPlaceholder = false,
  });

  /// `null`이면 저장을 중단합니다 (본문·메타 모두 비어 있음).
  final String? body;
  final bool usedPlaceholder;
}

class EntityDetailSaveOutcome {
  const EntityDetailSaveOutcome({
    required this.mirrored,
    required this.saved,
  });

  final UserCatalogEntity mirrored;
  final EntityJournalEntry saved;
}

/// EntityDetailWorkspace 저장·아카이브 상태 (WorkDetailArchiveOps 대칭).
abstract final class EntityDetailArchiveOps {
  static bool hasJournal(EntityJournalEntry? journal) => journal != null;

  static bool isVaultConnected() {
    final vaultPath = AkashaFileService().vaultPath;
    return vaultPath != null && vaultPath.isNotEmpty;
  }

  static EntityBodyResolveResult resolveBodyForSave({
    required String rawBody,
    required String posterPath,
    required List<String> tags,
  }) {
    var body = rawBody.trim();
    if (body.isNotEmpty) {
      return EntityBodyResolveResult(body: body);
    }
    final hasMetaChanges =
        posterPath.trim().isNotEmpty || tags.isNotEmpty;
    if (!hasMetaChanges) {
      return const EntityBodyResolveResult(body: null);
    }
    return const EntityBodyResolveResult(
      body: kEntityJournalPlaceholderBody,
      usedPlaceholder: true,
    );
  }

  static Future<EntityDetailSaveOutcome> persist({
    required String vaultPath,
    required UserCatalogEntity entityDraft,
    required EntityJournalEntry? existingJournal,
    required String body,
    required List<String> tags,
    required String posterPath,
    UserCatalogPort? userCatalog,
    EntityVaultStore? vaultStore,
  }) async {
    final store = vaultStore ?? EntityVaultStore();
    final EntityJournalEntry saved;
    if (existingJournal == null) {
      saved = await store.saveCatalogEntity(
        vaultPath: vaultPath,
        entity: entityDraft,
        body: body,
      );
    } else {
      saved = await store.updateEntry(
        entry: existingJournal,
        body: body,
        tags: tags,
        posterPath: posterPath,
      );
    }

    var mirrored = entityDraft;
    if (userCatalog != null) {
      mirrored = await EntityArchiveService.syncCatalogFromJournal(
        draft: entityDraft,
        entry: saved,
        userCatalog: userCatalog,
      );
    }

    return EntityDetailSaveOutcome(mirrored: mirrored, saved: saved);
  }

  static Future<bool> deleteFromVault({
    required EntityJournalEntry entry,
    required UserCatalogPort userCatalog,
    EntityVaultStore? vaultStore,
  }) =>
      EntityArchiveService.deleteArchivedEntity(
        entry: entry,
        userCatalog: userCatalog,
        vaultStore: vaultStore,
      );

  static String saveSuccessMessage(UserCatalogEntity entity) =>
      '"${entity.title}" entity journal을 저장했습니다.';

  static String? vaultRequiredSnack({required bool silent}) =>
      silent ? null : '볼트를 먼저 연결해 주세요.';

  static String? emptyBodySnack({required bool silent}) =>
      silent ? null : '본문을 입력해 주세요.';
}
