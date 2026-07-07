import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/archiving/canvas_record.dart';
import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/akasha_item.dart';
import '../../../services/canvas_store.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../dialogs/canvas_archive_search_dialog.dart';
import 'canvas_node_card.dart';

enum CanvasInteractionMode {
  none,
  selectSource,
  selectTarget,
}

class CanvasEditorWorkspace extends StatefulWidget {
  const CanvasEditorWorkspace({
    super.key,
    required this.vaultPath,
    required this.canvasId,
    required this.title,
    required this.localItems,
    required this.onClose,
  });

  final String vaultPath;
  final String canvasId;
  final String title;
  final List<AkashaItem> localItems;
  final VoidCallback onClose;

  @override
  State<CanvasEditorWorkspace> createState() => _CanvasEditorWorkspaceState();
}

class _CanvasEditorWorkspaceState extends State<CanvasEditorWorkspace> {
  CanvasLayout? _layout;
  List<EntityJournalEntry> _entities = [];
  bool _loading = true;

  // Interaction states for connecting nodes
  CanvasInteractionMode _interactionMode = CanvasInteractionMode.none;
  String? _selectedSourceNodeId;

  @override
  void initState() {
    super.initState();
    _loadCanvasData();
  }

  @override
  void dispose() {
    // Flush any pending saves immediately on exit
    if (_layout != null) {
      CanvasStore.instance.flushPendingSave(widget.vaultPath, widget.canvasId, _layout!);
    }
    super.dispose();
  }

