import 'dart:io';
import 'dart:convert';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

/// AKASHA Vault Format Spec v3 — standalone conformance validator.
///
/// Deliberately does NOT import app code (`lib/`): conformance is defined by
/// the specification (`docs/active/AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md`,
/// embedded in vaults at `.akasha/spec/spec_v3.md`), not by AKASHA app
/// behavior. Any tool that passes this validator can claim vault
/// compatibility without AKASHA installed.
///
/// Usage:
///   dart run tool/vault_format_validator.dart <vault_path> [--strict]
///
/// Exit codes: 0 = conforming, 1 = errors found (or warnings with --strict),
/// 2 = usage/IO failure.
Future<void> main(List<String> args) async {
  final paths = args.where((a) => !a.startsWith('--')).toList();
  final strict = args.contains('--strict');
  if (paths.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/vault_format_validator.dart <vault_path> [--strict]',
    );
    exit(2);
  }

  final vaultDir = Directory(paths.single);
  if (!vaultDir.existsSync()) {
    stderr.writeln('Vault path not found: ${paths.single}');
    exit(2);
  }

  final report = await VaultFormatValidator().validateVault(vaultDir.path);
  stdout.write(report.render());

  if (report.errors.isNotEmpty || (strict && report.warnings.isNotEmpty)) {
    exit(1);
  }
}

class VaultFormatIssue {
  const VaultFormatIssue({
    required this.severity,
    required this.code,
    required this.path,
    required this.message,
  });

  /// `error` = spec MUST violated · `warning` = legacy/should violation.
  final String severity;
  final String code;
  final String path;
  final String message;

  @override
  String toString() => '[$severity] $code · $path — $message';
}

class VaultFormatReport {
  final List<VaultFormatIssue> issues = [];
  int recordCount = 0;
  int v3Count = 0;
  int legacyCount = 0;
  int skippedCount = 0;

  List<VaultFormatIssue> get errors =>
      issues.where((i) => i.severity == 'error').toList(growable: false);
  List<VaultFormatIssue> get warnings =>
      issues.where((i) => i.severity == 'warning').toList(growable: false);

  String render() {
    final buffer = StringBuffer()
      ..writeln('AKASHA Vault Format Validator (spec v3)')
      ..writeln(
        'records: $recordCount (v3: $v3Count · legacy v1/v2: $legacyCount · '
        'skipped non-record md: $skippedCount)',
      );
    for (final issue in issues) {
      buffer.writeln(issue);
    }
    buffer.writeln(
      'result: ${errors.length} error(s), ${warnings.length} warning(s)',
    );
    return buffer.toString();
  }
}

class VaultFormatValidator {
  // ── Spec §2.1 ──────────────────────────────────────────────────────
  static const Set<String> recordKinds = {
    'workJournal',
    'entityJournal',
    'timelineEntry',
    'freeformJournal',
  };
  static const Set<String> legacyRecordKinds = {'timeline'};
  static const Set<String> entityAnchoredKinds = {
    'workJournal',
    'entityJournal',
  };
  static const Set<String> sources = {
    'user',
    'app',
    'agent',
    'importTool',
    'script',
  };

  // ── Spec §3 ────────────────────────────────────────────────────────
  static const Map<String, String> typePrefixes = {
    'work': 'wk',
    'person': 'pe',
    'event': 'ev',
    'place': 'pl',
    'concept': 'co',
    'organization': 'or',
    'object': 'ob',
  };

  // ── Spec §4.1 ──────────────────────────────────────────────────────
  static const Set<String> coreRelations = {
    'related',
    'about',
    'appears_in',
    'created_by',
    'part_of',
    'member_of',
    'located_in',
    'inspired_by',
  };
  static final RegExp _userRelationPattern = RegExp(r'^u:[a-z0-9_]{1,40}$');

