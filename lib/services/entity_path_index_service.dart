import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'derived_index_atomic_write.dart';
import 'entity_journal_parser.dart';
import 'entity_vault_load_result.dart';

/// `{vault}/.akasha/entity_path_index.json` — entity_id → vault 상대 경로.
class EntityPathIndexService {
  EntityPathIndexService({DerivedIndexAtomicWrite? atomicWrite})
    : atomicWrite = atomicWrite ?? const DerivedIndexAtomicWrite();

  final DerivedIndexAtomicWrite atomicWrite;

  static const int schemaVersion = 1;
  static const String indexDirName = '.akasha';
  static const String indexFileName = 'entity_path_index.json';

  String _indexPath(String vaultPath) =>
      p.join(vaultPath, indexDirName, indexFileName);

  File _indexFile(String vaultPath) => File(_indexPath(vaultPath));

  Future<bool> isAvailable(String vaultPath) async {
    final result = await loadPathsResult(vaultPath);
    return result.isReady;
  }

  /// Parses the index without treating corrupt JSON as an empty map.
  Future<EntityPathIndexLoadResult> loadPathsResult(String vaultPath) async {
    final file = File(_indexPath(vaultPath));
    final opened = await atomicWrite.openForRead(
      target: file,
      validateContent: _isValidIndexContent,
    );
    if (opened.isMissing) {
      return const EntityPathIndexLoadResult.missing();
    }
    if (opened.isCorrupt) {
      return EntityPathIndexLoadResult.corrupt(file.path);
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return EntityPathIndexLoadResult.corrupt(file.path);
      }
      final json = Map<String, dynamic>.from(decoded);
      if ((json['version'] as num?)?.toInt() != schemaVersion) {
        return EntityPathIndexLoadResult.corrupt(file.path);
      }
      final raw = json['paths'];
      if (raw is! Map) {
        return EntityPathIndexLoadResult.corrupt(file.path);
      }
      return EntityPathIndexLoadResult.ready(
        raw.map((key, value) => MapEntry(key.toString(), value.toString())),
      );
    } on Object {
      return EntityPathIndexLoadResult.corrupt(file.path);
    }
  }

  Future<Map<String, String>> loadPaths(String vaultPath) async {
    final result = await loadPathsResult(vaultPath);
    if (result.isCorrupt) {
      throw DerivedIndexCorruptException(result.path ?? _indexPath(vaultPath));
    }
    return Map<String, String>.from(result.paths);
  }

  Future<String?> lookupRelativePath(String vaultPath, String entityId) async {
    if (entityId.isEmpty) return null;
    final result = await loadPathsResult(vaultPath);
    if (!result.isReady) return null;
    return result.paths[entityId];
  }

  Future<String?> lookupAbsolutePath(String vaultPath, String entityId) async {
    final relative = await lookupRelativePath(vaultPath, entityId);
    if (relative == null || relative.isEmpty) return null;
    return p.join(vaultPath, relative);
  }

  Future<void> upsert({
    required String vaultPath,
    required String entityId,
    required String absolutePath,
  }) async {
    if (entityId.isEmpty || absolutePath.isEmpty) return;
    if (!_isWithinVault(vaultPath, absolutePath)) return;

    await atomicWrite.runExclusive(
      target: _indexFile(vaultPath),
      action: () async {
        final paths = await loadPaths(vaultPath);
        paths[entityId] = p.relative(absolutePath, from: vaultPath);
        await _write(vaultPath, paths);
      },
    );
  }

  Future<String?> upsertMarkdownFile({
    required String vaultPath,
    required String absolutePath,
  }) async {
    final result = await upsertMarkdownFileDetailed(
      vaultPath: vaultPath,
      absolutePath: absolutePath,
    );
    result.throwIfWriteFailed();
    return result.entityId;
  }

  /// Incrementally mutates the locator while preserving parse/write issues.
  ///
  /// Non-Entity Markdown is a successful skipped operation. A malformed file
  /// under `entities/` is reported as partial even when stale locator cleanup
  /// succeeds. The source Markdown itself is never changed or deleted.
  Future<EntityPathIndexMutationResult> upsertMarkdownFileDetailed({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.trim().isEmpty ||
        absolutePath.trim().isEmpty ||
        !_isWithinVault(vaultPath, absolutePath)) {
      return EntityPathIndexMutationResult(
        operation: EntityPathIndexMutationOperation.skipped,
        writeApplied: false,
        skippedPath: absolutePath,
        issues: [
          EntityVaultLoadIssue(
            relativePath: absolutePath,
            errorCode: 'entity_path_invalid',
            severity: EntityVaultIssueSeverity.error,
          ),
        ],
      );
    }

    final file = File(absolutePath);
    final relativePath = _relativePath(vaultPath, absolutePath);
    if (!await file.exists()) {
      try {
        final removed = await removeByAbsolutePath(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        return EntityPathIndexMutationResult(
          operation: EntityPathIndexMutationOperation.removed,
          writeApplied: true,
          entityId: removed,
        );
      } on Object catch (error, stack) {
        return _writeFailureResult(
          operation: EntityPathIndexMutationOperation.removed,
          path: relativePath,
          error: error,
          stack: stack,
        );
      }
    }

    EntityJournalParseResult parsed;
    try {
      parsed = EntityJournalParser.parseDetailed(
        await file.readAsString(),
        file.path,
      );
    } on Object {
      return _skipAndRemoveWithIssue(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
        issue: EntityVaultLoadIssue(
          relativePath: relativePath,
          errorCode: 'io_read_failed',
          severity: EntityVaultIssueSeverity.error,
        ),
      );
    }

    final parseIssue = parsed.issue;
    final entry = parsed.entry;
    if (parseIssue != null || entry == null) {
      final issue = _normalizeIssue(
        parseIssue ??
            EntityVaultLoadIssue(
              relativePath: relativePath,
              errorCode: 'entity_parse_empty',
              severity: EntityVaultIssueSeverity.error,
            ),
        vaultPath: vaultPath,
        absolutePath: absolutePath,
        promoteIgnored: _isEntityMarkdownPath(vaultPath, absolutePath),
      );
      return _skipAndRemoveWithIssue(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
        issue: issue,
      );
    }

    try {
      await upsert(
        vaultPath: vaultPath,
        entityId: entry.entityId,
        absolutePath: file.path,
      );
      return EntityPathIndexMutationResult(
        operation: EntityPathIndexMutationOperation.upserted,
        writeApplied: true,
        entityId: entry.entityId,
      );
    } on Object catch (error, stack) {
      return _writeFailureResult(
        operation: EntityPathIndexMutationOperation.upserted,
        path: relativePath,
        entityId: entry.entityId,
        error: error,
        stack: stack,
      );
    }
  }

  Future<void> remove({
    required String vaultPath,
    required String entityId,
  }) async {
    if (entityId.isEmpty) return;

    await atomicWrite.runExclusive(
      target: _indexFile(vaultPath),
      action: () async {
        final paths = await loadPaths(vaultPath);
        if (paths.remove(entityId) == null) return;
        await _write(vaultPath, paths);
      },
    );
  }

  Future<String?> removeByAbsolutePath({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.trim().isEmpty || absolutePath.trim().isEmpty) return null;
    if (!_isWithinVault(vaultPath, absolutePath)) return null;

    return atomicWrite.runExclusive(
      target: _indexFile(vaultPath),
      action: () async {
        final relative = p.relative(absolutePath, from: vaultPath);
        final paths = await loadPaths(vaultPath);
        String? removedEntityId;
        paths.removeWhere((entityId, indexedPath) {
          final matches = p.normalize(indexedPath) == p.normalize(relative);
          if (matches) removedEntityId = entityId;
          return matches;
        });
        if (removedEntityId == null) return null;
        await _write(vaultPath, paths);
        return removedEntityId;
      },
    );
  }

  /// Rebuilds when missing or corrupt; leaves a healthy index alone.
  Future<void> ensureIndex(String vaultPath) async {
    if (await isAvailable(vaultPath)) return;
    await rebuildFromVault(vaultPath);
  }

  Future<void> rebuildFromVault(String vaultPath) async {
    final result = await rebuildFromVaultDetailed(vaultPath);
    result.throwIfWriteFailed();
  }

  /// Rebuilds every valid Entity locator and returns all per-file issues.
  Future<EntityPathIndexMutationResult> rebuildFromVaultDetailed(
    String vaultPath,
  ) {
    return atomicWrite.runExclusive(
      target: _indexFile(vaultPath),
      action: () async {
        final paths = <String, String>{};
        final issues = <EntityVaultLoadIssue>[];
        final root = Directory(
          p.join(vaultPath, EntityJournalParser.entitiesDirName),
        );
        if (await root.exists()) {
          await for (final entity in root.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is! File || !entity.path.endsWith('.md')) continue;
            final relativePath = _relativePath(vaultPath, entity.path);
            String content;
            try {
              content = await entity.readAsString();
            } on Object {
              issues.add(
                EntityVaultLoadIssue(
                  relativePath: relativePath,
                  errorCode: 'io_read_failed',
                  severity: EntityVaultIssueSeverity.error,
                ),
              );
              continue;
            }

            final parsed = EntityJournalParser.parseDetailed(
              content,
              entity.path,
            );
            final parseIssue = parsed.issue;
            if (parseIssue != null) {
              issues.add(
                _normalizeIssue(
                  parseIssue,
                  vaultPath: vaultPath,
                  absolutePath: entity.path,
                  promoteIgnored: true,
                ),
              );
              continue;
            }
            final entry = parsed.entry;
            if (entry == null) continue;
            paths[entry.entityId] = p.relative(entity.path, from: vaultPath);
          }
        }
        try {
          await _write(vaultPath, paths);
          return EntityPathIndexMutationResult(
            operation: EntityPathIndexMutationOperation.rebuilt,
            writeApplied: true,
            indexedEntries: paths.length,
            issues: List.unmodifiable(issues),
          );
        } on Object catch (error, stack) {
          return EntityPathIndexMutationResult(
            operation: EntityPathIndexMutationOperation.rebuilt,
            writeApplied: false,
            indexedEntries: paths.length,
            issues: [
              ...issues,
              EntityVaultLoadIssue(
                relativePath: _relativePath(
                  vaultPath,
                  _indexFile(vaultPath).path,
                ),
                errorCode: 'index_write_failed',
                severity: EntityVaultIssueSeverity.error,
                diagnostic: error.runtimeType.toString(),
              ),
            ],
            writeFailure: error,
            writeFailureStack: stack,
          );
        }
      },
    );
  }

  Future<EntityPathIndexMutationResult> _skipAndRemoveWithIssue({
    required String vaultPath,
    required String absolutePath,
    required EntityVaultLoadIssue issue,
  }) async {
    try {
      final removed = await removeByAbsolutePath(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      );
      return EntityPathIndexMutationResult(
        operation: EntityPathIndexMutationOperation.skipped,
        writeApplied: true,
        entityId: removed,
        skippedPath: _relativePath(vaultPath, absolutePath),
        issues: [issue],
      );
    } on Object catch (error, stack) {
      return EntityPathIndexMutationResult(
        operation: EntityPathIndexMutationOperation.skipped,
        writeApplied: false,
        skippedPath: _relativePath(vaultPath, absolutePath),
        issues: [
          issue,
          EntityVaultLoadIssue(
            relativePath: _relativePath(vaultPath, absolutePath),
            errorCode: 'index_write_failed',
            severity: EntityVaultIssueSeverity.error,
            diagnostic: error.runtimeType.toString(),
          ),
        ],
        writeFailure: error,
        writeFailureStack: stack,
      );
    }
  }

  EntityPathIndexMutationResult _writeFailureResult({
    required EntityPathIndexMutationOperation operation,
    required String path,
    required Object error,
    required StackTrace stack,
    String? entityId,
  }) {
    return EntityPathIndexMutationResult(
      operation: operation,
      writeApplied: false,
      entityId: entityId,
      skippedPath: path,
      issues: [
        EntityVaultLoadIssue(
          relativePath: path,
          errorCode: 'index_write_failed',
          severity: EntityVaultIssueSeverity.error,
          diagnostic: error.runtimeType.toString(),
        ),
      ],
      writeFailure: error,
      writeFailureStack: stack,
    );
  }

  static EntityVaultLoadIssue _normalizeIssue(
    EntityVaultLoadIssue issue, {
    required String vaultPath,
    required String absolutePath,
    required bool promoteIgnored,
  }) {
    return EntityVaultLoadIssue(
      relativePath: _relativePath(vaultPath, absolutePath),
      errorCode: issue.errorCode,
      severity:
          promoteIgnored && issue.severity == EntityVaultIssueSeverity.ignored
          ? EntityVaultIssueSeverity.warning
          : issue.severity,
      diagnostic: issue.diagnostic,
    );
  }

  static bool _isEntityMarkdownPath(String vaultPath, String absolutePath) {
    final entitiesRoot = p.normalize(
      p.join(vaultPath, EntityJournalParser.entitiesDirName),
    );
    return p.isWithin(entitiesRoot, p.normalize(absolutePath));
  }

  static String _relativePath(String vaultPath, String absolutePath) {
    return p.relative(absolutePath, from: vaultPath).replaceAll('\\', '/');
  }

  Future<void> _write(String vaultPath, Map<String, String> paths) async {
    final payload = <String, dynamic>{
      'version': schemaVersion,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'paths': paths,
    };
    await atomicWrite.writeText(
      target: _indexFile(vaultPath),
      content: const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  static bool _isValidIndexContent(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) return false;
      if ((decoded['version'] as num?)?.toInt() != schemaVersion) return false;
      return decoded['paths'] is Map;
    } on Object {
      return false;
    }
  }

  static bool _isWithinVault(String vaultPath, String absolutePath) {
    final vaultRoot = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(absolutePath));
    final relative = p.relative(target, from: vaultRoot);
    if (relative == '.') return true;
    if (p.isAbsolute(relative)) return false;
    return relative != '..' && !relative.startsWith('..${p.separator}');
  }
}

