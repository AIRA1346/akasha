import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

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
}
