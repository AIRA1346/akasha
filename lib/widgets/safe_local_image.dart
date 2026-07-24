import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Windows 환경에서 한글 등 Non-ASCII 문자 경로가 포함된 파일명을 로드할 때
/// Flutter의 Image.file이 네이티브 레벨에서 디스크 경로를 찾지 못하고 로드 실패하는 현상을 방지하기 위해
/// Dart VM 단에서 File.readAsBytes()로 안전하게 바이너리를 읽어와 Image.memory로 렌더링하는 위젯입니다.
class SafeLocalImage extends StatefulWidget {
  static final _byteCache = _LocalImageBytesCache();

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
  int _loadGeneration = 0;

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
    final generation = ++_loadGeneration;
    final file = widget.file;
    setState(() {
      _loading = true;
      _bytes = null;
      _error = null;
      _stackTrace = null;
    });

    try {
      final bytes = await SafeLocalImage._byteCache.read(file);
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      }
    } catch (e, st) {
      if (mounted && generation == _loadGeneration) {
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

    final devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final cacheWidth = _decodeSize(widget.width, devicePixelRatio);
    final cacheHeight = cacheWidth == null
        ? _decodeSize(widget.height, devicePixelRatio)
        : null;

    return Image.memory(
      _bytes!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: FilterQuality.medium,
      errorBuilder: widget.errorBuilder,
    );
  }

  int? _decodeSize(double? logicalSize, double devicePixelRatio) {
    if (logicalSize == null ||
        !logicalSize.isFinite ||
        logicalSize <= 0 ||
        devicePixelRatio <= 0) {
      return null;
    }
    return (logicalSize * devicePixelRatio).ceil().clamp(1, 4096);
  }
}

/// Bounded LRU for user-owned image bytes.
///
/// Multiple cards showing the same poster share both the byte buffer and the
/// resulting MemoryImage cache key. File timestamp and length participate in
/// the key, so a replaced poster is not confused with its previous revision.
class _LocalImageBytesCache {
  static const int _maximumBytes = 64 * 1024 * 1024;

  final LinkedHashMap<String, Uint8List> _entries = LinkedHashMap();
  final Map<String, Future<Uint8List>> _pending = {};
  int _totalBytes = 0;

  Future<Uint8List> read(File file) async {
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw FileSystemException('File does not exist', file.path);
    }
    final key =
        '${file.path}\u0000${stat.modified.microsecondsSinceEpoch}\u0000${stat.size}';
    final cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return cached;
    }

    final existingRead = _pending[key];
    if (existingRead != null) return existingRead;

    final read = file.readAsBytes();
    _pending[key] = read;
    try {
      final bytes = await read;
      _store(key, bytes);
      return bytes;
    } finally {
      _pending.remove(key);
    }
  }

  void _store(String key, Uint8List bytes) {
    if (bytes.lengthInBytes > _maximumBytes) return;
    _entries[key] = bytes;
    _totalBytes += bytes.lengthInBytes;
    while (_totalBytes > _maximumBytes && _entries.isNotEmpty) {
      final oldestKey = _entries.keys.first;
      final removed = _entries.remove(oldestKey);
      if (removed != null) _totalBytes -= removed.lengthInBytes;
    }
  }
}