  static final RegExp _utcZPattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$',
  );
  static final RegExp _wallClockPattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?$',
  );

  static const Set<String> _skipFileNames = {'VAULT_README.md', 'NOTES.md'};

  Future<VaultFormatReport> validateVault(String vaultPath) async {
    final report = VaultFormatReport();
    final files = await _listMdFiles(Directory(vaultPath));

    for (final file in files) {
      final rel = file.path
          .substring(vaultPath.length)
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^/'), '');

      // Spec §1: hidden directories other than .akasha/.trash are ignored;
      // derived/trash content is not part of the record surface either.
      final segments = rel.split('/');
      if (segments.any((s) => s.startsWith('.'))) continue;
      if (!rel.endsWith('.md')) continue;
      if (_skipFileNames.contains(segments.last)) continue;

      if (segments.first == 'canvases') {
        validateCanvasRecord(file.path, rel, report, vaultPath);
        continue;
      }

      validateRecordContent(await file.readAsString(), rel, report);
    }
    return report;
  }

  Future<List<File>> _listMdFiles(Directory dir) async {
    final files = <File>[];
    try {
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          files.add(entity);
        } else if (entity is Directory) {
          final name = p.basename(entity.path);
          if (name.startsWith('.') && name != '.akasha' && name != '.trash') {
            continue;
          }
          files.addAll(await _listMdFiles(entity));
        }
      }
    } catch (_) {
      // Ignore OS permission denied errors for locked or ghost directories
    }
    return files;
  }

  /// Validates one Markdown file's content against the v3 record contract.
  void validateRecordContent(
    String content,
    String path,
    VaultFormatReport report,
  ) {
    final frontmatter = _extractFrontmatter(content);
    if (frontmatter == null) {
      report.skippedCount++;
      report.issues.add(
        VaultFormatIssue(
          severity: 'warning',
          code: 'no_frontmatter',
          path: path,
          message:
              'Markdown file without YAML frontmatter is not a record (§2).',
        ),
      );
      return;
    }

    Map<dynamic, dynamic> yaml;
    try {
      final loaded = loadYaml(frontmatter);
      if (loaded is! Map) {
        _error(report, 'frontmatter_not_map', path,
            'frontmatter must be a YAML mapping (§2).');
        return;
      }
      yaml = loaded;
    } catch (e) {
      _error(report, 'frontmatter_invalid_yaml', path,
          'frontmatter is not parseable YAML (§2): $e');
      return;
    }

    report.recordCount++;

    final schemaVersion = yaml['schema_version'];
    if (schemaVersion == null) {
      report.legacyCount++;
      _validateLegacyRecord(yaml, path, report);
      return;
    }
    if (schemaVersion is! int) {
      _error(report, 'schema_version_type', path,
          'schema_version must be an integer (§2.1).');
      return;
    }
    if (schemaVersion > 3) {
      report.issues.add(
        VaultFormatIssue(
          severity: 'warning',
          code: 'schema_version_future',
          path: path,
          message:
              'schema_version $schemaVersion is newer than this validator '
              '(additive evolution assumed, §5).',
        ),
      );
    } else if (schemaVersion != 3) {
      _error(report, 'schema_version_value', path,
          'schema_version must be 3 for v3 records (§2.1).');
    }
    report.v3Count++;

    _requireNonEmptyString(yaml, 'record_id', path, report);
    final kind = yaml['record_kind']?.toString() ?? '';
    if (!recordKinds.contains(kind)) {
      if (legacyRecordKinds.contains(kind)) {
        report.issues.add(
          VaultFormatIssue(
            severity: 'warning',
            code: 'record_kind_legacy',
            path: path,
            message:
                'record_kind "$kind" is a legacy alias; canonical is '
                'timelineEntry (§2.1).',
          ),
        );
      } else {
        _error(report, 'record_kind_unknown', path,
            'record_kind "$kind" is not in the v3 enum (§2.1).');
      }
    }
    _requireNonEmptyString(yaml, 'title', path, report);

    _validateEntityAnchor(yaml, kind, path, report);
    _validateSystemTimestamp(yaml, 'created_at', path, report, required: true);
    _validateSystemTimestamp(yaml, 'updated_at', path, report, required: true);
    _validateSystemTimestamp(yaml, 'added_at', path, report, required: false);

    final source = yaml['source']?.toString() ?? '';
    if (source.isEmpty) {
      _error(report, 'source_required', path,
          'source is required for v3 records (§2.1).');
    } else if (!sources.contains(source)) {
      _error(report, 'source_unknown', path,
          'source "$source" is not in the provenance enum (§2.1).');
    }

    _validateOccurredAt(yaml, path, report);
    _validateLinks(yaml, path, report);
  }

  void _validateLegacyRecord(
    Map<dynamic, dynamic> yaml,
    String path,
    VaultFormatReport report,
  ) {
    // v1/v2 records stay readable forever (§5); only sanity-check identity.
    final kind = yaml['record_kind']?.toString() ?? '';
    if (kind.isNotEmpty &&
        !recordKinds.contains(kind) &&
        !legacyRecordKinds.contains(kind)) {
      _error(report, 'record_kind_unknown', path,
          'record_kind "$kind" is not a known record kind (§2.1).');
    }
  }

  void _validateEntityAnchor(
    Map<dynamic, dynamic> yaml,
    String kind,
    String path,
    VaultFormatReport report,
  ) {
    final entityType = yaml['entity_type']?.toString() ?? '';
    final entityId = yaml['entity_id']?.toString() ?? '';
    final anchored = entityAnchoredKinds.contains(kind);

    if (anchored && entityType.isEmpty) {
      _error(report, 'entity_type_required', path,
          'entity_type is required for $kind (§2.1).');
    }
    if (anchored && entityId.isEmpty) {
      _error(report, 'entity_id_required', path,
          'entity_id is required for $kind (§2.1).');
    }

    if (entityType.isNotEmpty && !typePrefixes.containsKey(entityType)) {
      _error(report, 'entity_type_unknown', path,
          'entity_type "$entityType" is not one of the 7 anchor types (§3).');
    }

    if (entityId.isNotEmpty && entityType.isNotEmpty) {
      final prefix = typePrefixes[entityType];
      if (prefix != null) {
        if (entityId.startsWith('cu_')) {
          if (entityType != 'object') {
            _error(report, 'entity_id_prefix_mismatch', path,
                'legacy cu_ IDs map to object, not "$entityType" (§3).');
          } else {
            report.issues.add(
              VaultFormatIssue(
                severity: 'warning',
                code: 'entity_id_legacy_cu',
                path: path,
                message:
                    'legacy cu_ ID; new IDs must use ob_ for object (§3).',
              ),
            );
          }
        } else if (!entityId.startsWith('${prefix}_')) {
          _error(report, 'entity_id_prefix_mismatch', path,
              'entity_id "$entityId" does not match "$entityType" '
              '(expected ${prefix}_ prefix, §3).');
        }
      }
    }
  }

  void _validateSystemTimestamp(
    Map<dynamic, dynamic> yaml,
    String key,
    String path,
    VaultFormatReport report, {
    required bool required,
  }) {
    final raw = yaml[key];
    if (raw == null) {
      if (required) {
        _error(report, '${key}_required', path,
            '$key is required for v3 records (§2.1).');
      }
      return;
    }
    final value = raw.toString();
    if (!_utcZPattern.hasMatch(value)) {
      _error(report, '${key}_not_utc', path,
          '$key "$value" must be UTC ISO-8601 ending in Z (§2.2).');
    }
  }

  void _validateOccurredAt(
    Map<dynamic, dynamic> yaml,
    String path,
    VaultFormatReport report,
  ) {
    final raw = yaml['occurred_at'];
    if (raw == null) return;
    final value = raw.toString();

    if (_wallClockPattern.hasMatch(value)) return;
    if (_utcZPattern.hasMatch(value) ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value)) {
      report.issues.add(
        VaultFormatIssue(
          severity: 'warning',
          code: 'occurred_at_legacy_zone',
          path: path,
          message:
              'occurred_at "$value" carries a timezone; semantic local time '
              'must be wall-clock without Z/offset. Readers accept it; the '
              'next write normalizes it (§2.3).',
        ),
      );
      return;
    }
    _error(report, 'occurred_at_invalid', path,
        'occurred_at "$value" is not an ISO-8601 wall-clock timestamp (§2.3).');
  }

  void _validateLinks(
    Map<dynamic, dynamic> yaml,
    String path,
    VaultFormatReport report,
  ) {
    final links = yaml['links'];
    if (links is! Iterable) return;
    for (final link in links) {
      if (link is! Map) {
        _error(report, 'link_not_map', path,
            'links entries must be mappings (§4.1).');
        continue;
      }
      final relation = link['relation']?.toString() ?? 'related';
      if (coreRelations.contains(relation) ||
          _userRelationPattern.hasMatch(relation)) {
        continue;
      }
      // Readers MUST preserve unknown legacy relations (§4.1) — so an
      // unknown value is a warning, not a hard failure.
      report.issues.add(
        VaultFormatIssue(
          severity: 'warning',
          code: 'link_relation_nonconforming',
          path: path,
          message:
              'relation "$relation" is outside the core vocabulary and the '
              'u: namespace; conforming writers must not emit it (§4.1).',
        ),
      );
    }
  }

  void _requireNonEmptyString(
    Map<dynamic, dynamic> yaml,
    String key,
    String path,
    VaultFormatReport report,
  ) {
    final value = yaml[key]?.toString().trim() ?? '';
    if (value.isEmpty) {
      _error(report, '${key}_required', path,
          '$key is required for v3 records (§2.1).');
    }
  }

  void _error(
    VaultFormatReport report,
    String code,
    String path,
    String message,
  ) {
    report.issues.add(
      VaultFormatIssue(
        severity: 'error',
        code: code,
        path: path,
        message: message,
      ),
    );
  }

  String? _extractFrontmatter(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return null;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        return lines.sublist(1, i).join('\n');
      }
    }
    return null;
  }

  void validateCanvasRecord(
    String mdFilePath,
    String relPath,
    VaultFormatReport report,
    String vaultPath,
  ) {
    report.recordCount++;
    final mdFile = File(mdFilePath);
    if (!mdFile.existsSync()) {
      _error(report, 'canvas_file_not_found', relPath, 'Canvas Markdown file does not exist.');
      return;
    }

    final mdContent = mdFile.readAsStringSync();
    final frontmatter = _extractFrontmatter(mdContent);
    if (frontmatter == null) {
      _error(report, 'canvas_no_frontmatter', relPath, 'Canvas Markdown file has no frontmatter.');
      return;
    }

    Map<dynamic, dynamic> yaml;
    try {
      final loaded = loadYaml(frontmatter);
      if (loaded is! Map) {
        _error(report, 'canvas_frontmatter_not_map', relPath, 'Canvas frontmatter is not a YAML mapping.');
        return;
      }
      yaml = loaded;
    } catch (e) {
      _error(report, 'canvas_invalid_yaml', relPath, 'Canvas frontmatter is not parseable YAML: $e');
      return;
    }

    final schemaVersion = yaml['schema_version'];
    if (schemaVersion != 3) {
      _error(report, 'canvas_schema_version_invalid', relPath, 'Canvas schema_version must be 3.');
    }
    report.v3Count++;

    final docKind = yaml['document_kind']?.toString() ?? yaml['record_kind']?.toString() ?? '';
    if (docKind != 'canvas') {
      _error(report, 'canvas_document_kind_invalid', relPath, 'Canvas document_kind must be "canvas".');
    }

    final canvasId = yaml['canvas_id']?.toString() ?? '';
    if (canvasId.isEmpty || !canvasId.startsWith('cv_u_')) {
      _error(report, 'canvas_id_invalid', relPath, 'Canvas canvas_id must start with "cv_u_".');
    }

    _requireNonEmptyString(yaml, 'title', relPath, report);

    final layoutRef = yaml['layout_ref']?.toString() ?? '';
    if (layoutRef.isEmpty) {
      _error(report, 'canvas_layout_ref_missing', relPath, 'Canvas layout_ref is required.');
      return;
    }

    final parentDir = File(mdFilePath).parent.path;
    final jsonFilePath = p.normalize(p.join(parentDir, layoutRef));
    final jsonFile = File(jsonFilePath);
    final jsonRelPath = p.relative(jsonFilePath, from: vaultPath).replaceAll('\\', '/');

    if (!jsonFile.existsSync()) {
      _error(report, 'canvas_layout_file_missing', relPath, 'Companion layout JSON file at $layoutRef does not exist.');
      return;
    }

    Map<String, dynamic> json;
    try {
      final jsonContent = jsonFile.readAsStringSync();
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        _error(report, 'canvas_layout_not_map', jsonRelPath, 'layout.json must be a JSON object.');
        return;
      }
      json = decoded;
    } catch (e) {
      _error(report, 'canvas_layout_invalid_json', jsonRelPath, 'layout.json is not parseable JSON: $e');
      return;
    }

    final layoutSchemaVersion = json['layout_schema_version'];
    if (layoutSchemaVersion != 1) {
      _error(report, 'canvas_layout_schema_version_invalid', jsonRelPath, 'layout_schema_version must be 1.');
    }

    final jsonCanvasId = json['canvas_id']?.toString() ?? '';
    if (jsonCanvasId != canvasId) {
      _error(report, 'canvas_id_mismatch', jsonRelPath, 'canvas_id in layout.json ($jsonCanvasId) does not match canvas.md ($canvasId).');
    }

    final layoutMode = json['layout_mode']?.toString() ?? '';
    if (layoutMode != 'freeform' && layoutMode != 'mindmap' && layoutMode != 'graph') {
      _error(report, 'canvas_layout_mode_invalid', jsonRelPath, 'layout_mode must be one of: freeform, mindmap, graph.');
    }

    final nodes = json['nodes'] as List?;
    final nodeIds = <String>{};
    if (nodes != null) {
      for (final node in nodes) {
        if (node is! Map) {
          _error(report, 'canvas_node_not_map', jsonRelPath, 'Each node in nodes array must be a JSON object.');
          continue;
        }
        final nodeId = node['node_id']?.toString() ?? '';
        if (nodeId.isEmpty) {
          _error(report, 'canvas_node_id_empty', jsonRelPath, 'Each node must have a non-empty node_id.');
        } else {
          nodeIds.add(nodeId);
        }
        final kind = node['kind']?.toString() ?? '';
        if (kind != 'entity' && kind != 'record' && kind != 'text' && kind != 'group') {
          _error(report, 'canvas_node_kind_invalid', jsonRelPath, 'Node kind must be one of: entity, record, text, group.');
        }
      }
    }

    final edges = json['edges'] as List?;
    if (edges != null) {
      for (final edge in edges) {
        if (edge is! Map) {
          _error(report, 'canvas_edge_not_map', jsonRelPath, 'Each edge in edges array must be a JSON object.');
          continue;
        }
        final from = edge['from']?.toString() ?? '';
        final to = edge['to']?.toString() ?? '';
        if (from.isEmpty || to.isEmpty) {
          _error(report, 'canvas_edge_endpoint_empty', jsonRelPath, 'Edge endpoints from/to cannot be empty.');
        } else {
          if (!nodeIds.contains(from)) {
            _error(report, 'canvas_edge_from_invalid', jsonRelPath, 'Edge endpoint from "$from" does not refer to a valid node_id.');
          }
          if (!nodeIds.contains(to)) {
            _error(report, 'canvas_edge_to_invalid', jsonRelPath, 'Edge endpoint to "$to" does not refer to a valid node_id.');
          }
        }
        final edgeKind = edge['edge_kind']?.toString() ?? '';
        if (edgeKind != 'canonical_view' && edgeKind != 'canvas_only' && edgeKind != 'candidate') {
          _error(report, 'canvas_edge_kind_invalid', jsonRelPath, 'Edge edge_kind must be one of: canonical_view, canvas_only, candidate.');
        }
        if (edgeKind == 'canonical_view') {
          final ref = edge['link_ref'] as Map?;
          if (ref == null) {
            _error(report, 'canvas_canonical_view_ref_missing', jsonRelPath, 'canonical_view edge must contain a link_ref object.');
          }
        }
      }
    }
  }
}
