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
        width: 250,
        height: 80,
      );

      setState(() {
        _layout!.nodes.add(newNode);
        _layout!.updatedAt = DateTime.now().toUtc();
      });

      CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
    }
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
                  onPressed: _addArchiveNode,
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
                  onPressed: _addTextNode,
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _layout == null
                    ? const Center(child: Text('캔버스 데이터를 불러올 수 없습니다.'))
                    : Stack(
                        children: _layout!.nodes.map((node) => _buildNodeWidget(node, palette)).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeWidget(CanvasNode node, AkashaPalette palette) {
    return Positioned(
      left: node.x,
      top: node.y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            node.x += details.delta.dx;
            node.y += details.delta.dy;
          });
          // Update layout.updatedAt on drag
          _layout!.updatedAt = DateTime.now().toUtc();
          // Call debounced save on every coordinate change
          CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
        },
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
    );
  }
}
