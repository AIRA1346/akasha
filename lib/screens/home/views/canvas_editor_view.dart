import 'package:flutter/material.dart';

import '../../../core/archiving/canvas_record.dart';
import '../../../services/canvas_store.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';

class CanvasEditorWorkspace extends StatefulWidget {
  const CanvasEditorWorkspace({
    super.key,
    required this.vaultPath,
    required this.canvasId,
    required this.title,
    required this.onClose,
  });

  final String vaultPath;
  final String canvasId;
  final String title;
  final VoidCallback onClose;

  @override
  State<CanvasEditorWorkspace> createState() => _CanvasEditorWorkspaceState();
}

class _CanvasEditorWorkspaceState extends State<CanvasEditorWorkspace> {
  CanvasLayout? _layout;
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
      setState(() {
        _layout = data.layout;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
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
          // Workspace header with close tab button
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
          // Call debounced save on every coordinate change
          CanvasStore.instance.saveLayoutDebounced(widget.vaultPath, widget.canvasId, _layout!);
        },
        child: Container(
          width: node.width ?? 200,
          height: node.height ?? 80,
          padding: const EdgeInsets.all(AkashaSpacing.md),
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(AkashaRadius.md),
            border: Border.all(color: palette.borderSubtle(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.note_alt_outlined, size: 14, color: palette.accent),
                  const SizedBox(width: AkashaSpacing.xs),
                  Text(
                    '메모',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AkashaSpacing.xs),
              Expanded(
                child: Text(
                  node.text ?? '',
                  style: AkashaTypography.body.copyWith(fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
