/// Link-graph derived Work relation — not stored in catalog/tags SSOT.
class EntityRelatedWorks {
  final String entityId;
  final Set<String> workIds;

  const EntityRelatedWorks({
    required this.entityId,
    required this.workIds,
  });

  bool isRelatedTo(String workId) => workIds.contains(workId);
}
