import 'package:akasha/models/registry_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registry manifests accept optional bundle provenance', () {
    final root = RegistryManifest.fromJson({
      'version': 4,
      'entryCount': 0,
      'shards': <Object>[],
      'releaseId': 'registry-release',
      'sourceRevision': 'abc123',
      'schemaVersion': 4,
      'bundleMode': 'full',
    });
    final search = RegistrySearchIndexManifest.fromJson({
      'version': 1,
      'entryCount': 0,
      'shards': <Object>[],
      'releaseId': 'registry-release',
      'sourceRevision': 'abc123',
      'schemaVersion': 4,
      'bundleMode': 'full',
    });

    expect(root.releaseId, search.releaseId);
    expect(root.sourceRevision, search.sourceRevision);
    expect(root.schemaVersion, search.schemaVersion);
    expect(root.bundleMode, search.bundleMode);
  });

  test('legacy manifests remain parseable without provenance', () {
    final root = RegistryManifest.fromJson({
      'version': 4,
      'entryCount': 0,
      'shards': <Object>[],
    });
    final search = RegistrySearchIndexManifest.fromJson({
      'version': 1,
      'entryCount': 0,
      'shards': <Object>[],
    });

    expect(root.releaseId, isNull);
    expect(root.sourceRevision, isNull);
    expect(root.schemaVersion, isNull);
    expect(root.bundleMode, isNull);
    expect(search.releaseId, isNull);
  });
}
