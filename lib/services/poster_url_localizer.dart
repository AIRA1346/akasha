import 'dart:io';
import 'dart:typed_data';

import '../core/app_vault.dart';
import '../core/ports/vault_port.dart';
import '../utils/helpers.dart';

/// HTTP 이미지 URL → vault `posters/` 상대경로 (하이브리드 로컬라이징).
abstract final class PosterUrlLocalizer {
  static const maxBytes = 15 * 1024 * 1024;
  static const timeout = Duration(seconds: 30);

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// 테스트·주입용. null이면 [defaultDownload] 사용.
  static Future<PosterDownloadPayload?> Function(Uri uri)? downloadOverride;

  static VaultPort get _vault => AppVault.port;

  static Future<PosterResolveResult> resolve(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return PosterResolveResult(path: '', localized: false);
    }

    if (_isVaultRelativePosterPath(trimmed)) {
      return PosterResolveResult(
        path: trimmed.replaceAll('\\', '/'),
        localized: false,
      );
    }

    if (!_isHttpUrl(trimmed)) {
      final local = await _importLocalPathIfPossible(trimmed);
      if (local != null) {
        return PosterResolveResult(path: local, localized: true);
      }
      return PosterResolveResult(path: trimmed, localized: false);
    }

    if (_vault.vaultPath == null) {
      return PosterResolveResult(
        path: trimmed,
        localized: false,
        failureMessage: '볼트가 연결되지 않아 이미지를 저장할 수 없습니다. URL을 그대로 사용합니다.',
      );
    }

    if (!isValidImageUrl(trimmed)) {
      return PosterResolveResult(
        path: trimmed,
        localized: false,
        failureMessage: '올바르지 않은 이미지 URL입니다. URL을 그대로 사용합니다.',
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return PosterResolveResult(
        path: trimmed,
        localized: false,
        failureMessage: '이미지를 다운로드하지 못했습니다. URL을 그대로 사용합니다.',
      );
    }

    final payload = await (downloadOverride ?? defaultDownload)(uri);
    if (payload == null || payload.bytes.isEmpty) {
      return PosterResolveResult(
        path: trimmed,
        localized: false,
        failureMessage: '이미지를 다운로드하지 못했습니다. URL을 그대로 사용합니다.',
      );
    }

    final mime = payload.contentType?.toLowerCase();
    if (mime != null && !mime.startsWith('image/')) {
      return PosterResolveResult(
        path: trimmed,
        localized: false,
        failureMessage: '이미지가 아닌 응답입니다. URL을 그대로 사용합니다.',
      );
    }
    if (!_looksLikeImage(payload.bytes)) {
      return PosterResolveResult(
        path: trimmed,
        localized: false,
        failureMessage: '이미지를 다운로드하지 못했습니다. URL을 그대로 사용합니다.',
      );
    }

    final extension = extensionForPayload(payload, uri);
    final relative = await _vault.importPosterImageBytesDeduped(
      payload.bytes,
      extension: extension,
    );
    if (relative == null) {
      return PosterResolveResult(
        path: trimmed,
        localized: false,
        failureMessage: '이미지를 볼트에 저장하지 못했습니다. URL을 그대로 사용합니다.',
      );
    }

    return PosterResolveResult(
      path: relative.replaceAll('\\', '/'),
      localized: true,
    );
  }

  static Future<String> applyWithSnackBar(
    String input, {
    required void Function(String message) showSnack,
  }) async {
    final result = await resolve(input);
    if (result.failureMessage != null) {
      showSnack(result.failureMessage!);
    }
    return result.path;
  }

  static Future<PosterDownloadPayload?> defaultDownload(Uri uri) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      request.headers.set(HttpHeaders.acceptHeader, 'image/*,*/*;q=0.8');

      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) return null;

      final mime = response.headers.contentType?.mimeType.toLowerCase();
      if (mime != null && !mime.startsWith('image/')) return null;

      final builder = BytesBuilder(copy: false);
      var total = 0;
      await for (final chunk in response.timeout(timeout)) {
        total += chunk.length;
        if (total > maxBytes) return null;
        builder.add(chunk);
      }

      final bytes = builder.takeBytes();
      if (bytes.isEmpty) return null;
      if (!_looksLikeImage(bytes)) return null;

      return PosterDownloadPayload(bytes: bytes, contentType: mime);
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static String extensionForPayload(PosterDownloadPayload payload, Uri uri) {
    final mime = payload.contentType;
    if (mime != null) {
      final fromMime = _extensionFromMime(mime);
      if (fromMime != null) return fromMime;
    }

    final path = uri.path.toLowerCase();
    for (final ext in const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp']) {
      if (path.endsWith('.$ext')) {
        return ext == 'jpeg' ? 'jpg' : ext;
      }
    }

    return _guessExtension(payload.bytes);
  }

  static Future<String?> _importLocalPathIfPossible(String path) async {
    if (_vault.vaultPath == null) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return _vault.importPosterImage(path);
  }

  static bool _isHttpUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  static bool _isVaultRelativePosterPath(String value) {
    final normalized = value.replaceAll('\\', '/');
    return normalized.startsWith('posters/');
  }

  static bool _looksLikeImage(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return true;
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return true;
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return true;
    }
    return false;
  }

  static String? _extensionFromMime(String mime) {
    return switch (mime) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/bmp' => 'bmp',
      _ => mime.startsWith('image/') ? 'jpg' : null,
    };
  }

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
    return 'jpg';
  }
}

class PosterDownloadPayload {
  const PosterDownloadPayload({
    required this.bytes,
    this.contentType,
  });

  final Uint8List bytes;
  final String? contentType;
}

class PosterResolveResult {
  const PosterResolveResult({
    required this.path,
    required this.localized,
    this.failureMessage,
  });

  final String path;
  final bool localized;
  final String? failureMessage;
}