enum EntityPathIndexMutationOperation { upserted, removed, skipped, rebuilt }

class EntityPathIndexMutationResult {
  const EntityPathIndexMutationResult({
    required this.operation,
    required this.writeApplied,
    this.entityId,
    this.skippedPath,
    this.indexedEntries = 0,
    this.issues = const [],
    this.writeFailure,
    this.writeFailureStack,
  });

  final EntityPathIndexMutationOperation operation;
  final bool writeApplied;
  final String? entityId;
  final String? skippedPath;
  final int indexedEntries;
  final List<EntityVaultLoadIssue> issues;

  /// Preserved only so compatibility wrappers can rethrow write failures.
  /// It is intentionally omitted from diagnostics and serialization.
  final Object? writeFailure;
  final StackTrace? writeFailureStack;

  bool get hasReportableIssues =>
      issues.any((issue) => issue.severity != EntityVaultIssueSeverity.ignored);

  bool get succeeded => writeApplied && !hasReportableIssues;

  bool get partialSuccess => writeApplied && hasReportableIssues;

  List<String> get malformedPaths => issues
      .where((issue) => issue.severity != EntityVaultIssueSeverity.ignored)
      .map((issue) => issue.relativePath)
      .toSet()
      .toList(growable: false);

  void throwIfWriteFailed() {
    final failure = writeFailure;
    if (failure == null) return;
    Error.throwWithStackTrace(failure, writeFailureStack ?? StackTrace.current);
  }

