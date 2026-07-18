import 'package:flutter/services.dart';

enum RegistrySourceFailureType {
  missing,
  malformedJson,
  manifestMismatch,
  incompatibleSchema,
  invalidProvenance,
}

class RegistrySourceException implements Exception {
  const RegistrySourceException({
    required this.type,
    required this.relativePath,
    required this.sourceId,
    this.shardId,
    this.releaseId,
    this.cause,
  });

  final RegistrySourceFailureType type;
  final String relativePath;
  final String sourceId;
  final String? shardId;
  final String? releaseId;
  final Object? cause;

  @override
  String toString() {
    final details = <String>[
      'type=${type.name}',
      if (shardId != null) 'shardId=$shardId',
      'path=$relativePath',
      if (releaseId != null) 'releaseId=$releaseId',
      'sourceId=$sourceId',
      if (cause != null) 'cause=$cause',
    ];
    return 'RegistrySourceException(${details.join(', ')})';
  }
}

abstract interface class RegistrySource {
  Future<String> readRequired(String relativePath);
  Future<bool> exists(String relativePath);
  String get sourceId;
}

class BundledRegistrySource implements RegistrySource {
  BundledRegistrySource({
    AssetBundle? bundle,
    this.assetRoot = 'assets/registry',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetRoot;
  Future<Set<String>>? _assetPaths;

  @override
  String get sourceId => 'bundle:$assetRoot';

  String _assetPath(String relativePath) => '$assetRoot/$relativePath';

  @override
  Future<String> readRequired(String relativePath) async {
    try {
      return await _bundle.loadString(_assetPath(relativePath));
    } catch (error) {
      throw RegistrySourceException(
        type: RegistrySourceFailureType.missing,
        relativePath: relativePath,
        sourceId: sourceId,
        cause: error,
      );
    }
  }

  @override
  Future<bool> exists(String relativePath) async {
    try {
      final paths = await (_assetPaths ??= _loadAssetPaths());
      return paths.contains(_assetPath(relativePath));
    } catch (_) {
      // Custom test bundles may not expose AssetManifest.bin. Keep the
      // interface usable without changing production's manifest-only lookup.
      try {
        await _bundle.load(_assetPath(relativePath));
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<Set<String>> _loadAssetPaths() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    return manifest.listAssets().toSet();
  }
}

class TestRegistrySource implements RegistrySource {
  TestRegistrySource(this.files, {this.sourceId = 'test:memory'});

  final Map<String, String> files;

  @override
  final String sourceId;

  @override
  Future<bool> exists(String relativePath) async =>
      files.containsKey(relativePath);

  @override
  Future<String> readRequired(String relativePath) async {
    final value = files[relativePath];
    if (value != null) return value;
    throw RegistrySourceException(
      type: RegistrySourceFailureType.missing,
      relativePath: relativePath,
      sourceId: sourceId,
    );
  }
}

typedef RemoteRegistryReader = Future<String?> Function(String relativePath);

/// Isolated future provider. Production wiring never constructs this source.
class RemoteRegistrySource implements RegistrySource {
  const RemoteRegistrySource({
    required RemoteRegistryReader reader,
    required this.sourceId,
  }) : _reader = reader;

  final RemoteRegistryReader _reader;

  @override
  final String sourceId;

  @override
  Future<bool> exists(String relativePath) async =>
      await _reader(relativePath) != null;

  @override
  Future<String> readRequired(String relativePath) async {
    final value = await _reader(relativePath);
    if (value != null) return value;
    throw RegistrySourceException(
      type: RegistrySourceFailureType.missing,
      relativePath: relativePath,
      sourceId: sourceId,
    );
  }
}
