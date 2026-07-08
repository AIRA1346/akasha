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

  /// Recommended presets for canvas-only relations (Spec §4.1 u: namespace).
  static const Set<String> recommendedCanvasRelations = {
    'u:rival_of',
    'u:ally_of',
    'u:friend_of',
    'u:family_of',
    'u:mentor_of',
    'u:subordinate_of',
    'u:successor_of',
    'u:protects',
    'u:loves',
    'u:enemy_of',
    'u:adapted_from',
    'u:symbolizes',
  };

  /// UI presentation mapping of relation tokens to Korean display names.
  static const Map<String, String> displayLabels = {
    'related': '단순 관련성',
    'about': '주제 / 논함',
    'appears_in': '등장인물 / 등장장소',
    'created_by': '창작자 / 제작자',
    'part_of': '하위 부분 / 소속',
    'member_of': '구성원 / 멤버',
    'located_in': '위치함',
    'inspired_by': '영감을 받음',
    // Presets
    'u:rival_of': '대립 / 라이벌',
    'u:ally_of': '동맹 / 협력',
    'u:friend_of': '친구 / 동료',
    'u:family_of': '가족 / 친족',
    'u:mentor_of': '스승 / 멘토',
    'u:subordinate_of': '부하 / 종속',
    'u:successor_of': '계승 / 후계',
    'u:protects': '보호함',
    'u:loves': '애정 / 호감',
    'u:enemy_of': '적대',
    'u:adapted_from': '각색 / 원작 기반',
    'u:symbolizes': '상징함',
  };

  /// Translates a relation token to its localized Korean display label,
  /// falling back to the raw token if mapping is not found.
  @Deprecated('Use RelationLocalizer in the UI layer instead')
  static String displayLabelFor(String? relation) {
    if (relation == null) return '';
    return displayLabels[relation] ?? relation;
  }
}
