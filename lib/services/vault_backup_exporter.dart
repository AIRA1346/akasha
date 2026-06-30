import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

class VaultBackupResult {
  const VaultBackupResult({
    required this.archivePath,
    required this.fileCount,
    required this.bytesWritten,
  });

  final String archivePath;
  final int fileCount;
  final int bytesWritten;
}

class VaultBackupExporter {
  const VaultBackupExporter();

  static const _skipDirNames = {'.git', '.cursor', '.obsidian', 'node_modules'};

  Future<VaultBackupResult> exportVault({
    required String vaultPath,
    required String outputDirectory,
    DateTime? now,
  }) async {
    final vaultDir = Directory(vaultPath);
    if (!await vaultDir.exists()) {
      throw StateError('Vault path does not exist');
    }

    final destinationDir = Directory(outputDirectory);
    await destinationDir.create(recursive: true);

    final archivePath = p.join(
      destinationDir.path,
      _backupFileName(now ?? DateTime.now()),
    );
    final archiveFile = File(archivePath);
    final files = await _collectFiles(
      vaultPath: vaultDir.path,
      outputDirectory: destinationDir.path,
      archivePath: archiveFile.path,
    );

    final writer = _ZipStoreWriter();
    final bytesWritten = await writer.write(
      outputFile: archiveFile,
      vaultPath: vaultDir.path,
      files: files,
    );

    return VaultBackupResult(
      archivePath: archiveFile.path,
      fileCount: files.length,
      bytesWritten: bytesWritten,
    );
  }

  String _backupFileName(DateTime now) {
    final local = now.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}'
        '${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}'
        '${local.minute.toString().padLeft(2, '0')}'
        '${local.second.toString().padLeft(2, '0')}';
    return 'akasha-vault-backup-$date-$time.zip';
  }

  Future<List<File>> _collectFiles({
    required String vaultPath,
    required String outputDirectory,
    required String archivePath,
  }) async {
    final normalizedVault = p.normalize(p.absolute(vaultPath));
    final normalizedOutput = p.normalize(p.absolute(outputDirectory));
    final normalizedArchive = p.normalize(p.absolute(archivePath));
    final outputSubdirInsideVault =
        p.isWithin(normalizedVault, normalizedOutput) &&
        !p.equals(normalizedVault, normalizedOutput);
    final files = <File>[];

    await for (final entity in Directory(
      normalizedVault,
    ).list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final normalizedPath = p.normalize(p.absolute(entity.path));
      if (normalizedPath == normalizedArchive) continue;
      if (outputSubdirInsideVault &&
          p.isWithin(normalizedOutput, normalizedPath)) {
        continue;
      }
      if (_shouldSkip(normalizedVault, normalizedPath)) continue;
      files.add(entity);
    }

    files.sort((a, b) {
      final ar = _relativeZipPath(normalizedVault, a.path);
      final br = _relativeZipPath(normalizedVault, b.path);
      return ar.compareTo(br);
    });
    return files;
  }

  bool _shouldSkip(String vaultPath, String absolutePath) {
    final relative = p.relative(absolutePath, from: vaultPath);
    final parts = p.split(relative);
    if (parts.any(_skipDirNames.contains)) return true;
    final basename = p.basename(absolutePath);
    return basename.startsWith('.akasha_') && basename.endsWith('.tmp');
  }
}

