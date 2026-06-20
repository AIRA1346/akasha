/// R2-B — Entity link picker 선택 결과.
class EntityLinkSelection {
  const EntityLinkSelection({
    required this.entityId,
    required this.title,
    required this.entityType,
  });

  final String entityId;
  final String title;
  final String entityType;

  /// Canonical vault token — [link-identity-policy.md].
  String get canonicalWikiToken => '[[$entityId|$title]]';
}
