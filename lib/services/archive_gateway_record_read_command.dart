import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/record_kind.dart';
import '../core/archiving/vault_file_revision.dart';
import 'record_path_index_service.dart';
import 'record_summary_index_service.dart';
import 'title_alias_index_service.dart';
import 'vault_document_identity.dart';

/// Bounded read side of AKASHA's local agent command surface.
///
/// It intentionally exposes only exact title/alias lookup and one stable-id
/// Markdown read. It never accepts a raw Vault path, scans Markdown on behalf
/// of the agent, or writes any user-owned archive state.
class ArchiveGatewayRecordReadCommand {
  ArchiveGatewayRecordReadCommand({
    TitleAliasIndexService? titleAliasIndex,
    RecordPathIndexService? recordPathIndex,
  }) : _titleAliasIndex = titleAliasIndex ?? TitleAliasIndexService(),
       _recordPathIndex = recordPathIndex ?? const RecordPathIndexService();

  static const int maxLookupResults = 20;
  static const int defaultReadMaxBytes = 256 * 1024;
  static const int maxReadBytes = 1024 * 1024;

  final TitleAliasIndexService _titleAliasIndex;
  final RecordPathIndexService _recordPathIndex;

  Future<ArchiveGatewayRecordReadCommandResult> execute({
    required String vaultPath,
    required String verb,
    required Map<String, dynamic> payload,
  }) => switch (verb) {
    'lookup' => lookup(vaultPath: vaultPath, payload: payload),
    'read' => read(vaultPath: vaultPath, payload: payload),
    _ => Future.value(
      ArchiveGatewayRecordReadCommandResult.usage(
        'Usage: akasha record lookup|read --vault <vault-path>.',
      ),
    ),
  };

  Future<ArchiveGatewayRecordReadCommandResult> lookup({
    required String vaultPath,
    required Map<String, dynamic> payload,
  }) async {
    ArchiveGatewayRecordLookupRequest request;
    try {
      request = ArchiveGatewayRecordLookupRequest.fromJson(payload);
    } on FormatException catch (error) {
      return ArchiveGatewayRecordReadCommandResult.invalid(error.message);
    }

    if (!await _titleAliasIndex.isAvailable(vaultPath)) {
      return ArchiveGatewayRecordReadCommandResult.failure(
        'title_index_unavailable',
        'The derived title/alias index is unavailable; no Vault scan was run.',
      );
    }

    try {
      final matches = await _titleAliasIndex.lookup(
        vaultPath,
        request.name,
        entityType: request.entityType,
        recordKind: request.recordKind,
      );
      final readable = matches
          .where(
            (entry) =>
                entry.documentRecordId != null &&
                RecordPathIndexService.isStableRecordId(
                  entry.documentRecordId!,
                ),
          )
          .toList(growable: false);
      if (readable.isEmpty && matches.isNotEmpty) {
        return ArchiveGatewayRecordReadCommandResult.failure(
          'record_id_required',
          'Matching legacy Documents have no physical record_id for a bounded Record read.',
        );
      }
      return ArchiveGatewayRecordReadCommandResult.success({
        'matches': readable
            .take(request.limit)
            .map(
              (entry) => <String, Object?>{
                'recordId': entry.documentRecordId,
                'targetId': entry.targetId,
                'recordKind': entry.recordKind.name,
                'entityType': entry.entityType,
                'title': entry.title,
                'matchedFields': List<String>.from(entry.fields),
              },
            )
            .toList(growable: false),
      });
    } on Object catch (error) {
      return ArchiveGatewayRecordReadCommandResult.failure(
        'record_lookup_failed',
        '$error',
      );
    }
  }

