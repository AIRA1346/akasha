import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/archiving/canvas_record.dart';
import '../../../core/archiving/relation_vocabulary.dart';
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
import 'canvas_edge_painter.dart';
import 'canvas_editor_modes.dart';
import 'canvas_node_card.dart';
import 'canvas_viewport_controls.dart';
import 'canvas_viewport_surface.dart';

class CanvasEditorWorkspace extends StatefulWidget {
  const CanvasEditorWorkspace({
    super.key,
    required this.vaultPath,
    required this.canvasId,
    required this.title,
    required this.localItems,
    required this.onClose,
    this.onOpenWork,
    this.onOpenEntity,
    this.onBindFlushViewport,
  });

  final String vaultPath;
  final String canvasId;
  final String title;
  final List<AkashaItem> localItems;
  final VoidCallback onClose;
  final void Function(AkashaItem item)? onOpenWork;
  final Future<bool> Function(String entityId)? onOpenEntity;
  final void Function(Future<void> Function()? flush)? onBindFlushViewport;

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
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _canvasViewportKey = GlobalKey(debugLabel: 'canvas_viewport');

  // State variables for tracking node dragging in Scene coordinates (v0.3-A.2)
  Offset? _dragStartSceneOffset;
  double? _dragStartNodeX;
  double? _dragStartNodeY;

