/// Relation vocabulary for structured links (Spec §4.1).
///
/// The relation string is the meaning layer of the personal knowledge graph.
/// To keep it machine-reasonable over decades, conforming writers may only
/// use the fixed core vocabulary or user-defined relations under the `u:`
/// namespace. Readers preserve unrecognized legacy strings as-is.
abstract final class RelationVocabulary {
  /// Generic association — the default relation.
  static const String related = 'related';

  /// Fixed core relations (directional, source → target).
  ///
  /// Grows only through spec revisions (Additive-Only Evolution, Spec §5).
  static const Set<String> core = {
    related,
    'about', // source discusses/covers the target topic
    'appears_in', // person/place/object appears in the target work
    'created_by', // work/object was created by person/organization
    'part_of', // source is a component of the target
    'member_of', // person belongs to the target group
    'located_in', // source is physically located in the target place
    'inspired_by', // source draws influence from the target
  };

  static const String userNamespacePrefix = 'u:';

  static final RegExp _userTokenPattern = RegExp(r'^[a-z0-9_]{1,40}$');

  static bool isCore(String relation) => core.contains(relation.trim());

  /// Whether [relation] is a well-formed user-defined relation (`u:{token}`,
  /// token matching `[a-z0-9_]{1,40}`).
  static bool isUserNamespaced(String relation) {
    final value = relation.trim();
    if (!value.startsWith(userNamespacePrefix)) return false;
    return _userTokenPattern.hasMatch(
      value.substring(userNamespacePrefix.length),
    );
  }

  /// Whether [relation] may be written by a conforming v3 writer.
  static bool isConforming(String relation) =>
      isCore(relation) || isUserNamespaced(relation);
}
