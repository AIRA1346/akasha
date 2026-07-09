// ignore_for_file: avoid_print
// akasha-db/contributions/status.json 갱신 (서버비 0원 — GitHub가 SoT)
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const statusIndexRelativePath = 'akasha-db/contributions/status.json';

const validStatusNames = {
  'submitted',
  'ai_verified',
  'accepted',
  'rejected',
  'merged',
};

String repoKindSegment(String kind) =>
    kind == 'fixWork' ? 'fix' : 'add';

String repoFolderForStatus(String status) {
  switch (status) {
    case 'accepted':
      return 'accepted';
    case 'rejected':
      return 'rejected';
    case 'merged':
      return 'merged';
    case 'ai_verified':
    case 'submitted':
    default:
      return 'pending';
  }
}

String contributionRepoPath({
  required String kind,
  required String status,
  required String id,
}) {
  final segment = repoKindSegment(kind);
  final folder = repoFolderForStatus(status);
  return p.join('contributions', segment, folder, '$id.json');
}

File statusIndexFile(Directory projectRoot) =>
    File('${projectRoot.path}/$statusIndexRelativePath');

Map<String, dynamic> readStatusIndex(Directory projectRoot) {
  final file = statusIndexFile(projectRoot);
  if (!file.existsSync()) {
    return {
      'version': 1,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': <String, dynamic>{},
    };
  }
  final decoded = json.decode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Invalid status.json');
  }
  decoded.putIfAbsent('entries', () => <String, dynamic>{});
  return decoded;
}

void writeStatusIndex(Directory projectRoot, Map<String, dynamic> index) {
  index['generatedAt'] = DateTime.now().toUtc().toIso8601String();
  final file = statusIndexFile(projectRoot);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(index));
}

void upsertStatusEntry(
  Map<String, dynamic> index,
  Map<String, dynamic> contribution,
) {
  final id = contribution['id']?.toString() ?? '';
  if (id.isEmpty) return;
  final kind = contribution['kind']?.toString() ?? 'addWork';
  final status = contribution['status']?.toString() ?? 'submitted';
  final entries = index['entries'] as Map<String, dynamic>;
  entries[id] = {
    'status': status,
    'kind': kind,
    'path': contributionRepoPath(kind: kind, status: status, id: id),
    'updatedAt': contribution['updatedAt']?.toString() ??
        contribution['createdAt']?.toString() ??
        DateTime.now().toUtc().toIso8601String(),
  };
}
