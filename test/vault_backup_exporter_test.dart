import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:akasha/services/vault_backup_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vaultDir;
  late Directory outputDir;

  setUp(() async {
    vaultDir = await Directory.systemTemp.createTemp('akasha_backup_vault_');
    outputDir = await Directory.systemTemp.createTemp('akasha_backup_out_');
  });

  tearDown(() async {
    if (await vaultDir.exists()) {
      await vaultDir.delete(recursive: true);
    }
    if (await outputDir.exists()) {
      await outputDir.delete(recursive: true);
    }
  });

  Future<void> writeVaultFile(String relativePath, String content) async {
    final file = File(p.joinAll([vaultDir.path, ...relativePath.split('/')]));
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  test('exportVault writes a readable zip with user vault assets', () async {
    await writeVaultFile('works/manga/Favorite.md', 'work body');
    await writeVaultFile('posters/cover.jpg', 'image bytes');
    await writeVaultFile('.akasha/record_index.json', '{"records": []}');
    await writeVaultFile('.trash/2026/trash_entry.json', '{"deleted": true}');
    await writeVaultFile('.git/config', 'not user data');
    await writeVaultFile('works/manga/.akasha_temp.md.tmp', 'temp');

    final result = await const VaultBackupExporter().exportVault(
      vaultPath: vaultDir.path,
      outputDirectory: outputDir.path,
      now: DateTime(2026, 7, 1, 8, 30, 5),
    );

    expect(
      p.basename(result.archivePath),
      'akasha-vault-backup-20260701-083005.zip',
    );
    expect(result.fileCount, 4);
    expect(result.bytesWritten, greaterThan(0));
    expect(await File(result.archivePath).exists(), isTrue);

    final zip = _TestZip(await File(result.archivePath).readAsBytes());
    expect(
      zip.names,
      containsAll([
        'works/manga/Favorite.md',
        'posters/cover.jpg',
        '.akasha/record_index.json',
        '.trash/2026/trash_entry.json',
      ]),
    );
    expect(zip.names, isNot(contains('.git/config')));
    expect(zip.names, isNot(contains('works/manga/.akasha_temp.md.tmp')));
    expect(zip.readText('works/manga/Favorite.md'), 'work body');
  });

  test(
    'exportVault skips the destination zip when placed inside vault',
    () async {
      await writeVaultFile('journal/jr_1.md', 'journal');
      final outputInsideVault = Directory(p.join(vaultDir.path, 'backups'));
      await outputInsideVault.create(recursive: true);
      await File(
        p.join(outputInsideVault.path, 'old-backup.zip'),
      ).writeAsString('old backup', flush: true);

      final result = await const VaultBackupExporter().exportVault(
        vaultPath: vaultDir.path,
        outputDirectory: outputInsideVault.path,
        now: DateTime(2026, 7, 1, 8, 31),
      );

      final zip = _TestZip(await File(result.archivePath).readAsBytes());
      expect(zip.names, ['journal/jr_1.md']);
    },
  );
}

class _TestZip {
  _TestZip(this.bytes) {
    _readCentralDirectory();
  }

  final Uint8List bytes;
  final Map<String, int> _localOffsets = {};

  List<String> get names => _localOffsets.keys.toList()..sort();

  String readText(String name) {
    final offset = _localOffsets[name];
    if (offset == null) throw ArgumentError('Missing $name');
    final header = _reader(offset);
    expect(header.getUint32(0, Endian.little), 0x04034b50);
    final compressedSize = header.getUint32(18, Endian.little);
    final nameLength = header.getUint16(26, Endian.little);
    final extraLength = header.getUint16(28, Endian.little);
    final dataOffset = offset + 30 + nameLength + extraLength;
    return utf8.decode(bytes.sublist(dataOffset, dataOffset + compressedSize));
  }

  void _readCentralDirectory() {
    final eocdOffset = _findSignatureFromEnd(0x06054b50);
    final eocd = _reader(eocdOffset);
    final entryCount = eocd.getUint16(10, Endian.little);
    var offset = eocd.getUint32(16, Endian.little);

    for (var i = 0; i < entryCount; i += 1) {
      final central = _reader(offset);
      expect(central.getUint32(0, Endian.little), 0x02014b50);
      final nameLength = central.getUint16(28, Endian.little);
      final extraLength = central.getUint16(30, Endian.little);
      final commentLength = central.getUint16(32, Endian.little);
      final localOffset = central.getUint32(42, Endian.little);
      final nameStart = offset + 46;
      final name = utf8.decode(
        bytes.sublist(nameStart, nameStart + nameLength),
      );
      _localOffsets[name] = localOffset;
      offset += 46 + nameLength + extraLength + commentLength;
    }
  }

  ByteData _reader(int offset) => ByteData.sublistView(bytes, offset);

  int _findSignatureFromEnd(int signature) {
    for (var i = bytes.length - 22; i >= 0; i -= 1) {
      if (_reader(i).getUint32(0, Endian.little) == signature) return i;
    }
    throw StateError('ZIP signature not found');
  }
}