  Future<void> _loadCanvasData() async {
    setState(() => _loading = true);
    final data = await CanvasStore.instance.loadCanvas(widget.vaultPath, widget.canvasId);
    if (!mounted) return;

    if (data != null) {
      // Load entities once at dialog/screen mount to avoid subsequent FS lookups
      final entities = await const EntityVaultLoader().loadFromVault(widget.vaultPath);
      if (!mounted) return;

      setState(() {
        _layout = data.layout;
        _entities = entities;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  String _generateTextNodeId() {
    final ms = DateTime.now().microsecondsSinceEpoch;
    final rand = math.Random().nextInt(9000) + 1000; // 1000 ~ 9999
    return 'n_txt_${ms}_$rand';
  }

  String _generateArchiveNodeId(String kind) {
    final prefix = kind == 'work' ? 'w' : 'e';
    final ms = DateTime.now().microsecondsSinceEpoch;
    final rand = math.Random().nextInt(9000) + 1000;
    return 'n_${prefix}_${ms}_$rand';
  }

  String _generateEdgeId() {
    final ms = DateTime.now().microsecondsSinceEpoch;
    final rand = math.Random().nextInt(9000) + 1000;
    return 'e_cv_${ms}_$rand';
  }

  void _addTextNode() {
    if (_layout == null) return;
    
    final offset = _layout!.nodes.length;
    // Modulo 10 cascading offset cascade to prevent overlaps
    final double x = 150.0 + (offset % 10) * 24.0;
    final double y = 150.0 + (offset % 10) * 24.0;

    final newNode = CanvasNode(
      nodeId: _generateTextNodeId(),
      kind: 'text',
      text: '새로운 스티커 메모',
      x: x,
      y: y,
      width: 250,
      height: 100,
    );

    setState(() {
      _layout!.nodes.add(newNode);
      _layout!.updatedAt = DateTime.now().toUtc();
    });

    CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
  }

  Future<void> _addArchiveNode() async {
    if (_layout == null) return;

    final result = await showDialog<CanvasSearchHit>(
      context: context,
      builder: (context) {
        return CanvasArchiveSearchDialog(
          vaultPath: widget.vaultPath,
          localItems: widget.localItems,
        );
      },
    );

    if (result != null && mounted) {
      // Deduplication check to prevent duplicate nodes
      final isDuplicate = _layout!.nodes.any((n) {
        if (result.kind == 'work') {
          return n.kind == 'work' && n.workId == result.id;
        } else {
          return n.kind == 'entity' && n.entityId == result.id;
        }
      });

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 지식 지도에 존재하는 노드입니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final offset = _layout!.nodes.length;
      final double x = 150.0 + (offset % 10) * 24.0;
      final double y = 150.0 + (offset % 10) * 24.0;

      final newNode = CanvasNode(
        nodeId: _generateArchiveNodeId(result.kind),
        kind: result.kind,
        workId: result.kind == 'work' ? result.id : null,
        entityId: result.kind == 'entity' ? result.id : null,
        x: x,
        y: y,
        width: 260,
        height: 90,
      );

      setState(() {
        _layout!.nodes.add(newNode);
        _layout!.updatedAt = DateTime.now().toUtc();
      });

      CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
    }
  }

  void _startConnecting() {
    setState(() {
      _interactionMode = CanvasInteractionMode.selectSource;
      _selectedSourceNodeId = null;
    });
  }

  void _handleNodeTap(CanvasNode node) {
    if (_interactionMode == CanvasInteractionMode.selectSource) {
      setState(() {
        _selectedSourceNodeId = node.nodeId;
        _interactionMode = CanvasInteractionMode.selectTarget;
      });
    } else if (_interactionMode == CanvasInteractionMode.selectTarget) {
      if (_selectedSourceNodeId == node.nodeId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('자기 자신은 연결할 수 없습니다. 다른 노드를 선택해 주세요.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      _showRelationDialog(_selectedSourceNodeId!, node.nodeId);
    }
  }

  Future<void> _showRelationDialog(String sourceId, String targetId) async {
    final controller = TextEditingController();
    final palette = context.akashaPalette;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.surfaceElevated,
          title: Text('관계 선 연결', style: AkashaTypography.headline),
          content: SizedBox(
            width: 400,
            child: TextField(
              controller: controller,
              autofocus: true,
              style: AkashaTypography.body,
              decoration: InputDecoration(
                hintText: '관계명을 입력하세요 (예: 등장인물, 대립관계)...',
                hintStyle: TextStyle(color: AkashaColors.textSecondary),
                filled: true,
                fillColor: palette.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AkashaRadius.sm),
                  borderSide: BorderSide(color: palette.borderSubtle(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AkashaRadius.sm),
                  borderSide: BorderSide(color: palette.accent),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소', style: TextStyle(color: AkashaColors.textSecondary)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: palette.accent),
              child: const Text('연결'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final relation = controller.text.trim();
      final newEdge = CanvasEdge(
        edgeId: _generateEdgeId(),
        from: sourceId,
        to: targetId,
        relation: relation,
        edgeKind: 'canvas_only',
      );

      setState(() {
        _layout!.edges.add(newEdge);
        _layout!.updatedAt = DateTime.now().toUtc();
        _interactionMode = CanvasInteractionMode.none;
        _selectedSourceNodeId = null;
      });

      CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
    } else {
      setState(() {
        _interactionMode = CanvasInteractionMode.none;
        _selectedSourceNodeId = null;
      });
    }
  }

  Widget _buildInteractionBanner(AkashaPalette palette) {
    if (_interactionMode == CanvasInteractionMode.none) {
      return const SizedBox.shrink();
    }

    final String message;
    if (_interactionMode == CanvasInteractionMode.selectSource) {
      message = '관계의 출발지가 될 노드를 마우스로 클릭해 주세요.';
    } else {
      final srcNode = _layout!.nodes.firstWhere((n) => n.nodeId == _selectedSourceNodeId);
      final String name;
      if (srcNode.kind == 'work') {
        final matching = widget.localItems.where((w) => w.workId == srcNode.workId);
        name = matching.isNotEmpty ? matching.first.title : '작품';
      } else if (srcNode.kind == 'entity') {
        final matching = _entities.where((e) => e.entityId == srcNode.entityId);
        name = matching.isNotEmpty ? matching.first.title : '엔티티';
      } else {
        name = srcNode.text ?? '메모';
      }
      message = '[$name]에서 연결할 도착 노드를 선택해 주세요.';
    }

    return Container(
      color: palette.accent.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(
        horizontal: AkashaSpacing.md,
        vertical: AkashaSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: palette.accent),
          const SizedBox(width: AkashaSpacing.xs),
          Text(
            message,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: palette.accent,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _interactionMode = CanvasInteractionMode.none;
                _selectedSourceNodeId = null;
              });
            },
            child: Text(
              '취소',
              style: TextStyle(
                fontSize: 11,
                color: palette.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTextNode(CanvasNode node) async {
    if (node.kind != 'text') return; // only text nodes are editable
    final controller = TextEditingController(text: node.text ?? '');
    final palette = context.akashaPalette;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.surfaceElevated,
          title: Text('메모 수정', style: AkashaTypography.headline),
          content: SizedBox(
            width: 400,
            child: TextField(
              controller: controller,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              autofocus: true,
              style: AkashaTypography.body,
              decoration: InputDecoration(
                hintText: '메모 내용을 입력하세요...',
                hintStyle: TextStyle(color: AkashaColors.textSecondary),
                filled: true,
                fillColor: palette.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AkashaRadius.sm),
                  borderSide: BorderSide(color: palette.borderSubtle(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AkashaRadius.sm),
                  borderSide: BorderSide(color: palette.accent),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소', style: TextStyle(color: AkashaColors.textSecondary)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: palette.accent),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        node.text = controller.text;
        _layout!.updatedAt = DateTime.now().toUtc();
      });
      CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
    }
  }

  Future<void> _deleteNode(CanvasNode node) async {
    final palette = context.akashaPalette;
    final isText = node.kind == 'text';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.surfaceElevated,
          title: Text(isText ? '메모 삭제' : '아카이브 노드 삭제', style: AkashaTypography.headline),
          content: Text(
            isText
                ? '이 메모를 삭제하시겠습니까?\n이 작업은 캔버스에서 제거할 뿐, 원본 파일은 삭제되지 않습니다.'
                : '이 노드를 삭제하시겠습니까?\n이 작업은 캔버스에서 제거할 뿐, 실제 작품/엔티티 원본 파일은 절대 삭제되지 않습니다.',
            style: AkashaTypography.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소', style: TextStyle(color: AkashaColors.textSecondary)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _layout!.nodes.removeWhere((n) => n.nodeId == node.nodeId);
        // Cascade Edge deletion to keep schema constraints clean
        _layout!.edges.removeWhere((e) => e.from == node.nodeId || e.to == node.nodeId);
        _layout!.updatedAt = DateTime.now().toUtc();
      });
      CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;

    return Container(
      color: palette.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Workspace header with close tab and add nodes buttons
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AkashaSpacing.md,
              vertical: AkashaSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: palette.sidebar,
              border: Border(
                bottom: BorderSide(
                  color: palette.borderSubtle(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose,
                  tooltip: '탭 닫기',
                ),
                const SizedBox(width: AkashaSpacing.xs),
                Text(
                  widget.title,
                  style: AkashaTypography.dashboardPanelTitle,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _interactionMode == CanvasInteractionMode.none ? _startConnecting : null,
                  icon: Icon(Icons.hub_outlined, size: 16, color: palette.accent),
                  label: Text(
                    '관계 연결',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.accent,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AkashaSpacing.sm,
                      vertical: AkashaSpacing.xs,
                    ),
                  ),
                ),
                const SizedBox(width: AkashaSpacing.xs),
                TextButton.icon(
                  onPressed: _interactionMode == CanvasInteractionMode.none ? _addArchiveNode : null,
                  icon: const Icon(Icons.archive_outlined, size: 16, color: Colors.tealAccent),
                  label: const Text(
                    '아카이브 추가',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AkashaSpacing.sm,
                      vertical: AkashaSpacing.xs,
                    ),
                  ),
                ),
                const SizedBox(width: AkashaSpacing.xs),
                TextButton.icon(
                  onPressed: _interactionMode == CanvasInteractionMode.none ? _addTextNode : null,
                  icon: Icon(Icons.add_comment_outlined, size: 16, color: palette.accent),
                  label: Text(
                    '메모 추가',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.accent,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AkashaSpacing.sm,
                      vertical: AkashaSpacing.xs,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildInteractionBanner(palette),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _layout == null
                    ? const Center(child: Text('캔버스 데이터를 불러올 수 없습니다.'))
                    : Stack(
                        children: [
                          if (_layout!.nodes.isNotEmpty)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: CanvasEdgePainter(
                                  layout: _layout!,
                                  nodes: _layout!.nodes,
                                  palette: palette,
                                ),
                              ),
                            ),
                          ..._layout!.nodes.map((node) => _buildNodeWidget(node, palette)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeWidget(CanvasNode node, AkashaPalette palette) {
    final bool isSelected = _selectedSourceNodeId == node.nodeId;
    final bool isConnectingMode = _interactionMode != CanvasInteractionMode.none;

    return Positioned(
      left: node.x,
      top: node.y,
      child: GestureDetector(
        onTap: isConnectingMode ? () => _handleNodeTap(node) : null,
        onPanUpdate: (details) {
          if (isConnectingMode) return; // disable dragging during connection mode
          setState(() {
            node.x += details.delta.dx;
            node.y += details.delta.dy;
          });
          // Update layout.updatedAt on drag
          _layout!.updatedAt = DateTime.now().toUtc();
          // Call debounced save on every coordinate change
          CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AkashaRadius.md),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: CanvasNodeCard(
            node: node,
            localItems: widget.localItems,
            entities: _entities,
            vaultPath: widget.vaultPath,
            palette: palette,
            onEdit: () => _editTextNode(node),
            onDelete: () => _deleteNode(node),
          ),
        ),
      ),
    );
  }
}

class CanvasEdgePainter extends CustomPainter {
  final CanvasLayout layout;
  final List<CanvasNode> nodes;
  final AkashaPalette palette;

  CanvasEdgePainter({
    required this.layout,
    required this.nodes,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = palette.borderSubtle(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final edge in layout.edges) {
      final fromNode = _findNode(edge.from);
      final toNode = _findNode(edge.to);
      if (fromNode == null || toNode == null) continue;

      final fromW = fromNode.width ?? (fromNode.kind == 'text' ? 250.0 : 260.0);
      final fromH = fromNode.height ?? (fromNode.kind == 'text' ? 100.0 : 90.0);
      final toW = toNode.width ?? (toNode.kind == 'text' ? 250.0 : 260.0);
      final toH = toNode.height ?? (toNode.kind == 'text' ? 100.0 : 90.0);

      final fromCenter = Offset(fromNode.x + fromW / 2, fromNode.y + fromH / 2);
      final toCenter = Offset(toNode.x + toW / 2, toNode.y + toH / 2);

      // Draw relation line
      canvas.drawLine(fromCenter, toCenter, paint);

      // Draw relation label in the middle
      final rel = edge.relation;
      if (rel != null && rel.isNotEmpty) {
        _drawRelationLabel(canvas, rel, fromCenter, toCenter);
      }
    }
  }

  CanvasNode? _findNode(String nodeId) {
    final matching = nodes.where((n) => n.nodeId == nodeId);
    return matching.isNotEmpty ? matching.first : null;
  }

  void _drawRelationLabel(Canvas canvas, String text, Offset from, Offset to) {
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 9.0,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgW = textPainter.width + 12.0;
    final bgH = textPainter.height + 6.0;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: mid, width: bgW, height: bgH),
      const Radius.circular(4.0),
    );

    // Draw background label box
    final bgPaint = Paint()..color = const Color(0xFF1E1E2F);
    canvas.drawRRect(bgRect, bgPaint);

    // Draw border around label
    final borderPaint = Paint()
      ..color = palette.borderSubtle(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bgRect, borderPaint);

    // Draw text centered
    textPainter.paint(
      canvas,
      Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CanvasEdgePainter oldDelegate) {
    return true; // Repaint whenever Stack updates
  }
}
