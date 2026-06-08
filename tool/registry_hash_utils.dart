/// akasha-db v4 — 해시 샤드 키·무결성 (도구·CI 공용)
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// v4 기본 — 256 샤드/카테고리
const defaultShardBits = 8;

final v4ShardHexPattern = RegExp(r'^[0-9a-f]{2}$');

/// `sha256(workId).bytes[0] & mask` — 균등 분포 0..(2^bits-1)
int shardIndexForWorkId(String workId, {int shardBits = defaultShardBits}) {
  if (workId.isEmpty) {
    throw ArgumentError('workId must not be empty');
  }
  if (shardBits < 1 || shardBits > 16) {
    throw ArgumentError('shardBits out of range: $shardBits');
  }
  final digest = sha256.convert(utf8.encode(workId));
  final mask = (1 << shardBits) - 1;
  if (shardBits <= 8) {
    return digest.bytes[0] & mask;
  }
  final combined = (digest.bytes[0] << 8) | digest.bytes[1];
  return combined & mask;
}

/// 8bit → `00`..`ff` (소문자)
String shardHexKey(int index, {int shardBits = defaultShardBits}) {
  final hexDigits = (shardBits + 3) ~/ 4;
  final max = 1 << shardBits;
  if (index < 0 || index >= max) {
    throw ArgumentError('shard index out of range: $index');
  }
  return index.toRadixString(16).padLeft(hexDigits, '0');
}

String shardHexForWorkId(String workId, {int shardBits = defaultShardBits}) {
  return shardHexKey(shardIndexForWorkId(workId, shardBits: shardBits),
      shardBits: shardBits);
}

String v4ShardId(String category, String hexKey) => '${category}_$hexKey';

String v4ShardPath(String category, String hexKey) =>
    'shards/$category/$hexKey.json';

/// 파일·JSON 본문 SHA-256 (hex, 소문자)
String sha256HexUtf8(String content) {
  return sha256.convert(utf8.encode(content)).toString();
}

bool isV4ShardFileName(String baseName) =>
    v4ShardHexPattern.hasMatch(baseName.toLowerCase());