  // Focus node for keyboard shortcuts listener (v0.3-A.3)
  bool _suppressViewportListener = false;

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      final isSpace = event.logicalKey == LogicalKeyboardKey.space;
      if (isCtrl && isSpace) {
        _fitToContent();
        return true; // handled
      }
    }
    return false; // not handled
  }

  @override
  void initState() {
    super.initState();
    _loadCanvasData();
    _transformationController.addListener(_handleViewportChange);
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    widget.onBindFlushViewport?.call(null);
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _transformationController.removeListener(_handleViewportChange);
    if (_layout != null) {
      _applyViewportFromController();
      _syncLayoutToStore();
    }
    _transformationController.dispose();
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

      // Restore viewport (Condition 6: translate then scale)
      final vp = data.layout.viewport;
      _suppressViewportListener = true;
      _transformationController.value = canvasMatrixFromViewport(vp);
      _suppressViewportListener = false;

      _syncLayoutToStore();
      widget.onBindFlushViewport?.call(_persistViewportBeforeNavigation);
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
    final palette = context.akashaPalette;
    
    // Combine core relations and recommended preset relations into a single list
    final List<String> availableTokens = [
      ...RelationVocabulary.core,
      ...RelationVocabulary.recommendedCanvasRelations,
    ];

    String selectedToken = 'related'; // Default selection
    bool isCustom = false;
    final customController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.surfaceElevated,
              title: Text('관계 선 연결', style: AkashaTypography.headline),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('노드 간의 관계 유형을 선택해 주세요:', style: TextStyle(color: AkashaColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: AkashaSpacing.xs),
                    DropdownButtonFormField<String>(
                      dropdownColor: palette.surfaceElevated,
                      initialValue: isCustom ? 'custom' : selectedToken,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: palette.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AkashaRadius.sm),
                          borderSide: BorderSide(color: palette.borderSubtle(0.3)),
                        ),
                      ),
                      style: AkashaTypography.body,
                      items: [
                        ...availableTokens.map((token) => DropdownMenuItem<String>(
                              value: token,
                              child: Text(RelationVocabulary.displayLabelFor(token)),
                            )),
                        const DropdownMenuItem<String>(
                          value: 'custom',
                          child: Text('직접 입력...'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            if (val == 'custom') {
                              isCustom = true;
                            } else {
                              isCustom = false;
                              selectedToken = val;
                            }
                          });
                        }
                      },
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: AkashaSpacing.md),
                      Text(
                        '사용자 정의 관계 토큰 입력 (예: u:likes, u:teacher_of)',
                        style: TextStyle(color: AkashaColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: AkashaSpacing.xs),
                      TextField(
                        controller: customController,
                        autofocus: true,
                        style: AkashaTypography.body,
                        decoration: InputDecoration(
                          hintText: 'u:relation_name',
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
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('취소', style: TextStyle(color: AkashaColors.textSecondary)),
                ),
                FilledButton(
                  onPressed: () {
                    if (isCustom) {
                      final input = customController.text.trim();
                      final formatted = _sanitizeAndValidateUserRelation(input);
                      if (formatted == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '올바르지 않은 사용자 관계 토큰 형식입니다. 소문자, 숫자, 언더바만 가능합니다 (예: u:rival_of).'
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      selectedToken = formatted;
                    }
                    Navigator.pop(context, true);
                  },
                  style: FilledButton.styleFrom(backgroundColor: palette.accent),
                  child: const Text('연결'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final newEdge = CanvasEdge(
        edgeId: _generateEdgeId(),
        from: sourceId,
        to: targetId,
        relation: selectedToken,
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

  String? _sanitizeAndValidateUserRelation(String input) {
    if (input.isEmpty) return null;
    
    // Check if input contains any Korean letters or illegal symbols (spaces, punctuation other than colon and underscore)
    // We only allow ascii lowercase letters, numbers, colons, underscores, spaces, or hyphens (spaces/hyphens will be sanitized).
    // If it contains Korean or symbols like ?, !, @, etc, we reject it.
    if (RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣]').hasMatch(input)) {
      return null;
    }
    
    var token = input.trim().toLowerCase();
    
    // Auto-prefix if missing
    if (!token.startsWith('u:')) {
      token = 'u:$token';
    }
    
    // Sanitize spaces/hyphens to underscores
    token = token.replaceAll(' ', '_').replaceAll('-', '_');
    
    // Strip other illegal characters
    token = token.replaceAll(RegExp(r'[^a-z0-9_:]'), '');

    // Validate using the strict RelationVocabulary namespace pattern
    if (RelationVocabulary.isUserNamespaced(token)) {
      return token;
    }
    
    return null;
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
                  onPressed: _fitToContent,
                  icon: const Icon(Icons.fullscreen, size: 16, color: Colors.amberAccent),
                  label: const Text(
                    '전체 노드 보기',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
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
                    : CanvasViewportSurface(
                        transformationController: _transformationController,
                        viewportKey: _canvasViewportKey,
                        onInteractionEnd: _handleViewportChange,
                        child: SizedBox(
                          width: CanvasEditorViewportConfig.workspaceSize,
                          height: CanvasEditorViewportConfig.workspaceSize,
                          child: uiStack(palette),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget uiStack(AkashaPalette palette) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_layout!.nodes.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: CanvasEdgePainter(
                layout: _layout!,
                nodes: _layout!.nodes,
                palette: palette,
                workspaceOrigin: CanvasEditorViewportConfig.workspaceOrigin,
              ),
            ),
          ),
        ..._layout!.edges.map((edge) => _buildEdgeLabelWidget(edge, palette)),
        ..._layout!.nodes.map((node) => _buildNodeWidget(node, palette)),
      ],
    );
  }

  void _syncLayoutToStore() {
    if (_layout == null) return;
    CanvasStore.instance.registerLayoutSession(
      widget.vaultPath,
      widget.canvasId,
      _layout!,
    );
  }

  /// Syncs [_layout.viewport] from the current transformation matrix.
  /// Returns true when the viewport value changed.
  bool _applyViewportFromController() {
    if (_layout == null) return false;
    final delta = canvasViewportDeltaFromMatrix(
      _transformationController.value,
      _layout!.viewport,
    );
    if (delta == null) return false;
    _layout!.viewport = delta;
    _layout!.updatedAt = DateTime.now().toUtc();
    _syncLayoutToStore();
    return true;
  }

  void _handleViewportChange() {
    if (_layout == null || _suppressViewportListener) return;
    if (!_applyViewportFromController()) return;
    CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
  }

  RenderBox? _canvasViewportRenderBox() {
    return _canvasViewportKey.currentContext?.findRenderObject() as RenderBox?;
  }

  /// Persists the current viewport to disk before leaving Canvas (e.g. opening Work/Entity).
  Future<void> _persistViewportBeforeNavigation() async {
    if (_layout == null) return;
    _applyViewportFromController();
    await CanvasStore.instance.flushPendingSave(
      widget.vaultPath,
      widget.canvasId,
      _layout!,
      force: true,
    );
  }

  void _fitToContent() {
    if (_layout == null || !mounted) return;
    _suppressViewportListener = true;
    _transformationController.value = computeCanvasFitToContentMatrix(
      nodes: _layout!.nodes,
      viewportSize: MediaQuery.sizeOf(context),
    );
    _suppressViewportListener = false;
    _applyViewportFromController();
    CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
  }

  Widget _buildEdgeLabelWidget(CanvasEdge edge, AkashaPalette palette) {
    final fromNode = _findNode(edge.from);
    final toNode = _findNode(edge.to);
    
    // Condition 5: Safe skip if from/to node is missing
    if (fromNode == null || toNode == null) return const SizedBox.shrink();

    // Condition 4: Calculate midpoint using current node x/y/width/height (default or custom)
    final fromW = canvasDefaultNodeWidth(fromNode);
    final fromH = canvasDefaultNodeHeight(fromNode);
    final toW = canvasDefaultNodeWidth(toNode);
    final toH = canvasDefaultNodeHeight(toNode);

    final fromCenter = Offset(
      CanvasEditorViewportConfig.workspaceOrigin + fromNode.x + fromW / 2,
      CanvasEditorViewportConfig.workspaceOrigin + fromNode.y + fromH / 2,
    );
    final toCenter = Offset(
      CanvasEditorViewportConfig.workspaceOrigin + toNode.x + toW / 2,
      CanvasEditorViewportConfig.workspaceOrigin + toNode.y + toH / 2,
    );

    final mid = Offset((fromCenter.dx + toCenter.dx) / 2, (fromCenter.dy + toCenter.dy) / 2);

    final rel = edge.relation;
    if (rel == null || rel.isEmpty) return const SizedBox.shrink();

    final labelText = RelationVocabulary.displayLabelFor(rel);

    return Positioned(
      left: mid.dx,
      top: mid.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: edge.edgeKind == 'canvas_only' ? () => _showEdgeEditDialog(edge) : null,
          child: MouseRegion(
            cursor: edge.edgeKind == 'canvas_only' ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2F),
                borderRadius: BorderRadius.circular(AkashaRadius.sm),
                border: Border.all(color: palette.borderSubtle(0.3), width: 1.0),
              ),
              child: Text(
                labelText,
                style: const TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  CanvasNode? _findNode(String nodeId) {
    if (_layout == null) return null;
    final matching = _layout!.nodes.where((n) => n.nodeId == nodeId);
    return matching.isNotEmpty ? matching.first : null;
  }

  Future<void> _showEdgeEditDialog(CanvasEdge edge) async {
    // Only allow editing canvas_only edges (Condition 1)
    if (edge.edgeKind != 'canvas_only') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('공식 수립된 관계선은 캔버스에서 직접 수정할 수 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final palette = context.akashaPalette;
    
    // Combine core relations and recommended preset relations into a single list
    final List<String> availableTokens = [
      ...RelationVocabulary.core,
      ...RelationVocabulary.recommendedCanvasRelations,
    ];

    final currentRelation = edge.relation ?? 'related';
    // If current relation is not in the list, it's a custom unknown token
    final bool isCustomInitially = !availableTokens.contains(currentRelation);

    String selectedToken = isCustomInitially ? 'custom' : currentRelation;
    bool isCustom = isCustomInitially;
    final customController = TextEditingController(text: isCustomInitially ? currentRelation : '');

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.surfaceElevated,
              title: Text('관계 편집', style: AkashaTypography.headline),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('노드 간의 관계 유형을 선택해 주세요:', style: TextStyle(color: AkashaColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: AkashaSpacing.xs),
                    DropdownButtonFormField<String>(
                      dropdownColor: palette.surfaceElevated,
                      initialValue: selectedToken,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: palette.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AkashaRadius.sm),
                          borderSide: BorderSide(color: palette.borderSubtle(0.3)),
                        ),
                      ),
                      style: AkashaTypography.body,
                      items: [
                        ...availableTokens.map((token) => DropdownMenuItem<String>(
                              value: token,
                              child: Text(RelationVocabulary.displayLabelFor(token)),
                            )),
                        const DropdownMenuItem<String>(
                          value: 'custom',
                          child: Text('직접 입력...'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            if (val == 'custom') {
                              isCustom = true;
                              selectedToken = 'custom';
                            } else {
                              isCustom = false;
                              selectedToken = val;
                            }
                          });
                        }
                      },
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: AkashaSpacing.md),
                      Text(
                        '사용자 정의 관계 토큰 입력 (예: u:likes, u:teacher_of)',
                        style: TextStyle(color: AkashaColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: AkashaSpacing.xs),
                      TextField(
                        controller: customController,
                        autofocus: true,
                        style: AkashaTypography.body,
                        decoration: InputDecoration(
                          hintText: 'u:relation_name',
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
                    ],
                    const SizedBox(height: AkashaSpacing.lg),
                    Row(
                      children: [
                        // DELETE button on the left (Condition 9: with confirm prompt)
                        TextButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final deleteConfirm = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: palette.surfaceElevated,
                                  title: Text('관계선 삭제', style: AkashaTypography.headline),
                                  content: const Text('이 관계선을 삭제할까요?\n이 작업은 캔버스에서 제거할 뿐, 원본 파일은 변경되지 않습니다.'),
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
                            if (deleteConfirm == true && mounted) {
                              // Remove edge
                              setState(() {
                                _layout!.edges.removeWhere((e) => e.edgeId == edge.edgeId);
                                _layout!.updatedAt = DateTime.now().toUtc();
                              });
                              CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
                              // Close the parent edit dialog
                              navigator.pop(false);
                            }
                          },
                          child: const Text('삭제', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('취소', style: TextStyle(color: AkashaColors.textSecondary)),
                        ),
                        const SizedBox(width: AkashaSpacing.xs),
                        FilledButton(
                          onPressed: () {
                            String finalRelation = selectedToken;
                            if (isCustom) {
                              final input = customController.text.trim();
                              final formatted = _sanitizeAndValidateUserRelation(input);
                              if (formatted == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '올바르지 않은 사용자 관계 토큰 형식입니다. 소문자, 숫자, 언더바만 가능합니다 (예: u:rival_of).'
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              finalRelation = formatted;
                            }
                            // Update and save
                            setState(() {
                              final targetEdgeIndex = _layout!.edges.indexWhere((e) => e.edgeId == edge.edgeId);
                              if (targetEdgeIndex != -1) {
                                _layout!.edges[targetEdgeIndex] = CanvasEdge(
                                  edgeId: edge.edgeId,
                                  from: edge.from,
                                  to: edge.to,
                                  relation: finalRelation,
                                  edgeKind: edge.edgeKind,
                                  visible: edge.visible,
                                  linkRef: edge.linkRef,
                                  createdAt: edge.createdAt,
                                );
                                _layout!.updatedAt = DateTime.now().toUtc();
                              }
                            });
                            CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
                            Navigator.pop(context, true);
                          },
                          style: FilledButton.styleFrom(backgroundColor: palette.accent),
                          child: const Text('저장'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showArchiveNodeMissingSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('아카이브에서 해당 항목을 찾을 수 없습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleNodeDoubleTap(CanvasNode node) async {
    if (_interactionMode != CanvasInteractionMode.none) return;

    if (node.kind == 'work') {
      final workId = node.workId;
      if (workId == null || workId.isEmpty) {
        _showArchiveNodeMissingSnackBar();
        return;
      }
      AkashaItem? work;
      for (final item in widget.localItems) {
        if (item.workId == workId) {
          work = item;
          break;
        }
      }
      if (work == null) {
        _showArchiveNodeMissingSnackBar();
        return;
      }
      await _persistViewportBeforeNavigation();
      if (!mounted) return;
      widget.onOpenWork?.call(work);
      return;
    }

    if (node.kind == 'entity') {
      final entityId = node.entityId;
      if (entityId == null || entityId.isEmpty) {
        _showArchiveNodeMissingSnackBar();
        return;
      }
      await _persistViewportBeforeNavigation();
      if (!mounted) return;
      final opened = await widget.onOpenEntity?.call(entityId) ?? false;
      if (!opened && mounted) {
        _showArchiveNodeMissingSnackBar();
      }
    }
  }

  Widget _buildNodeWidget(CanvasNode node, AkashaPalette palette) {
    final bool isSelected = _selectedSourceNodeId == node.nodeId;
    final bool isConnectingMode = _interactionMode != CanvasInteractionMode.none;

    return Positioned(
      left: CanvasEditorViewportConfig.workspaceOrigin + node.x,
      top: CanvasEditorViewportConfig.workspaceOrigin + node.y,
      child: GestureDetector(
        onTap: isConnectingMode ? () => _handleNodeTap(node) : null,
        onDoubleTap: isConnectingMode ? null : () => _handleNodeDoubleTap(node),
        onPanStart: (details) {
          if (isConnectingMode) return;
          final viewportBox = _canvasViewportRenderBox();
          if (viewportBox == null) return;
          final localOffset = viewportBox.globalToLocal(details.globalPosition);
          _dragStartSceneOffset = _transformationController.toScene(localOffset);
          _dragStartNodeX = node.x;
          _dragStartNodeY = node.y;
        },
        onPanUpdate: (details) {
          if (isConnectingMode) return;
          if (_dragStartSceneOffset == null || _dragStartNodeX == null || _dragStartNodeY == null) return;

          final viewportBox = _canvasViewportRenderBox();
          if (viewportBox == null) return;
          final localOffset = viewportBox.globalToLocal(details.globalPosition);
          final currentSceneOffset = _transformationController.toScene(localOffset);

          final dx = currentSceneOffset.dx - _dragStartSceneOffset!.dx;
          final dy = currentSceneOffset.dy - _dragStartSceneOffset!.dy;

          setState(() {
            node.x = _dragStartNodeX! + dx;
            node.y = _dragStartNodeY! + dy;
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


