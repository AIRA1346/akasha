/// Collection vs search tag semantics — exact match for [tagsAll], substring for search.
abstract final class EntityTagSemantics {
  /// Exact set membership (AND). Empty [requiredTags] matches all entities.
  static bool matchesTagsAll(List<String> entityTags, List<String> requiredTags) {
    if (requiredTags.isEmpty) return true;
    final tagSet = entityTags.toSet();
    for (final required in requiredTags) {
      if (!tagSet.contains(required)) return false;
    }
    return true;
  }
}
