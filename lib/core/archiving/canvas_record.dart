import 'package:yaml/yaml.dart';
import 'archive_record_contract.dart';

/// Canvas Record model representing the YAML metadata file (canvas.md).
class CanvasRecord {
  CanvasRecord({
    required this.canvasId,
    required this.slug,
    required this.title,
    required this.layoutRef,
    required this.createdAt,
    required this.updatedAt,
    required this.source,
    required this.tags,
    this.body = '',
  });

  final String canvasId;
  final String slug;
  final String title;
  final String layoutRef;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source;
  final List<String> tags;
  final String body;

  /// Parses a CanvasRecord from the raw markdown string.
  static CanvasRecord? fromMarkdown(String content) {
    final frontmatterIndex = content.indexOf('---');
    if (frontmatterIndex == -1) return null;
    final secondFrontmatterIndex = content.indexOf('---', frontmatterIndex + 3);
    if (secondFrontmatterIndex == -1) return null;

    final yamlString = content.substring(frontmatterIndex + 3, secondFrontmatterIndex);
    final body = content.substring(secondFrontmatterIndex + 3).trim();

    final doc = loadYaml(yamlString);
    if (doc is! Map) return null;

    final documentKind = doc['document_kind']?.toString() ?? doc['record_kind']?.toString() ?? '';
    if (documentKind != 'canvas') return null;

    final canvasId = doc['canvas_id']?.toString() ?? '';
    if (canvasId.isEmpty) return null;

    final slug = doc['slug']?.toString() ?? '';
    final title = doc['title']?.toString() ?? '';
    final layoutRef = doc['layout_ref']?.toString() ?? '';
    final createdAt = ArchiveRecordContract.parseSystemTimestamp(doc['created_at']) ?? DateTime.now().toUtc();
    final updatedAt = ArchiveRecordContract.parseSystemTimestamp(doc['updated_at']) ?? DateTime.now().toUtc();
    final source = doc['source']?.toString() ?? 'user';
    final tags = (doc['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return CanvasRecord(
      canvasId: canvasId,
      slug: slug,
      title: title,
      layoutRef: layoutRef,
      createdAt: createdAt,
      updatedAt: updatedAt,
      source: source,
      tags: tags,
      body: body,
    );
  }

  /// Serializes CanvasRecord back to markdown string with YAML frontmatter.
  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('schema_version: 3')
      ..writeln('document_kind: "canvas"')
      ..writeln('canvas_id: "$canvasId"')
      ..writeln('slug: "$slug"')
      ..writeln('title: "$title"')
      ..writeln('layout_ref: "$layoutRef"')
      ..writeln('created_at: "${ArchiveRecordContract.formatSystemTimestamp(createdAt)}"')
      ..writeln('updated_at: "${ArchiveRecordContract.formatSystemTimestamp(updatedAt)}"')
      ..writeln('source: "$source"');

    if (tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in tags) {
        buffer.writeln('  - "$tag"');
      }
    }
    buffer
      ..writeln('---')
      ..writeln()
      ..writeln(body);

    return buffer.toString();
  }
}

/// Canvas Layout model representing the JSON positioning file (layout.json).
class CanvasLayout {
  CanvasLayout({
    required this.layoutSchemaVersion,
    required this.canvasId,
    required this.updatedAt,
    required this.source,
    required this.layoutMode,
    required this.viewport,
    required this.nodes,
    required this.edges,
  });

  final int layoutSchemaVersion;
  final String canvasId;
  final DateTime updatedAt;
  final String source;
  final String layoutMode;
  final CanvasViewport viewport;
  final List<CanvasNode> nodes;
  final List<CanvasEdge> edges;