  Future<ArchiveGatewayRecordReadCommandResult> read({
    required String vaultPath,
    required Map<String, dynamic> payload,
  }) async {
    ArchiveGatewayRecordReadRequest request;
    try {
      request = ArchiveGatewayRecordReadRequest.fromJson(payload);
    } on FormatException catch (error) {
      return ArchiveGatewayRecordReadCommandResult.invalid(error.message);
    }

    if (!await _recordPathIndex.isAvailable(vaultPath)) {
      return ArchiveGatewayRecordReadCommandResult.failure(
        'record_locator_index_unavailable',
        'The derived Record locator index is unavailable; no Vault scan was run.',
      );
    }

    final located = await _recordPathIndex.lookup(vaultPath, request.recordId);
    if (located.isAmbiguous) {
      return ArchiveGatewayRecordReadCommandResult.failure(
        'record_id_ambiguous',
        'More than one Markdown file has this stable Record id.',
      );
    }
    if (!located.isFound) {
      return ArchiveGatewayRecordReadCommandResult.failure(
        'record_not_found',
        'No indexed Markdown Record has this stable Record id.',
      );
    }

    final file = File(
      p.joinAll([vaultPath, ...located.relativePath!.split('/')]),
    );
    try {
      if (!await file.exists()) {
        return ArchiveGatewayRecordReadCommandResult.failure(
          'record_locator_stale',
          'The Record locator points to a missing Markdown file.',
        );
      }
      if (await file.length() > request.maxBytes) {
        return ArchiveGatewayRecordReadCommandResult.failure(
          'record_too_large',
          'The Record exceeds the requested bounded read limit.',
        );
      }

      final bytes = await file.readAsBytes();
      if (bytes.length > request.maxBytes) {
        return ArchiveGatewayRecordReadCommandResult.failure(
          'record_too_large',
          'The Record changed beyond the requested bounded read limit.',
        );
      }
      final markdown = utf8.decode(bytes, allowMalformed: false);
      final documentRecordId = VaultDocumentIdentity.recordIdFromMarkdown(
        markdown,
      );
      if (documentRecordId != request.recordId) {
        return ArchiveGatewayRecordReadCommandResult.failure(
          'record_locator_stale',
          'The indexed Record identity no longer matches its Markdown file.',
        );
      }
      final summary = await VaultRecordSummary.fromMarkdownFile(
        vaultPath: vaultPath,
        file: file,
      );
      if (summary == null ||
          summary.relativePath.replaceAll('\\', '/') !=
              located.relativePath!.replaceAll('\\', '/')) {
        return ArchiveGatewayRecordReadCommandResult.failure(
          'record_locator_stale',
          'The indexed Record identity no longer matches its Markdown file.',
        );
      }

      final revision = VaultFileRevision.fromBytes(bytes);
      return ArchiveGatewayRecordReadCommandResult.success({
        'record': <String, Object?>{
          'recordId': request.recordId,
          'targetId': summary.id,
          'recordKind': summary.recordKind.name,
          'entityType': summary.entityType,
          'title': summary.title,
          'revision':
              'v2:sha256:${revision.sha256};bytes:${revision.byteLength}',
          'byteLength': bytes.length,
          'markdown': markdown,
        },
      });
    } on FormatException {
      return ArchiveGatewayRecordReadCommandResult.failure(
        'record_content_not_utf8',
        'The Record bytes are not valid UTF-8 Markdown.',
      );
    } on FileSystemException catch (error) {
      return ArchiveGatewayRecordReadCommandResult.failure(
        'record_unreadable',
        error.message,
      );
    } on Object catch (error) {
      return ArchiveGatewayRecordReadCommandResult.failure(
        'record_read_failed',
        '$error',
      );
    }
  }
}

class ArchiveGatewayRecordLookupRequest {
  const ArchiveGatewayRecordLookupRequest({
    required this.name,
    required this.limit,
    this.entityType,
    this.recordKind,
  });

  final String name;
  final int limit;
  final String? entityType;
  final RecordKind? recordKind;

  factory ArchiveGatewayRecordLookupRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    _rejectUnknown(json, const {'name', 'limit', 'entityType', 'recordKind'});
    final name = _requiredString(json['name'], 'name');
    if (utf8.encode(name).length > 512) {
      throw const FormatException('name exceeds 512 UTF-8 bytes.');
    }
    final limit = _boundedInt(
      json['limit'],
      field: 'limit',
      fallback: ArchiveGatewayRecordReadCommand.maxLookupResults,
      min: 1,
      max: ArchiveGatewayRecordReadCommand.maxLookupResults,
    );
    final entityType = _optionalString(json['entityType']);
    final recordKindName = _optionalString(json['recordKind']);
    final recordKind = recordKindName == null
        ? null
        : RecordKind.values
              .where((kind) => kind.name == recordKindName)
              .firstOrNull;
    if (recordKindName != null && recordKind == null) {
      throw const FormatException('recordKind is invalid.');
    }
    return ArchiveGatewayRecordLookupRequest(
      name: name,
      limit: limit,
      entityType: entityType,
      recordKind: recordKind,
    );
  }
}

class ArchiveGatewayRecordReadRequest {
  const ArchiveGatewayRecordReadRequest({
    required this.recordId,
    required this.maxBytes,
  });

  final String recordId;
  final int maxBytes;

  factory ArchiveGatewayRecordReadRequest.fromJson(Map<String, dynamic> json) {
    _rejectUnknown(json, const {'recordId', 'maxBytes'});
    final recordId = _requiredString(json['recordId'], 'recordId');
    if (!RecordPathIndexService.isStableRecordId(recordId)) {
      throw const FormatException('recordId is invalid.');
    }
    return ArchiveGatewayRecordReadRequest(
      recordId: recordId,
      maxBytes: _boundedInt(
        json['maxBytes'],
        field: 'maxBytes',
        fallback: ArchiveGatewayRecordReadCommand.defaultReadMaxBytes,
        min: 1,
        max: ArchiveGatewayRecordReadCommand.maxReadBytes,
      ),
    );
  }
}

class ArchiveGatewayRecordReadCommandResult {
  const ArchiveGatewayRecordReadCommandResult._({
    required this.ok,
    this.errorCode,
    this.message,
    this.data = const {},
  });

  final bool ok;
  final String? errorCode;
  final String? message;
  final Map<String, Object?> data;

  factory ArchiveGatewayRecordReadCommandResult.success(
    Map<String, Object?> data,
  ) => ArchiveGatewayRecordReadCommandResult._(ok: true, data: data);

  factory ArchiveGatewayRecordReadCommandResult.failure(
    String code,
    String message,
  ) => ArchiveGatewayRecordReadCommandResult._(
    ok: false,
    errorCode: code,
    message: message,
  );

  factory ArchiveGatewayRecordReadCommandResult.invalid(String message) =>
      ArchiveGatewayRecordReadCommandResult.failure(
        'command_payload_invalid',
        message,
      );

  factory ArchiveGatewayRecordReadCommandResult.usage(String message) =>
      ArchiveGatewayRecordReadCommandResult.failure('command_usage', message);

  Map<String, Object?> toJson() => {
    'ok': ok,
    ...data,
    if (!ok) 'error': {'code': errorCode, 'message': message},
  };
}

String _requiredString(Object? raw, String field) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) throw FormatException('$field is required.');
  return value;
}

String? _optionalString(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}

int _boundedInt(
  Object? raw, {
  required String field,
  required int fallback,
  required int min,
  required int max,
}) {
  if (raw == null) return fallback;
  final value = raw is num ? raw.toInt() : int.tryParse(raw.toString());
  if (value == null || value < min || value > max) {
    throw FormatException('$field must be between $min and $max.');
  }
  return value;
}

void _rejectUnknown(Map<String, dynamic> json, Set<String> allowed) {
  final unknown = json.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw FormatException(
      'request contains unsupported fields: ${unknown.join(', ')}.',
    );
  }
}
