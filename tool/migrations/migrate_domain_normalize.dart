// ignore_for_file: avoid_print
// Registry shard `domain` 정규화 — generalCulture → subculture
//
// Usage: dart run tool/migrations/migrate_domain_normalize.dart [--dry-run]
library;

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final root = _findProjectRoot();
  final shardsRoot = Directory('${root.path}/akasha-db/shards');
  if (!shardsRoot.existsSync()) {
    stderr.writeln('ERROR: ${shardsRoot.path} not found');
    exit(1);
  }

  var worksNormalized = 0;
  var filesWritten = 0;

  for (final categoryDir in shardsRoot.listSync().whereType<Directory>()) {
    for (final shardFile in categoryDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final raw = shardFile.readAsStringSync();
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) continue;

      var changed = false;
      for (final entry in decoded.entries) {
        if (entry.value is! Map) continue;
        final work = Map<String, dynamic>.from(entry.value as Map);
        final domain = work['domain']?.toString() ?? '';
        if (domain == 'generalCulture') {
          work['domain'] = 'subculture';
          decoded[entry.key] = work;
          worksNormalized++;
          changed = true;
        } else if (domain.isEmpty) {
          work['domain'] = 'subculture';
          decoded[entry.key] = work;
          changed = true;
        }
      }

      if (changed && !dryRun) {
        const encoder = JsonEncoder.withIndent('  ');
        shardFile.writeAsStringSync('${encoder.convert(decoded)}\n');
        filesWritten++;
      } else if (changed) {
        filesWritten++;
      }
    }
  }

  print(
    dryRun
        ? 'DRY-RUN: would normalize $worksNormalized work(s) in $filesWritten shard file(s)'
        : 'OK: normalized $worksNormalized work(s) in $filesWritten shard file(s)',
  );
  print('Next: dart run tool/registry_builder.dart --sync-assets --bundle-eager-only');
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