  factory CanvasLayout.fromJson(Map<String, dynamic> json) {
    final viewportJson = json['viewport'] as Map<String, dynamic>? ?? {};
    final nodesJson = json['nodes'] as List? ?? [];
    final edgesJson = json['edges'] as List? ?? [];

    return CanvasLayout(
      layoutSchemaVersion: json['layout_schema_version'] as int? ?? 1,
      canvasId: json['canvas_id']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      source: json['source']?.toString() ?? 'user',
      layoutMode: json['layout_mode']?.toString() ?? 'freeform',
      viewport: CanvasViewport.fromJson(viewportJson),
      nodes: nodesJson
          .map((n) => CanvasNode.fromJson(Map<String, dynamic>.from(n)))
          .toList(),
      edges: edgesJson
          .map((e) => CanvasEdge.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'layout_schema_version': layoutSchemaVersion,
      'canvas_id': canvasId,
      'updated_at': updatedAt.toIso8601String(),
      'source': source,
      'layout_mode': layoutMode,
      'viewport': viewport.toJson(),
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
    };
  }
}

class CanvasViewport {
  CanvasViewport({required this.x, required this.y, required this.zoom});

  final double x;
  final double y;
  final double zoom;

  factory CanvasViewport.fromJson(Map<String, dynamic> json) {
    return CanvasViewport(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'zoom': zoom};
}

class CanvasNode {
  CanvasNode({
    required this.nodeId,
    required this.kind,
    this.entityId,
    this.recordId,
    this.text,
    required this.x,
    required this.y,
    this.width,
    this.height,
    this.pinned = false,
    this.collapsed = false,
    this.promotedRecordId,
  });

  final String nodeId;
  final String kind; // 'entity', 'record', 'text', 'group'
  final String? entityId;
  final String? recordId;
  final String? text;
  double x;
  double y;
  final double? width;
  final double? height;
  final bool pinned;
  final bool collapsed;
  final String? promotedRecordId;

  factory CanvasNode.fromJson(Map<String, dynamic> json) {
    return CanvasNode(
      nodeId: json['node_id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      entityId: json['entity_id']?.toString(),
      recordId: json['record_id']?.toString(),
      text: json['text']?.toString(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      pinned: json['pinned'] as bool? ?? false,
      collapsed: json['collapsed'] as bool? ?? false,
      promotedRecordId: json['promoted_record_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node_id': nodeId,
      'kind': kind,
      if (entityId != null) 'entity_id': entityId,
      if (recordId != null) 'record_id': recordId,
      if (text != null) 'text': text,
      'x': x,
      'y': y,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'pinned': pinned,
      'collapsed': collapsed,
      if (promotedRecordId != null) 'promoted_record_id': promotedRecordId,
    };
  }
}

class CanvasEdge {
  CanvasEdge({
    required this.edgeId,
    required this.from,
    required this.to,
    this.relation,
    required this.edgeKind, // 'canonical_view', 'canvas_only', 'candidate'
    this.visible = true,
    this.linkRef,
    this.createdAt,
  });

  final String edgeId;
  final String from;
  final String to;
  final String? relation;
  final String edgeKind;
  final bool visible;
  final CanvasLinkRef? linkRef;
  final DateTime? createdAt;

  factory CanvasEdge.fromJson(Map<String, dynamic> json) {
    final refJson = json['link_ref'] as Map<String, dynamic>?;
    return CanvasEdge(
      edgeId: json['edge_id']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      relation: json['relation']?.toString(),
      edgeKind: json['edge_kind']?.toString() ?? '',
      visible: json['visible'] as bool? ?? true,
      linkRef: refJson != null ? CanvasLinkRef.fromJson(refJson) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'edge_id': edgeId,
      'from': from,
      'to': to,
      if (relation != null && edgeKind != 'canonical_view') 'relation': relation,
      'edge_kind': edgeKind,
      'visible': visible,
      if (linkRef != null) 'link_ref': linkRef!.toJson(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class CanvasLinkRef {
  CanvasLinkRef({
    this.linkId,
    this.ownerId,
    this.targetId,
    this.relation,
  });

  final String? linkId;
  final String? ownerId;
  final String? targetId;
  final String? relation;

  factory CanvasLinkRef.fromJson(Map<String, dynamic> json) {
    return CanvasLinkRef(
      linkId: json['link_id']?.toString(),
      ownerId: json['owner_id']?.toString(),
      targetId: json['target_id']?.toString(),
      relation: json['relation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (linkId != null) 'link_id': linkId,
      if (ownerId != null) 'owner_id': ownerId,
      if (targetId != null) 'target_id': targetId,
      if (relation != null) 'relation': relation,
    };
  }
}
