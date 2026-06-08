/// pipeline/discovery/manifest.json 로더
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'discovery_types.dart';

const discoveryManifestRelative =
    'akasha-db/pipeline/discovery/manifest.json';

class DiscoveryManifest {
  final int version;
  final Map<String, DiscoveryChannelConfig> channels;

  const DiscoveryManifest({
    required this.version,
    required this.channels,
  });

  DiscoveryChannelConfig? channel(String id) => channels[id];

  static DiscoveryManifest load(Directory projectRoot) {
    final file = File(p.join(projectRoot.path, discoveryManifestRelative));
    if (!file.existsSync()) {
      throw StateError('Missing $discoveryManifestRelative');
    }
    final decoded = json.decode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid discovery manifest');
    }
    return DiscoveryManifest.fromJson(decoded);
  }

  factory DiscoveryManifest.fromJson(Map<String, dynamic> json) {
    final version = int.tryParse(json['version']?.toString() ?? '') ?? 1;
    final rawChannels = json['channels'];
    final channels = <String, DiscoveryChannelConfig>{};
    if (rawChannels is Map) {
      rawChannels.forEach((key, value) {
        if (value is! Map) return;
        final map = Map<String, dynamic>.from(value);
        channels[key.toString()] = DiscoveryChannelConfig(
          id: key.toString(),
          source: map['source']?.toString() ?? '',
          category: map['category']?.toString() ?? '',
          domain: map['domain']?.toString() ?? 'subculture',
          enabled: map['enabled'] == true,
          dailyLimit: int.tryParse(map['dailyLimit']?.toString() ?? '') ?? 0,
          trialBatchSize:
              int.tryParse(map['trialBatchSize']?.toString() ?? '') ?? 100,
          cursorPath: map['cursorPath']?.toString() ?? '',
        );
      });
    }
    return DiscoveryManifest(version: version, channels: channels);
  }
}

Map<String, dynamic> readCursor(Directory projectRoot, String relativePath) {
  final file = File(p.join(projectRoot.path, 'akasha-db', relativePath));
  if (!file.existsSync()) {
    return {
      'lastPage': 0,
      'lastId': null,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
  final decoded = json.decode(file.readAsStringSync());
  return decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{};
}

void writeCursor(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> cursor,
) {
  cursor['updatedAt'] = DateTime.now().toUtc().toIso8601String();
  final file = File(p.join(projectRoot.path, 'akasha-db', relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(cursor)}\n',
  );
}
