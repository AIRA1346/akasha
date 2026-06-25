import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as p;

import 'file_service.dart';

/// Sanctum 본문·갤러리 — vault/posters 이미지 가져오기.
abstract final class SanctumImageImport {
  static bool get canImport => AkashaFileService().vaultPath != null;

  static Future<String?> pickAndImport() async {
    final service = AkashaFileService();
    if (service.vaultPath == null) return null;

    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return null;

    return normalizeRelative(
      await service.importPosterImage(path),
    );
  }

  static Future<String?> importFilePath(String absolutePath) async {
    final service = AkashaFileService();
    if (service.vaultPath == null) return null;
    if (!File(absolutePath).existsSync()) return null;

    return normalizeRelative(
      await service.importPosterImage(absolutePath),
    );
  }

  static Future<String?> importBytes(
    Uint8List bytes, {
    String extension = 'png',
  }) async {
    final service = AkashaFileService();
    if (service.vaultPath == null) return null;

    return normalizeRelative(
      await service.importPosterImageFromBytes(bytes, extension: extension),
    );
  }

  /// 클립보드 이미지(스크린샷 등) → posters.
  static Future<String?> importClipboardImage() async {
    if (!canImport) return null;

    final bytes = await Pasteboard.image;
    if (bytes == null || bytes.isEmpty) return null;

    return importBytes(bytes, extension: _guessExtension(bytes));
  }

  /// 클립보드 파일 경로 목록(데스크톱) → posters.
  static Future<List<String>> importClipboardFiles() async {
    if (!canImport) return const [];

    final imported = <String>[];
    for (final path in await Pasteboard.files()) {
      if (path.isEmpty) continue;
      final ext = p.extension(path).toLowerCase();
      if (!_imageExtensions.contains(ext)) continue;
      final relative = await importFilePath(path);
      if (relative != null) imported.add(relative);
    }
    return imported;
  }

  /// 스마트 붙여넣기 — 이미지 바이트 · 파일 · 로컬 경로 텍스트 순.
  static Future<List<String>> importFromClipboard() async {
    if (!canImport) return const [];

    final image = await importClipboardImage();
    if (image != null) return [image];

    final files = await importClipboardFiles();
    if (files.isNotEmpty) return files;

    final textPath = await importClipboardTextPath(await Pasteboard.text);
    if (textPath != null) return [textPath];

    return const [];
  }

  /// 클립보드 텍스트가 로컬 이미지 경로면 posters로 복사.
  static Future<String?> importClipboardTextPath(String? raw) async {
    if (raw == null) return null;
    final trimmed = raw.trim().replaceAll('"', '');
    if (trimmed.isEmpty) return null;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final file = File(trimmed);
      if (file.existsSync()) {
        return importFilePath(trimmed);
      }
    }
    return null;
  }

  static String? normalizeRelative(String? relative) =>
      relative?.replaceAll('\\', '/');

  static const _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.heic',
  };

  static String _guessExtension(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'gif';
    }
    return 'png';
  }
}
