import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/registry_models.dart';
import 'package:akasha/services/registry_shard_loader.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late RegistryShardLoader loader;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('akasha_registry_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot);
    loader = RegistryShardLoader();
    loader.manifestForTesting = const RegistryManifest(
      version: 3,
      generatedAt: '2026-06-07T10:00:00.000Z',
      shards: [],
    );
    loader.resetLoadedShardsForTesting();
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('RegistryShardLoader cache staleness', () {
    test('returns false when cache manifest is absent', () async {
      expect(await loader.isDiskCacheStaleComparedToBundle(), isFalse);
    });

    test('returns false when cache matches bundle generatedAt', () async {
      await _writeCachedManifest(
        tempRoot,
        generatedAt: '2026-06-07T10:00:00.000Z',
      );
      expect(await loader.isDiskCacheStaleComparedToBundle(), isFalse);
    });

    test('returns true when bundle is newer than cache', () async {
      await _writeCachedManifest(
        tempRoot,
        generatedAt: '2026-06-06T00:00:00.000Z',
      );
      expect(await loader.isDiskCacheStaleComparedToBundle(), isTrue);
    });

    test('returns false when cache is newer than bundle', () async {
      await _writeCachedManifest(
        tempRoot,
        generatedAt: '2026-06-08T00:00:00.000Z',
      );
      expect(await loader.isDiskCacheStaleComparedToBundle(), isFalse);
    });

    test('clearDiskCache removes cached files', () async {
      final cacheDir = Directory(p.join(tempRoot.path, 'registry_cache'));
      cacheDir.createSync(recursive: true);
      File(p.join(cacheDir.path, 'manifest.json')).writeAsStringSync('{}');
      File(p.join(cacheDir.path, 'search_index.json')).writeAsStringSync('[]');

      await loader.clearDiskCache();

      expect(
        File(p.join(cacheDir.path, 'manifest.json')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(cacheDir.path, 'search_index.json')).existsSync(),
        isFalse,
      );
    });
  });
}

Future<void> _writeCachedManifest(
  Directory tempRoot, {
  required String generatedAt,
}) async {
  final cacheDir = Directory(p.join(tempRoot.path, 'registry_cache'));
  cacheDir.createSync(recursive: true);
  final manifest = {
    'version': 3,
    'generatedAt': generatedAt,
    'shards': [
      {
        'id': 'manga_K',
        'category': MediaCategory.manga.name,
        'path': 'shards/manga/manga_K.json',
        'eager': true,
        'entryCount': 1,
      },
    ],
  };
  await File(p.join(cacheDir.path, 'manifest.json'))
      .writeAsString(jsonEncode(manifest));
}
