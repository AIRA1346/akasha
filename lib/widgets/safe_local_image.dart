import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Windows 환경에서 한글 등 Non-ASCII 문자 경로가 포함된 파일명을 로드할 때
/// Flutter의 Image.file이 네이티브 레벨에서 디스크 경로를 찾지 못하고 로드 실패하는 현상을 방지하기 위해
/// Dart VM 단에서 File.readAsBytes()로 안전하게 바이너리를 읽어와 Image.memory로 렌더링하는 위젯입니다.
class SafeLocalImage extends StatefulWidget {
  final File file;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const SafeLocalImage({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  State<SafeLocalImage> createState() => _SafeLocalImageState();
}

class _SafeLocalImageState extends State<SafeLocalImage> {
  Uint8List? _bytes;
  Object? _error;
  StackTrace? _stackTrace;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  @override
  void didUpdateWidget(SafeLocalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _loadBytes();
    }
  }

  Future<void> _loadBytes() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _bytes = null;
      _error = null;
      _stackTrace = null;
    });

    try {
      final exists = await widget.file.exists();
      if (!exists) {
        throw FileSystemException('File does not exist', widget.file.path);
      }
      final bytes = await widget.file.readAsBytes();
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = e;
          _stackTrace = st;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // 로딩 중일 때는 errorBuilder 호출 대신 임시로 빈 위젯 렌더링
      return const SizedBox.shrink();
    }

    if (_error != null || _bytes == null || _bytes!.isEmpty) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(
          context,
          _error ?? Exception('Invalid or empty image bytes'),
          _stackTrace,
        );
      }
      return const SizedBox.shrink();
    }

    return Image.memory(
      _bytes!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: widget.errorBuilder,
    );
  }
}
