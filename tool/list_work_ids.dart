// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final cat = args.isNotEmpty ? args.first : null;
  final root = _findProjectRoot();
  final shards = Directory('${root.path}/akasha-db/shards');
  final ids = <String>[];
  for (final f in shards.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    if (cat != null &&
        !f.path.contains('/$cat/') &&
        !f.path.contains('\\$cat\\')) {
      continue;
    }
    final m = json.decode(f.readAsStringSync()) as Map<String, dynamic>;
    ids.addAll(m.keys.cast<String>());
  }
  ids.sort();
  for (final id in ids) {
    print(id);
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('no pubspec');
}
