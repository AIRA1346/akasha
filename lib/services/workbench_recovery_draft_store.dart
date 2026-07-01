import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

enum WorkbenchRecoveryRecordKind { work, entity }

class WorkbenchRecoveryDraft {
  const WorkbenchRecoveryDraft({
    required this.kind,
    required this.recordId,
    required this.updatedAt,
    required this.bodyText,
    required this.fileText,
    this.title,
    this.posterPath,
    this.tags = const [],
    this.pageView,
    this.rating,
    this.workStatus,
    this.myStatus,
    this.hallOfFame,
  });

  final WorkbenchRecoveryRecordKind kind;
  final String recordId;
  final DateTime updatedAt;
  final String bodyText;
  final String fileText;
  final String? title;
  final String? posterPath;
  final List<String> tags;
  final String? pageView;
  final double? rating;
  final String? workStatus;
  final String? myStatus;
  final bool? hallOfFame;

  bool hasSameText({required String body, required String file}) =>
      bodyText == body && fileText == file;

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'kind': kind.name,
    'recordId': recordId,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'bodyText': bodyText,
    'fileText': fileText,
    if (title != null) 'title': title,
    if (posterPath != null) 'posterPath': posterPath,
    'tags': tags,
    if (pageView != null) 'pageView': pageView,
    if (rating != null) 'rating': rating,
    if (workStatus != null) 'workStatus': workStatus,
    if (myStatus != null) 'myStatus': myStatus,
    if (hallOfFame != null) 'hallOfFame': hallOfFame,
  };

  factory WorkbenchRecoveryDraft.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind']?.toString() ?? '';
    final kind = WorkbenchRecoveryRecordKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => WorkbenchRecoveryRecordKind.work,
    );
    return WorkbenchRecoveryDraft(
      kind: kind,
      recordId: json['recordId']?.toString() ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      bodyText: json['bodyText']?.toString() ?? '',
      fileText: json['fileText']?.toString() ?? '',
      title: json['title']?.toString(),
      posterPath: json['posterPath']?.toString(),
      tags:
          (json['tags'] as List?)
              ?.map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList() ??
          const [],
      pageView: json['pageView']?.toString(),
      rating: double.tryParse(json['rating']?.toString() ?? ''),
      workStatus: json['workStatus']?.toString(),
      myStatus: json['myStatus']?.toString(),
      hallOfFame: json['hallOfFame'] is bool
          ? json['hallOfFame'] as bool
          : null,
    );
  }
}

class WorkbenchRecoveryDraftStore {
  const WorkbenchRecoveryDraftStore();

  static const recoveryDirName = 'recovery';

  Future<WorkbenchRecoveryDraft?> load({
    required String vaultPath,
    required WorkbenchRecoveryRecordKind kind,
    required String recordId,
  }) async {
    final file = _draftFile(
      vaultPath: vaultPath,
      kind: kind,
      recordId: recordId,
    );
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) return null;
    final draft = WorkbenchRecoveryDraft.fromJson(decoded);
    if (draft.kind != kind || draft.recordId != recordId) return null;
    return draft;
  }

  Future<File> save({
    required String vaultPath,
    required WorkbenchRecoveryDraft draft,
  }) async {
    final file = _draftFile(
      vaultPath: vaultPath,
      kind: draft.kind,
      recordId: draft.recordId,
    );
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(draft.toJson()),
      flush: true,
    );
    if (await file.exists()) {
      await file.delete();
    }
    return temp.rename(file.path);
  }

  Future<void> delete({
    required String vaultPath,
    required WorkbenchRecoveryRecordKind kind,
    required String recordId,
  }) async {
    final file = _draftFile(
      vaultPath: vaultPath,
      kind: kind,
      recordId: recordId,
    );
    if (await file.exists()) {
      await file.delete();
    }
  }

  File _draftFile({
    required String vaultPath,
    required WorkbenchRecoveryRecordKind kind,
    required String recordId,
  }) {
    return File(
      p.join(
        vaultPath,
        '.akasha',
        recoveryDirName,
        '${kind.name}_${_safeRecordId(recordId)}.json',
      ),
    );
  }

  String _safeRecordId(String recordId) {
    final safe = recordId
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^[._]+|[._]+$'), '');
    if (safe.isNotEmpty) return safe;
    return base64Url.encode(utf8.encode(recordId)).replaceAll('=', '');
  }
}
