import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_journal_parser.dart';
import '../../../widgets/sanctum_page_panel.dart';

/// EntityDetailWorkspace 컨트롤러·상태 동기화 스냅샷.
class EntityDetailWorkspaceSnapshot {
  const EntityDetailWorkspaceSnapshot({
    required this.entity,
    required this.journal,
    required this.item,
    required this.preview,
    required this.draftTags,
    required this.bodyText,
    required this.posterText,
    required this.fileText,
    required this.pageView,
  });

  final UserCatalogEntity entity;
  final EntityJournalEntry? journal;
  final EntityItem item;
  final EntityItem preview;
  final List<String> draftTags;
  final String bodyText;
  final String posterText;
  final String fileText;
  final SanctumPageView pageView;

  static EntityDetailWorkspaceSnapshot fromProps({
    required UserCatalogEntity entity,
    required EntityJournalEntry? journal,
  }) {
    final draftTags = List<String>.from(journal?.tags ?? entity.tags);
    final bodyText = journal?.body ?? '';
    final posterText = journal?.posterPath ?? entity.posterPath ?? '';
    final item = EntityDetailDraftOps.buildEntityItem(entity, journal);
    return EntityDetailWorkspaceSnapshot(
      entity: entity,
      journal: journal,
      item: item,
      preview: item,
      draftTags: draftTags,
      bodyText: bodyText,
      posterText: posterText,
      fileText: EntityDetailDraftOps.serializeFile(
        entity: entity,
        journal: journal,
        body: bodyText,
        tags: draftTags,
        posterPath: posterText,
      ),
      pageView: EntityDetailDraftOps.initialPageView(bodyText),
    );
  }

  static EntityDetailWorkspaceSnapshot fromJournalEntry({
    required UserCatalogEntity entity,
    required EntityJournalEntry entry,
    required SanctumPageView pageView,
  }) {
    final mirrored = entity.copyWith(
      title: entry.title,
      aliases: entry.aliases.isNotEmpty ? entry.aliases : entity.aliases,
      tags: entry.tags,
      posterPath: entry.posterPath,
    );
    final tags = List<String>.from(entry.tags);
    final posterText = entry.posterPath ?? '';
    final item = EntityDetailDraftOps.buildEntityItem(mirrored, entry);
    return EntityDetailWorkspaceSnapshot(
      entity: mirrored,
      journal: entry,
      item: item,
      preview: item,
      draftTags: tags,
      bodyText: entry.body,
      posterText: posterText,
      fileText: EntityDetailDraftOps.serializeFile(
        entity: mirrored,
        journal: entry,
        body: entry.body,
        tags: tags,
        posterPath: posterText,
      ),
      pageView: pageView,
    );
  }
}

/// EntityDetailWorkspace draft·journal 파일 편집.
abstract final class EntityDetailDraftOps {
  static SanctumPageView initialPageView(String bodyText) =>
      bodyText.trim().isEmpty ? SanctumPageView.body : SanctumPageView.preview;

  static EntityItem buildEntityItem(
    UserCatalogEntity entity,
    EntityJournalEntry? journal,
  ) {
    return EntityItem(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      category: entity.subtype,
      domain: entity.domain,
      creator: entity.creator,
      releaseYear: entity.releaseYear,
      posterPath: journal?.posterPath ?? entity.posterPath,
      tags: List<String>.from(journal?.tags ?? entity.tags),
      addedAt: journal?.addedAt ?? entity.addedAt,
      bodyRaw: journal?.body ?? '',
    );
  }

  static EntityItem buildPreviewItem({
    required UserCatalogEntity entity,
    required EntityJournalEntry? journal,
    required String posterPath,
    required List<String> tags,
    required String bodyRaw,
  }) {
    return EntityItem(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      category: entity.subtype,
      domain: entity.domain,
      creator: entity.creator,
      releaseYear: entity.releaseYear,
      posterPath: posterPath,
      tags: tags,
      addedAt: journal?.addedAt ?? entity.addedAt,
      bodyRaw: bodyRaw,
    );
  }

  static String serializeFile({
    required UserCatalogEntity entity,
    required EntityJournalEntry? journal,
    required String body,
    required List<String> tags,
    required String posterPath,
  }) {
    if (journal == null) {
      return EntityJournalParser.serialize(
        entityType: entity.anchorType,
        entityId: entity.entityId,
        title: entity.title,
        body: body,
        addedAt: entity.addedAt,
        aliases: entity.aliases,
        tags: tags,
        posterPath: posterPath,
      );
    }
    return EntityJournalParser.serialize(
      entityType: journal.entityType,
      entityId: journal.entityId,
      title: journal.title,
      body: body,
      addedAt: journal.addedAt,
      aliases: journal.aliases.isNotEmpty ? journal.aliases : entity.aliases,
      tags: tags,
      posterPath: posterPath,
    );
  }

  static List<String>? syncBodyFromFileEditor({
    required String fileText,
    required TextEditingController bodyCtrl,
  }) {
    final parsed = EntityJournalParser.parse(fileText, '');
    if (parsed == null) return null;
    bodyCtrl.text = parsed.body;
    return List<String>.from(parsed.tags);
  }

  static void handlePageViewChanging({
    required SanctumPageView current,
    required SanctumPageView next,
    required TextEditingController fileCtrl,
    required TextEditingController bodyCtrl,
    required void Function() refreshFileEditor,
    required void Function() syncBodyFromFile,
  }) {
    if (current == SanctumPageView.file && next != SanctumPageView.file) {
      syncBodyFromFile();
    }
    if (next == SanctumPageView.file) {
      refreshFileEditor();
    }
  }
}
