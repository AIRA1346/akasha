// ignore_for_file: avoid_print
// 구 8자리 wk_ → 9자리 legacy_aliases 보강 (pad9 이후 1회)

import 'dart:convert';
import 'dart:io';

import 'wk_id_utils.dart';

void main() {
  final root = _findProjectRoot();
  final file = File('${root.path}/akasha-db/legacy_aliases.json');
  final aliases = Map<String, dynamic>.from(
    json.decode(file.readAsStringSync()) as Map,
  );

  var added = 0;
  for (final key in aliases.keys.toList()) {
    final v = aliases[key]?.toString() ?? '';
    if (!isWkId(v)) continue;
    final seq = parseWkSequence(v);
    if (seq == null) continue;
    final legacy8 = 'wk_${seq.toString().padLeft(8, '0')}';
    if (legacy8 == v) continue;
    if (!aliases.containsKey(legacy8)) {
      aliases[legacy8] = v;
      added++;
    }
  }

  // 샤드에 있는 9자리 wk_ 기준으로도 보강
  final shardsRoot = Directory('${root.path}/akasha-db/shards');
  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is! Map) continue;
    for (final key in decoded.keys) {
      final id = key.toString();
      if (!isWkId(id)) continue;
      final seq = parseWkSequence(id)!;
      final legacy8 = 'wk_${seq.toString().padLeft(8, '0')}';
      if (legacy8 != id && !aliases.containsKey(legacy8)) {
        aliases[legacy8] = id;
        added++;
      }
    }
  }

  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(aliases)}\n');
  print('OK: added $added wk_ 8→9 alias(es)');

  final assets = File('${root.path}/assets/registry/legacy_aliases.json');
  if (assets.existsSync()) {
    assets.writeAsStringSync(file.readAsStringSync());
    print('  synced assets/registry/legacy_aliases.json');
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
