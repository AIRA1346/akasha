import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../services/sanctum_image_import.dart';
import '../../theme/akasha_colors.dart';
import '../../theme/akasha_radius.dart';

/// 데스크톱 — 이미지 파일 드래그·드롭 영역.
class SanctumImageDropZone extends StatefulWidget {
  const SanctumImageDropZone({
    super.key,
    required this.child,
    required this.onImagesDropped,
    this.enabled = true,
    this.hint = '이미지를 끌어다 놓으세요',
  });

  final Widget child;
  final Future<void> Function(List<String> relativePaths) onImagesDropped;
  final bool enabled;
  final String hint;

  static const _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.heic',
  };

  @override
  State<SanctumImageDropZone> createState() => _SanctumImageDropZoneState();
}

class _SanctumImageDropZoneState extends State<SanctumImageDropZone> {
  var _dragging = false;

  bool get _dropActive =>
      widget.enabled && SanctumImageImport.canImport && !kIsWeb;

  Future<void> _onDragDone(DropDoneDetails details) async {
    if (!_dropActive) return;

    setState(() => _dragging = false);
    final imported = <String>[];
    for (final item in details.files) {
      final path = item.path;
      if (path.isEmpty) continue;
      final ext = p.extension(path).toLowerCase();
      if (!SanctumImageDropZone._imageExtensions.contains(ext)) continue;

      final relative = await SanctumImageImport.importFilePath(path);
      if (relative != null) imported.add(relative);
    }

    if (imported.isNotEmpty) {
      await widget.onImagesDropped(imported);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dropActive) return widget.child;

    return DropTarget(
      enable: widget.enabled,
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _onDragDone,
      child: Stack(
        children: [
          widget.child,
          if (_dragging)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AkashaColors.accent.withValues(alpha: 0.1),
                  borderRadius: AkashaRadius.mdBorder,
                  border: Border.all(
                    color: AkashaColors.accent.withValues(alpha: 0.65),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.hint,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AkashaColors.accent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
