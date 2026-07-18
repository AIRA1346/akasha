import 'dart:convert';

import 'package:akasha/services/registry_shard_loader.dart';
import 'package:akasha/services/registry_source.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegistrySource', () {
    test(
      'test source exposes required reads and typed missing errors',
      () async {
        final source = TestRegistrySource({'manifest.json': '{}'});

        expect(await source.exists('manifest.json'), isTrue);
        expect(await source.readRequired('manifest.json'), '{}');
        await expectLater(
          source.readRequired('missing.json'),
          throwsA(
            isA<RegistrySourceException>()
                .having(
                  (e) => e.type,
                  'type',
                  RegistrySourceFailureType.missing,
                )
                .having((e) => e.sourceId, 'sourceId', 'test:memory'),
          ),
        );
      },
    );

    test('remote source stays explicit and never falls back', () async {
      final reads = <String>[];
      final source = RemoteRegistrySource(
        sourceId: 'remote:test-release',
        reader: (path) async {
          reads.add(path);
          return path == 'manifest.json' ? '{}' : null;
        },
      );

      expect(await source.readRequired('manifest.json'), '{}');
      await expectLater(
        source.readRequired('shards/game/00.json'),
        throwsA(isA<RegistrySourceException>()),
      );
      expect(reads, ['manifest.json', 'shards/game/00.json']);
    });
  });

  group('bundle provenance and typed failures', () {
    test('valid full bundle loads on-demand detail from one source', () async {
      final fixture = _fullBundleFixture();
      final merged = <String, dynamic>{};
      final source = _RecordingSource(fixture);
      final loader = RegistryShardLoader(
        source: source,
        shardEntriesMerger: merged.addAll,
      );

      await loader.loadBundledBootstrap();
      expect(loader.manifest?.releaseId, 'registry-test');
      expect(loader.source.sourceId, 'test:memory');
      expect(loader.isShardLoaded('game_00'), isFalse);
      expect(source.requiredReads, isNot(contains('shards/game/00.json')));

      await loader.ensureShardForWorkId('wk_000000001');

      expect(loader.isShardLoaded('game_00'), isTrue);
      expect(merged, contains('wk_000000001'));
      expect(source.requiredReads, contains('shards/game/00.json'));
    });

    test('missing shard reports shard, path, release, and source', () async {
      final fixture = _fullBundleFixture()..remove('shards/game/00.json');
      final loader = RegistryShardLoader(source: TestRegistrySource(fixture));

      await expectLater(
        loader.loadBundledBootstrap(),
        throwsA(
          isA<RegistrySourceException>()
              .having((e) => e.type, 'type', RegistrySourceFailureType.missing)
              .having((e) => e.shardId, 'shardId', 'game_00')
              .having((e) => e.relativePath, 'path', 'shards/game/00.json')
              .having((e) => e.releaseId, 'release', 'registry-test')
              .having((e) => e.sourceId, 'source', 'test:memory'),
        ),
      );
    });

    test('search shard SHA uses the builder canonical JSON contract', () async {
      final fixture = _fullBundleFixture();
      final decoded = jsonDecode(fixture['search_index/game.json']!);
      fixture['search_index/game.json'] =
          '${const JsonEncoder.withIndent('  ').convert(decoded)}\n';
      final loader = RegistryShardLoader(source: TestRegistrySource(fixture));

      await loader.loadBundledBootstrap();
      await loader.ensureSearchIndexLoaded();
      expect(loader.searchIndex, hasLength(1));
    });

    test('search shard content corruption reports manifest mismatch', () async {
      final fixture = _fullBundleFixture();
      final decoded =
          jsonDecode(fixture['search_index/game.json']!) as List<dynamic>;
      (decoded.single as Map<String, dynamic>)['title'] = 'Corrupted';
      fixture['search_index/game.json'] = jsonEncode(decoded);
      final loader = RegistryShardLoader(source: TestRegistrySource(fixture));

      await loader.loadBundledBootstrap();
      await expectLater(
        loader.ensureSearchIndexLoaded(),
        throwsA(
          isA<RegistrySourceException>().having(
            (e) => e.type,
            'type',
            RegistrySourceFailureType.manifestMismatch,
          ),
        ),
      );
    });

    test('root and search release mismatch is rejected', () async {
      final fixture = _fullBundleFixture();
      final search =
          jsonDecode(fixture['search_index/manifest.json']!)
              as Map<String, dynamic>;
      search['releaseId'] = 'registry-other';
      fixture['search_index/manifest.json'] = jsonEncode(search);

      await expectLater(
        RegistryShardLoader(
          source: TestRegistrySource(fixture),
        ).loadBundledBootstrap(),
        throwsA(
          isA<RegistrySourceException>().having(
            (e) => e.type,
            'type',
            RegistrySourceFailureType.invalidProvenance,
          ),
        ),
      );
    });

    test('malformed and SHA-mismatched shards are distinct failures', () async {
      final malformed = _fullBundleFixture();
      malformed['shards/game/00.json'] = '[';
      _setShardSha(malformed, _sha('['));
      final malformedLoader = RegistryShardLoader(
        source: TestRegistrySource(malformed),
      );
      await malformedLoader.loadBundledBootstrap();

      await expectLater(
        malformedLoader.ensureShardLoaded('game_00'),
        throwsA(
          isA<RegistrySourceException>().having(
            (e) => e.type,
            'type',
            RegistrySourceFailureType.malformedJson,
          ),
        ),
      );

      final mismatch = _fullBundleFixture();
      mismatch['shards/game/00.json'] = '{}';
      final mismatchLoader = RegistryShardLoader(
        source: TestRegistrySource(mismatch),
      );
      await mismatchLoader.loadBundledBootstrap();
      await expectLater(
        mismatchLoader.ensureShardLoaded('game_00'),
        throwsA(
          isA<RegistrySourceException>().having(
            (e) => e.type,
            'type',
            RegistrySourceFailureType.manifestMismatch,
          ),
        ),
      );
    });

    test('legacy fixture requires explicit legacy mode', () async {
      final files = {
        'manifest.json': jsonEncode({'version': 3, 'shards': []}),
        'search_index.json': '[]',
        'legacy_aliases.json': '{}',
      };

      await expectLater(
        RegistryShardLoader(
          source: TestRegistrySource(files),
        ).loadBundledBootstrap(),
        throwsA(isA<RegistrySourceException>()),
      );
      await RegistryShardLoader(
        source: TestRegistrySource(files),
        allowLegacyManifest: true,
      ).loadBundledBootstrap();
    });
  });
}

