import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/archiving/record_kind.dart';
import 'record_summary_index_service.dart';

/// Rebuildable local query cache for one canonical Vault.
///
/// This store intentionally lives outside the Vault root. Its database is not
/// archive evidence, must never be used for canonical writes, and may be
/// deleted whenever a rebuild is required.
class LocalDerivedIndexStore {
  LocalDerivedIndexStore({DatabaseFactory? databaseFactory})
    : _databaseFactoryOverride = databaseFactory;

  static const int schemaVersion = 4;
  static const String cacheDirectoryName = 'derived_indexes';
  static const String databaseFileName = 'index.sqlite';

  final DatabaseFactory? _databaseFactoryOverride;

  /// Opens a cache database below [cacheRoot], never below [vaultPath].
  Future<Database> open({
    required String cacheRoot,
    required String vaultPath,
  }) async {
    final databaseFile = databaseFileFor(
      cacheRoot: cacheRoot,
      vaultPath: vaultPath,
    );
    await databaseFile.parent.create(recursive: true);

    sqfliteFfiInit();
    final database = await _databaseFactory.openDatabase(
      databaseFile.path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );
    await database.execute('PRAGMA foreign_keys = ON');
    await database.insert('cache_meta', {
      'key': 'vault_root',
      'value': normalizedVaultRoot(vaultPath),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return database;
  }

  File databaseFileFor({required String cacheRoot, required String vaultPath}) {
    final root = cacheRoot.trim();
    if (root.isEmpty) {
      throw ArgumentError.value(cacheRoot, 'cacheRoot', 'must not be empty');
    }
    return File(
      p.join(
        root,
        cacheDirectoryName,
        vaultCacheKey(vaultPath),
        databaseFileName,
      ),
    );
  }

  /// Deletes only derived data for this Vault. Canonical Vault files are never
  /// touched.
  Future<void> deleteCache({
    required String cacheRoot,
    required String vaultPath,
  }) async {
    final directory = databaseFileFor(
      cacheRoot: cacheRoot,
      vaultPath: vaultPath,
    ).parent;
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  /// Updates the derived Work projection without reading or rewriting the
  /// complete cache.
  Future<void> upsertWorkSummary({
    required Database database,
    required VaultRecordSummary summary,
    String? indexedGeneration,
  }) async {
    await database.transaction(
      (transaction) => _upsertWorkSummaryInTransaction(
        transaction,
        summary: summary,
        indexedGeneration: indexedGeneration,
      ),
    );
  }

  /// Applies a bounded rebuild batch in one cache transaction.
  ///
  /// Rebuild callers should use this instead of opening a transaction for each
  /// source file. Regular one-path changes continue to use [upsertWorkSummary]
  /// or [markSourceUnreadable].
  Future<void> applyWorkSourceBatch({
    required Database database,
    required Iterable<VaultRecordSummary> readable,
    required Map<String, String> unreadable,
    required String indexedGeneration,
  }) async {
    if (readable.isEmpty && unreadable.isEmpty) return;
    await database.transaction((transaction) async {
      for (final summary in readable) {
        await _upsertWorkSummaryInTransaction(
          transaction,
          summary: summary,
          indexedGeneration: indexedGeneration,
        );
      }
      for (final entry in unreadable.entries) {
        await _markSourceUnreadableInTransaction(
          transaction,
          relativePath: entry.key,
          errorCode: entry.value,
          indexedGeneration: indexedGeneration,
        );
      }
    });
  }

  Future<void> _upsertWorkSummaryInTransaction(
    DatabaseExecutor transaction, {
    required VaultRecordSummary summary,
    required String? indexedGeneration,
  }) async {
    if (summary.recordKind != RecordKind.workJournal) {
      throw ArgumentError.value(
        summary.recordKind,
        'summary.recordKind',
        'must be a workJournal summary',
      );
    }
    final workId = summary.id.trim();
    final sourcePath = _normalizedRelativePath(summary.relativePath);
    if (workId.isEmpty) {
      throw ArgumentError.value(summary.id, 'summary.id', 'must not be empty');
    }

    final previous = await transaction.query(
      'work_summaries',
      columns: const ['source_path'],
      where: 'work_id = ?',
      whereArgs: [workId],
      limit: 1,
    );
    final previousPath = previous.isEmpty
        ? null
        : previous.single['source_path']?.toString();
    if (previousPath != null && previousPath != sourcePath) {
      await transaction.delete(
        'source_files',
        where: 'relative_path = ?',
        whereArgs: [previousPath],
      );
    }
    await transaction.delete(
      'source_files',
      where: 'relative_path = ? AND entity_id != ?',
      whereArgs: [sourcePath, workId],
    );
    await transaction.insert('source_files', {
      'relative_path': sourcePath,
      'entity_id': workId,
      'record_kind': RecordKind.workJournal.name,
      'indexed_at_utc': DateTime.now().toUtc().toIso8601String(),
      'indexed_generation': indexedGeneration,
      'readability_state': 'readable',
      'read_error': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await transaction.insert('work_summaries', {
      'work_id': workId,
      'source_path': sourcePath,
      'title': summary.title,
      'category': _nullIfEmpty(summary.category),
      'creator': _nullIfEmpty(summary.creator),
      'release_year': summary.releaseYear,
      'rating': summary.rating,
      'work_status': _nullIfEmpty(summary.workStatus),
      'my_status': _nullIfEmpty(summary.myStatus),
      'poster_path': _nullIfEmpty(summary.posterPath),
      'added_at_utc': _asUtcIso(summary.addedAt),
      'updated_at_utc': _asUtcIso(summary.updatedAt),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await transaction.delete(
      'work_summary_tags',
      where: 'work_id = ?',
      whereArgs: [workId],
    );
    for (final tag in _normalizedTags(summary.tags)) {
      await transaction.insert('work_summary_tags', {
        'work_id': workId,
        'normalized_tag': tag,
      });
    }
  }

  /// Removes one source path and all of its derived Work data.
  Future<void> removeBySourcePath({
    required Database database,
    required String relativePath,
  }) {
    return database.delete(
      'source_files',
      where: 'relative_path = ?',
      whereArgs: [_normalizedRelativePath(relativePath)],
    );
  }

  /// Keeps a broken source visible to repair flows while removing any stale
  /// readable Work projection for the same path.
  Future<void> markSourceUnreadable({
    required Database database,
    required String relativePath,
    required String errorCode,
    String? indexedGeneration,
  }) async {
    await database.transaction((transaction) async {
      await _markSourceUnreadableInTransaction(
        transaction,
        relativePath: relativePath,
        errorCode: errorCode,
        indexedGeneration: indexedGeneration,
      );
    });
  }

  Future<void> _markSourceUnreadableInTransaction(
    DatabaseExecutor transaction, {
    required String relativePath,
    required String errorCode,
    required String? indexedGeneration,
  }) async {
    final sourcePath = _normalizedRelativePath(relativePath);
    await transaction.delete(
      'source_files',
      where: 'relative_path = ?',
      whereArgs: [sourcePath],
    );
    await transaction.insert('source_files', {
      'relative_path': sourcePath,
      'record_kind': RecordKind.workJournal.name,
      'indexed_at_utc': DateTime.now().toUtc().toIso8601String(),
      'indexed_generation': indexedGeneration,
      'readability_state': 'unreadable',
      'read_error': errorCode,
    });
  }

  /// Removes Work sources that a completed rebuild did not observe.
  Future<int> pruneWorkSourcesOutsideGeneration({
    required Database database,
    required String generation,
  }) {
    return database.delete(
      'source_files',
      where:
          "relative_path LIKE ? AND (indexed_generation IS NULL OR indexed_generation != ?)",
      whereArgs: ['works/%', generation],
    );
  }

  /// Reads at most [WorkSummaryQuery.limit] Work rows plus one cursor sentinel.
  ///
  /// This method queries only the local derived store. It never scans Markdown
  /// or loads the complete summary index.
  Future<WorkSummaryPage> queryWorkSummaries({
    required Database database,
    WorkSummaryQuery query = const WorkSummaryQuery(),
  }) async {
    final where = <String>[];
    final arguments = <Object?>[];
    _appendInFilter(
      where: where,
      arguments: arguments,
      column: 'category',
      values: query.categories,
    );
    _appendInFilter(
      where: where,
      arguments: arguments,
      column: 'work_status',
      values: query.workStatuses,
    );
    _appendInFilter(
      where: where,
      arguments: arguments,
      column: 'my_status',
      values: query.myStatuses,
    );
    final tag = _normalizeValue(query.tag)?.toLowerCase();
    if (tag != null) {
      where.add('''
        EXISTS (
          SELECT 1 FROM work_summary_tags
          WHERE work_summary_tags.work_id = work_summaries.work_id
            AND work_summary_tags.normalized_tag = ?
        )
      ''');
      arguments.add(tag);
    }

    final cursor = _decodeCursor(query.cursor);
    const sortKey = "COALESCE(updated_at_utc, added_at_utc, '')";
    if (cursor != null) {
      where.add('($sortKey < ? OR ($sortKey = ? AND work_id > ?))');
      arguments.addAll([cursor.sortKey, cursor.sortKey, cursor.workId]);
    }

    final rows = await database.rawQuery(
      '''
        SELECT work_id, source_path, title, category, creator, release_year,
               rating, work_status, my_status, poster_path, added_at_utc,
               updated_at_utc, $sortKey AS cursor_sort_key
        FROM work_summaries
        ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
        ORDER BY $sortKey DESC, work_id ASC
        LIMIT ?
      ''',
      [...arguments, query.limit + 1],
    );
    final pageRows = rows.take(query.limit).toList(growable: false);
    final tagsByWorkId = await _loadTags(database, pageRows);
    final summaries = pageRows
        .map((row) => _summaryFromRow(row, tagsByWorkId))
        .toList(growable: false);
    final hasMore = rows.length > query.limit;
    final nextCursor = hasMore && pageRows.isNotEmpty
        ? _encodeCursor(
            pageRows.last['cursor_sort_key']?.toString() ?? '',
            pageRows.last['work_id']!.toString(),
          )
        : null;
    return WorkSummaryPage(summaries: summaries, nextCursor: nextCursor);
  }

  static String normalizedVaultRoot(String vaultPath) {
    final trimmed = vaultPath.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(vaultPath, 'vaultPath', 'must not be empty');
    }
    final normalized = p.normalize(p.absolute(trimmed));
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  static String vaultCacheKey(String vaultPath) =>
      sha256.convert(utf8.encode(normalizedVaultRoot(vaultPath))).toString();

  DatabaseFactory get _databaseFactory =>
      _databaseFactoryOverride ?? databaseFactoryFfi;

  static Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE cache_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE source_files (
        relative_path TEXT PRIMARY KEY,
        record_id TEXT,
        entity_id TEXT,
        record_kind TEXT,
        content_hash TEXT,
        size_bytes INTEGER,
        modified_at_utc TEXT,
        indexed_at_utc TEXT,
        indexed_generation TEXT,
        readability_state TEXT NOT NULL,
        read_error TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE work_summaries (
        work_id TEXT PRIMARY KEY,
        source_path TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        category TEXT,
        creator TEXT,
        release_year INTEGER,
        rating REAL,
        work_status TEXT,
        my_status TEXT,
        poster_path TEXT,
        added_at_utc TEXT,
        updated_at_utc TEXT,
        FOREIGN KEY (source_path) REFERENCES source_files(relative_path)
          ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE work_summary_tags (
        work_id TEXT NOT NULL,
        normalized_tag TEXT NOT NULL,
        PRIMARY KEY (work_id, normalized_tag),
        FOREIGN KEY (work_id) REFERENCES work_summaries(work_id)
          ON DELETE CASCADE
      )
    ''');
    await database.execute(
      'CREATE INDEX work_summaries_updated_id '
      'ON work_summaries(updated_at_utc DESC, work_id ASC)',
    );
    await database.execute(
      'CREATE INDEX work_summaries_filters '
      'ON work_summaries(category, my_status, work_status)',
    );
    await database.execute(
      'CREATE INDEX work_summary_tags_tag_work '
      'ON work_summary_tags(normalized_tag, work_id)',
    );
  }

  static Future<void> _upgradeSchema(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await database.execute(
        'ALTER TABLE source_files ADD COLUMN entity_id TEXT',
      );
    }
    if (oldVersion < 3 && newVersion >= 3) {
      await database.execute(
        'ALTER TABLE source_files ADD COLUMN indexed_generation TEXT',
      );
    }
    if (oldVersion < 4 && newVersion >= 4) {
      await database.execute(
        'ALTER TABLE source_files ADD COLUMN read_error TEXT',
      );
    }
  }

  static Future<Map<String, List<String>>> _loadTags(
    Database database,
    List<Map<String, Object?>> rows,
  ) async {
    if (rows.isEmpty) return const {};
    final workIds = rows.map((row) => row['work_id']!.toString()).toList();
    final placeholders = List.filled(workIds.length, '?').join(', ');
    final tags = await database.query(
      'work_summary_tags',
      columns: const ['work_id', 'normalized_tag'],
      where: 'work_id IN ($placeholders)',
      whereArgs: workIds,
      orderBy: 'normalized_tag ASC',
    );
    final result = <String, List<String>>{};
    for (final tag in tags) {
      final workId = tag['work_id']!.toString();
      result
          .putIfAbsent(workId, () => [])
          .add(tag['normalized_tag']!.toString());
    }
    return result;
  }

  static VaultRecordSummary _summaryFromRow(
    Map<String, Object?> row,
    Map<String, List<String>> tagsByWorkId,
  ) {
    final workId = row['work_id']!.toString();
    return VaultRecordSummary(
      id: workId,
      recordKind: RecordKind.workJournal,
      entityType: 'work',
      title: row['title']!.toString(),
      relativePath: row['source_path']!.toString(),
      category: _nullableString(row['category']),
      creator: _nullableString(row['creator']),
      releaseYear: _nullableInt(row['release_year']),
      rating: _nullableDouble(row['rating']),
      workStatus: _nullableString(row['work_status']),
      myStatus: _nullableString(row['my_status']),
      tags: List.unmodifiable(tagsByWorkId[workId] ?? const []),
      addedAt: _parseUtc(row['added_at_utc']),
      updatedAt: _parseUtc(row['updated_at_utc']),
      posterPath: _nullableString(row['poster_path']),
    );
  }

  static void _appendInFilter({
    required List<String> where,
    required List<Object?> arguments,
    required String column,
    required Iterable<String> values,
  }) {
    final normalized = _nonEmptyValues(values);
    if (normalized.isEmpty) return;
    where.add('$column IN (${List.filled(normalized.length, '?').join(', ')})');
    arguments.addAll(normalized);
  }

  static String _normalizedRelativePath(String relativePath) {
    final raw = relativePath.trim();
    if (raw.isEmpty || p.isAbsolute(raw)) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'must be a non-empty path below the Vault root',
      );
    }
    final normalized = p.normalize(raw).replaceAll('\\', '/');
    if (normalized == '.' ||
        normalized == '..' ||
        normalized.startsWith('../')) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'must stay below the Vault root',
      );
    }
    return normalized;
  }

  static String? _nullIfEmpty(String? value) => _normalizeValue(value);

  static String? _normalizeValue(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static List<String> _nonEmptyValues(Iterable<String> values) => values
      .map(_normalizeValue)
      .whereType<String>()
      .toSet()
      .toList(growable: false);

  static List<String> _normalizedTags(Iterable<String> values) =>
      _nonEmptyValues(
        values,
      ).map((value) => value.toLowerCase()).toSet().toList(growable: false);

  static String? _asUtcIso(DateTime? value) => value?.toUtc().toIso8601String();

  static String? _nullableString(Object? value) {
    final string = value?.toString();
    return string == null || string.isEmpty ? null : string;
  }

  static int? _nullableInt(Object? value) => (value as num?)?.toInt();

  static double? _nullableDouble(Object? value) => (value as num?)?.toDouble();

  static DateTime? _parseUtc(Object? value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    return parsed?.toUtc();
  }

  static String _encodeCursor(String sortKey, String workId) => base64Url
      .encode(utf8.encode(jsonEncode({'sort': sortKey, 'workId': workId})));

  static _WorkSummaryCursor? _decodeCursor(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(value)));
      if (decoded is! Map) {
        throw const FormatException('cursor is not an object');
      }
      final sortKey = decoded['sort']?.toString();
      final workId = decoded['workId']?.toString();
      if (sortKey == null || workId == null || workId.isEmpty) {
        throw const FormatException('cursor fields are missing');
      }
      return _WorkSummaryCursor(sortKey: sortKey, workId: workId);
    } on FormatException catch (error) {
      throw ArgumentError.value(value, 'cursor', 'is invalid: $error');
    }
  }
}

/// A bounded request for read-only Work browse summaries.
class WorkSummaryQuery {
  const WorkSummaryQuery({
    this.limit = 50,
    this.cursor,
    this.categories = const [],
    this.workStatuses = const [],
    this.myStatuses = const [],
    this.tag,
  }) : assert(limit > 0 && limit <= maxLimit);

  static const int maxLimit = 250;

  final int limit;
  final String? cursor;
  final Iterable<String> categories;
  final Iterable<String> workStatuses;
  final Iterable<String> myStatuses;
  final String? tag;
}

/// One bounded Work summary page. [nextCursor] is opaque to callers.
class WorkSummaryPage {
  const WorkSummaryPage({required this.summaries, this.nextCursor});

  final List<VaultRecordSummary> summaries;
  final String? nextCursor;
}

class _WorkSummaryCursor {
  const _WorkSummaryCursor({required this.sortKey, required this.workId});

  final String sortKey;
  final String workId;
}
