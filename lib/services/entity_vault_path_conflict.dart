/// R2-C — 동일 vault path에 다른 entityId 저장 시도.
class EntityVaultPathConflict implements Exception {
  EntityVaultPathConflict({
    required this.existingEntityId,
    required this.incomingEntityId,
    required this.title,
    required this.path,
  });

  final String existingEntityId;
  final String incomingEntityId;
  final String title;
  final String path;

  /// R2-C — UI 표시용 (store layer는 변경 없음).
  String get userMessage =>
      '「$title」 Entity가 이미 아카이브되어 있습니다. '
      '같은 종류의 Entity에 동일한 제목이 이미 존재합니다.';

  @override
  String toString() =>
      'EntityVaultPathConflict(path: $path, title: "$title", '
      'existing: $existingEntityId, incoming: $incomingEntityId)';
}
