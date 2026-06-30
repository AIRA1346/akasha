import 'dart:io';
import 'dart:typed_data';

import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/poster_url_localizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PosterUrlLocalizer', () {
    late Directory tempVaultDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempVaultDir = await Directory.systemTemp.createTemp('akasha_poster_url');
      final fileService = AkashaFileService();
      await fileService.setVaultPath(tempVaultDir.path);
      PosterUrlLocalizer.downloadOverride = null;
    });

    tearDown(() async {
      PosterUrlLocalizer.downloadOverride = null;
      if (tempVaultDir.existsSync()) {
        await tempVaultDir.delete(recursive: true);
      }
      await AkashaFileService().setVaultPath('');
    });

    test('localizes http URL to posters relative path', () async {
      final bytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x01,
      ]);

      PosterUrlLocalizer.downloadOverride = (uri) async {
        expect(uri.toString(), 'https://example.com/poster.png');
        return PosterDownloadPayload(bytes: bytes, contentType: 'image/png');
      };

      final result = await PosterUrlLocalizer.resolve(
        'https://example.com/poster.png',
      );

      expect(result.localized, isTrue);
      expect(result.path, startsWith('posters/'));
      expect(result.path, endsWith('.png'));
      expect(result.failureMessage, isNull);

      final saved = File(p.join(tempVaultDir.path, result.path));
      expect(saved.existsSync(), isTrue);
    });

    test('dedupes identical downloads to the same posters path', () async {
      final bytes = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0x00,
        0x01,
        0x02,
      ]);

      PosterUrlLocalizer.downloadOverride = (_) async {
        return PosterDownloadPayload(bytes: bytes, contentType: 'image/jpeg');
      };

      final first = await PosterUrlLocalizer.resolve('https://a.test/one.jpg');
      final second = await PosterUrlLocalizer.resolve('https://b.test/two.jpg');

      expect(first.localized, isTrue);
      expect(second.localized, isTrue);
      expect(first.path, second.path);
      expect(
        Directory(p.join(tempVaultDir.path, 'posters')).listSync().length,
        1,
      );
    });

    test('falls back to original URL when download fails', () async {
      PosterUrlLocalizer.downloadOverride = (_) async => null;

      final result = await PosterUrlLocalizer.resolve(
        'https://example.com/missing.jpg',
      );

      expect(result.localized, isFalse);
      expect(result.path, 'https://example.com/missing.jpg');
      expect(result.failureMessage, isNotNull);
    });

    test('rejects non-image content type', () async {
      PosterUrlLocalizer.downloadOverride = (_) async {
        return PosterDownloadPayload(
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'text/html',
        );
      };

      final result = await PosterUrlLocalizer.resolve(
        'https://example.com/not-image.jpg',
      );

      expect(result.localized, isFalse);
      expect(result.path, 'https://example.com/not-image.jpg');
      expect(result.failureMessage, contains('이미지가 아닌'));
    });

    test('keeps existing posters relative path unchanged', () async {
      final result = await PosterUrlLocalizer.resolve('posters/existing.png');

      expect(result.localized, isFalse);
      expect(result.path, 'posters/existing.png');
      expect(result.failureMessage, isNull);
    });
  });

  group('importPosterImageBytesDeduped', () {
    late Directory tempVaultDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempVaultDir = await Directory.systemTemp.createTemp('akasha_poster_dedupe');
      await AkashaFileService().setVaultPath(tempVaultDir.path);
    });

    tearDown(() async {
      if (tempVaultDir.existsSync()) {
        await tempVaultDir.delete(recursive: true);
      }
      await AkashaFileService().setVaultPath('');
    });

    test('writes hash-based filename under posters', () async {
      final fileService = AkashaFileService();
      final bytes = Uint8List.fromList([9, 8, 7, 6, 5]);

      final relative = await fileService.importPosterImageBytesDeduped(
        bytes,
        extension: 'png',
      );

      expect(relative, isNotNull);
      expect(relative, startsWith('posters/'));
      expect(File(p.join(tempVaultDir.path, relative!)).existsSync(), isTrue);
    });
  });
}
