import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:akasha/services/taste_index_service.dart';

const String vaultPath = r"G:\내 드라이브\akasha-md";
const String backupPath = r"G:\내 드라이브\akasha-md-backup-v3";

void main(List<String> args) async {
  final isApply = args.contains('--apply');
  print('=== AKASHA Vault v3 Migrator ===');
  print('Vault Target: $vaultPath');
  print('Mode: ${isApply ? "APPLY (Writes changes & Backs up)" : "DRY-RUN (Simulated)"}');
  print('--------------------------------\n');

  final vaultDir = Directory(vaultPath);
  if (!await vaultDir.exists()) {
    print('Error: Target vault path does not exist at "$vaultPath"');
    exit(1);
  }

  // 1. Back up first if Apply mode
  if (isApply) {
    print('[1/5] Backing up vault to "$backupPath"...');
    await _backupVault(vaultPath, backupPath);
    print('      Backup completed successfully.\n');
  } else {
    print('[1/5] [Dry-run] Skipping backup creation.\n');
  }

  // 2. Scan all files and build mapping table [Old BaseName (without extension) -> New ID BaseName]
  print('[2/5] Scanning vault files for ID extraction...');
  final markdownFiles = <File>[];
  final nameToIdMap = <String, String>{}; // e.g. "렘" -> "pe_u_3puh848u"
  final fileToNewNameMap = <String, String>{}; // e.g. "works/movie/렘.md" -> "pe_u_3puh848u.md"

  await for (final entity in vaultDir.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.md')) continue;
    
    // Skip system folders
    final relative = p.relative(entity.path, from: vaultPath);
    if (relative.startsWith('.') || relative.contains('${p.separator}.')) continue;
    if (relative.startsWith('posters') || relative.startsWith('catalog')) continue;

    markdownFiles.add(entity);

    final content = await entity.readAsString();
    final frontmatter = _extractFrontmatter(content);
    if (frontmatter == null) continue;

    try {
      final yaml = loadYaml(frontmatter);
      if (yaml is! Map) continue;

      final id = yaml['work_id']?.toString().trim() ??
                 yaml['entity_id']?.toString().trim() ??
                 yaml['record_id']?.toString().trim();

      if (id != null && id.isNotEmpty && !id.startsWith('path:')) {
        final oldBaseName = p.basenameWithoutExtension(entity.path);
        nameToIdMap[oldBaseName] = id;
        fileToNewNameMap[entity.path] = '$id.md';
      }
    } catch (_) {}
  }
  print('      Scanned ${markdownFiles.length} files. Found ${nameToIdMap.length} stable identity mappings.\n');

  // 3. Rename files based on ID [Old Title.md -> ID.md]
  print('[3/5] Simulating/Performing file renaming...');
  final renamedPaths = <String, String>{}; // maps old absolute path to new absolute path

  for (final file in markdownFiles) {
    final newName = fileToNewNameMap[file.path];
    if (newName == null) {
      renamedPaths[file.path] = file.path;
      continue;
    }

    final oldName = p.basename(file.path);
    if (oldName == newName) {
      renamedPaths[file.path] = file.path;
      continue;
    }

    final dir = p.dirname(file.path);
    final targetPath = p.join(dir, newName);

    print('      [Rename] ${p.relative(file.path, from: vaultPath)} -> $newName');

    if (isApply) {
      await file.rename(targetPath);
      renamedPaths[file.path] = targetPath;
    } else {
      renamedPaths[file.path] = targetPath;
    }
  }
  print('      File renaming simulation/execution done.\n');

  // 4. Update backlinks text content [[Old Title]] -> [[ID|Old Title]]
  print('[4/5] Updating Wiki Backlinks in all Markdown contents...');
  final wikiRegex = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');

  for (final oldPath in renamedPaths.keys) {
    final currentPath = renamedPaths[oldPath]!;
    final file = File(currentPath);
    if (!await file.exists()) continue;

    final content = await file.readAsString();
    var hasChanges = false;

    final updatedContent = content.replaceAllMapped(wikiRegex, (match) {
      final targetTitle = match.group(1)!.trim();
      final displayTitle = match.group(2)?.trim() ?? targetTitle;

      final targetId = nameToIdMap[targetTitle];
      if (targetId != null) {
        hasChanges = true;
        return '[[$targetId|$displayTitle]]';
      }
      return match.group(0)!;
    });

    if (hasChanges) {
      print('      [Backlink Update] ${p.relative(currentPath, from: vaultPath)}');
      if (isApply) {
        await file.writeAsString(updatedContent, flush: true);
      }
    }
  }
  print('      Backlink reference updates simulation/execution done.\n');

  // 5. Rebuild Indexes
  if (isApply) {
    print('[5/5] Rebuilding Derived Indexes (.akasha/)...');
    final recordIndexer = RecordSummaryIndexService();
    final tasteIndexer = TasteIndexService();
    
    await recordIndexer.rebuildFromVault(vaultPath);
    await tasteIndexer.rebuildFromVault(vaultPath);
    print('      Index regeneration successfully completed.\n');
  } else {
    print('[5/5] [Dry-run] Skipping index regeneration.\n');
  }

  print('=== Migration Run Finished ===');
}

String? _extractFrontmatter(String content) {
  final lines = content.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') return null;
  var end = -1;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      end = i;
      break;
    }
  }
  if (end < 0) return null;
  return lines.sublist(1, end).join('\n');
}

Future<void> _backupVault(String source, String destination) async {
  final sourceDir = Directory(source);
  final destDir = Directory(destination);
  if (await destDir.exists()) {
    await destDir.delete(recursive: true);
  }
  await destDir.create(recursive: true);

  await for (final entity in sourceDir.list(recursive: true, followLinks: false)) {
    final relative = p.relative(entity.path, from: source);
    if (relative.startsWith('.') || relative.contains('${p.separator}.')) continue;

    if (entity is Directory) {
      await Directory(p.join(destination, relative)).create(recursive: true);
    } else if (entity is File) {
      final destFile = File(p.join(destination, relative));
      await destFile.parent.create(recursive: true);
      await entity.copy(destFile.path);
    }
  }
}
