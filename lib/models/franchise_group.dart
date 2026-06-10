import '../config/catalog_locale.dart';
import 'external_ids.dart';
import '../utils/work_title_resolver.dart';

class FranchiseGroup {
  final String id;
  final String displayName;
  final Map<String, String> displayNames;
  final ExternalIds externalIds;
  final List<String> members;
  final String primaryWorkId;

  const FranchiseGroup({
    required this.id,
    required this.displayName,
    this.displayNames = const {},
    this.externalIds = const ExternalIds(),
    required this.members,
    required this.primaryWorkId,
  });

  String? get wikidataQid => externalIds['wikidata'];

  String localizedDisplayName([CatalogLocale? locale]) {
    return resolveFranchiseDisplayName(
      legacyDisplayName: displayName,
      displayNames: displayNames,
      locale: locale ?? CatalogLocaleScope.current,
    );
  }

  factory FranchiseGroup.fromJson(String id, Map<String, dynamic> json) {
    final members = (json['members'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final names = <String, String>{};
    final rawNames = json['displayNames'];
    if (rawNames is Map) {
      rawNames.forEach((key, value) {
        final tag = key?.toString() ?? '';
        final text = value?.toString().trim() ?? '';
        if (tag.isNotEmpty && text.isNotEmpty) names[tag] = text;
      });
    }

    return FranchiseGroup(
      id: id,
      displayName: json['displayName']?.toString() ?? id,
      displayNames: names,
      externalIds: ExternalIds.fromJson(json['externalIds']),
      members: members,
      primaryWorkId: json['primaryWorkId']?.toString() ?? members.first,
    );
  }
}
