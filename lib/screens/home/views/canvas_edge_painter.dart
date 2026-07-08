import 'package:flutter/material.dart';

import '../../../core/archiving/canvas_record.dart';
import '../../../theme/akasha_palette.dart';

class CanvasEdgePainter extends CustomPainter {
  final CanvasLayout layout;
  final List<CanvasNode> nodes;
  final AkashaPalette palette;
  final double workspaceOrigin;

  CanvasEdgePainter({
    required this.layout,
    required this.nodes,
    required this.palette,
    required this.workspaceOrigin,
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

      final fromCenter = Offset(workspaceOrigin + fromNode.x + fromW / 2, workspaceOrigin + fromNode.y + fromH / 2);
      final toCenter = Offset(workspaceOrigin + toNode.x + toW / 2, workspaceOrigin + toNode.y + toH / 2);

      // Draw relation line
      canvas.drawLine(fromCenter, toCenter, paint);
    }
  }

  CanvasNode? _findNode(String nodeId) {
    final matching = nodes.where((n) => n.nodeId == nodeId);
    return matching.isNotEmpty ? matching.first : null;
  }

  @override
  bool shouldRepaint(covariant CanvasEdgePainter oldDelegate) {
    return true; // Always repaint when node coordinates update
  }
}