  Map<String, dynamic> toJson() => {
    'operation': operation.name,
    'succeeded': succeeded,
    'partialSuccess': partialSuccess,
    'writeApplied': writeApplied,
    'indexedEntries': indexedEntries,
    if (entityId != null && entityId!.isNotEmpty) 'entityId': entityId,
    if (skippedPath != null && skippedPath!.isNotEmpty)
      'skippedPath': skippedPath,
    if (malformedPaths.isNotEmpty) 'malformedPaths': malformedPaths,
    if (issues.isNotEmpty)
      'issues': [
        for (final issue in issues)
          {
            'path': issue.relativePath,
            'code': issue.errorCode,
            'severity': issue.severity.name,
            if (issue.diagnostic != null && issue.diagnostic!.isNotEmpty)
              'diagnostic': issue.diagnostic,
          },
      ],
  };
}

class EntityPathIndexLoadResult {
  const EntityPathIndexLoadResult._({
    required this.paths,
    required this.isMissing,
    required this.isCorrupt,
    this.path,
  });

  const EntityPathIndexLoadResult.missing()
    : this._(paths: const {}, isMissing: true, isCorrupt: false);

  const EntityPathIndexLoadResult.corrupt(String path)
    : this._(paths: const {}, isMissing: false, isCorrupt: true, path: path);

  const EntityPathIndexLoadResult.ready(Map<String, String> paths)
    : this._(paths: paths, isMissing: false, isCorrupt: false);

  final Map<String, String> paths;
  final bool isMissing;
  final bool isCorrupt;
  final String? path;

  bool get isReady => !isMissing && !isCorrupt;
}