Map<String, String> _fullBundleFixture() {
  final shard = jsonEncode({
    'wk_000000001': {
      'workId': 'wk_000000001',
      'title': 'Offline Game',
      'category': 'game',
      'domain': 'subculture',
    },
  });
  final searchIndex = jsonEncode([
    {
      'workId': 'wk_000000001',
      'title': 'Offline Game',
      'shardId': 'game_00',
      'category': 'game',
      'domain': 'subculture',
      'searchTokens': ['offline game', '오프라인 게임'],
    },
  ]);
  return {
    'manifest.json': jsonEncode({
      'version': 4,
      'entryCount': 1,
      'releaseId': 'registry-test',
      'sourceRevision': 'source-test',
      'schemaVersion': 4,
      'bundleMode': 'full',
      'shardBits': 8,
      'shards': [
        {
          'id': 'game_00',
          'category': 'game',
          'path': 'shards/game/00.json',
          'eager': false,
          'entryCount': 1,
          'sha256': _sha(shard),
        },
      ],
    }),
    'search_index/manifest.json': jsonEncode({
      'version': 1,
      'entryCount': 1,
      'releaseId': 'registry-test',
      'sourceRevision': 'source-test',
      'schemaVersion': 4,
      'bundleMode': 'full',
      'shards': [
        {
          'category': 'game',
          'path': 'search_index/game.json',
          'entryCount': 1,
          'sha256': _sha(searchIndex),
        },
      ],
    }),
    'search_index.json': searchIndex,
    'search_index/game.json': searchIndex,
    'legacy_aliases.json': '{}',
    'franchise_groups.json': '{}',
    'shards/game/00.json': shard,
  };
}

void _setShardSha(Map<String, String> fixture, String sha) {
  final manifest =
      jsonDecode(fixture['manifest.json']!) as Map<String, dynamic>;
  final shards = manifest['shards'] as List<dynamic>;
  (shards.single as Map<String, dynamic>)['sha256'] = sha;
  fixture['manifest.json'] = jsonEncode(manifest);
}

String _sha(String content) => sha256.convert(utf8.encode(content)).toString();

class _RecordingSource extends TestRegistrySource {
  _RecordingSource(super.files);

  final List<String> requiredReads = [];

  @override
  Future<String> readRequired(String relativePath) {
    requiredReads.add(relativePath);
    return super.readRequired(relativePath);
  }
}