class _ZipStoreWriter {
  Future<int> write({
    required File outputFile,
    required String vaultPath,
    required List<File> files,
  }) async {
    final parent = outputFile.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final temp = File('${outputFile.path}.tmp');
    final sink = temp.openWrite();
    final entries = <_ZipCentralEntry>[];
    var offset = 0;

    try {
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final stat = await file.stat();
        final name = _relativeZipPath(vaultPath, file.path);
        final nameBytes = utf8.encode(name);
        final crc = _crc32(bytes);
        _assertZip32(bytes.length, 'file size');
        _assertZip32(offset, 'zip offset');

        final dosTime = _DosDateTime.fromDateTime(stat.modified);
        final localHeader = _localFileHeader(
          nameBytes: nameBytes,
          crc32: crc,
          size: bytes.length,
          dosTime: dosTime,
        );
        sink.add(localHeader);
        offset += localHeader.length;
        sink.add(bytes);
        final localOffset = offset - localHeader.length;
        offset += bytes.length;

        entries.add(
          _ZipCentralEntry(
            nameBytes: nameBytes,
            crc32: crc,
            size: bytes.length,
            localHeaderOffset: localOffset,
            dosTime: dosTime,
          ),
        );
      }

      final centralDirectoryOffset = offset;
      for (final entry in entries) {
        final header = _centralDirectoryHeader(entry);
        sink.add(header);
        offset += header.length;
      }
      final centralDirectorySize = offset - centralDirectoryOffset;
      _assertZip32(centralDirectoryOffset, 'central directory offset');
      _assertZip32(centralDirectorySize, 'central directory size');

      final end = _endOfCentralDirectory(
        entryCount: entries.length,
        centralDirectoryOffset: centralDirectoryOffset,
        centralDirectorySize: centralDirectorySize,
      );
      sink.add(end);
      offset += end.length;
      await sink.close();

      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      await temp.rename(outputFile.path);
      return offset;
    } catch (_) {
      await sink.close();
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Uint8List _localFileHeader({
    required List<int> nameBytes,
    required int crc32,
    required int size,
    required _DosDateTime dosTime,
  }) {
    final builder = BytesBuilder(copy: false);
    builder.add(_u32(0x04034b50));
    builder.add(_u16(20));
    builder.add(_u16(0x0800));
    builder.add(_u16(0));
    builder.add(_u16(dosTime.time));
    builder.add(_u16(dosTime.date));
    builder.add(_u32(crc32));
    builder.add(_u32(size));
    builder.add(_u32(size));
    builder.add(_u16(nameBytes.length));
    builder.add(_u16(0));
    builder.add(nameBytes);
    return builder.takeBytes();
  }

  Uint8List _centralDirectoryHeader(_ZipCentralEntry entry) {
    final builder = BytesBuilder(copy: false);
    builder.add(_u32(0x02014b50));
    builder.add(_u16(20));
    builder.add(_u16(20));
    builder.add(_u16(0x0800));
    builder.add(_u16(0));
    builder.add(_u16(entry.dosTime.time));
    builder.add(_u16(entry.dosTime.date));
    builder.add(_u32(entry.crc32));
    builder.add(_u32(entry.size));
    builder.add(_u32(entry.size));
    builder.add(_u16(entry.nameBytes.length));
    builder.add(_u16(0));
    builder.add(_u16(0));
    builder.add(_u16(0));
    builder.add(_u16(0));
    builder.add(_u32(0));
    builder.add(_u32(entry.localHeaderOffset));
    builder.add(entry.nameBytes);
    return builder.takeBytes();
  }

  Uint8List _endOfCentralDirectory({
    required int entryCount,
    required int centralDirectoryOffset,
    required int centralDirectorySize,
  }) {
    if (entryCount > 0xFFFF) {
      throw StateError('ZIP64 is not supported for more than 65535 files');
    }
    final builder = BytesBuilder(copy: false);
    builder.add(_u32(0x06054b50));
    builder.add(_u16(0));
    builder.add(_u16(0));
    builder.add(_u16(entryCount));
    builder.add(_u16(entryCount));
    builder.add(_u32(centralDirectorySize));
    builder.add(_u32(centralDirectoryOffset));
    builder.add(_u16(0));
    return builder.takeBytes();
  }

  Uint8List _u16(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  Uint8List _u32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  int _crc32(List<int> bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc ^= byte;
      for (var i = 0; i < 8; i += 1) {
        final mask = -(crc & 1);
        crc = (crc >> 1) ^ (0xEDB88320 & mask);
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  void _assertZip32(int value, String label) {
    if (value > 0xFFFFFFFF) {
      throw StateError('ZIP64 is not supported for $label > 4GB');
    }
  }
}

class _ZipCentralEntry {
  const _ZipCentralEntry({
    required this.nameBytes,
    required this.crc32,
    required this.size,
    required this.localHeaderOffset,
    required this.dosTime,
  });

  final List<int> nameBytes;
  final int crc32;
  final int size;
  final int localHeaderOffset;
  final _DosDateTime dosTime;
}

class _DosDateTime {
  const _DosDateTime({required this.date, required this.time});

  final int date;
  final int time;

  factory _DosDateTime.fromDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final year = local.year < 1980 ? 1980 : local.year;
    final date = ((year - 1980) << 9) | (local.month << 5) | local.day;
    final time = (local.hour << 11) | (local.minute << 5) | (local.second ~/ 2);
    return _DosDateTime(date: date, time: time);
  }
}

String _relativeZipPath(String vaultPath, String absolutePath) {
  return p
      .relative(
        p.normalize(p.absolute(absolutePath)),
        from: p.normalize(p.absolute(vaultPath)),
      )
      .replaceAll('\\', '/');
}
