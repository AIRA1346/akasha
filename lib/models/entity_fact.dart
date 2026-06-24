import '../core/archiving/entity_anchor.dart';
import 'enums.dart';
import 'registry_work.dart';

/// Tier 1 global Entity Fact (Person · Concept …) — Wave 4.
class EntityFact {
  const EntityFact({
    required this.entityId,
    required this.entityType,
    required this.title,
    this.aliases = const [],
    this.description = '',
  });

  final String entityId;
  final EntityAnchorType entityType;
  final String title;
  final List<String> aliases;
  final String description;

  EntityAnchorType get anchorType => entityType;

  factory EntityFact.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['entityType']?.toString() ?? 'person';
    EntityAnchorType type = EntityAnchorType.person;
    for (final t in EntityAnchorType.values) {
      if (t.name == typeRaw) {
        type = t;
        break;
      }
    }

    return EntityFact(
      entityId: json['entityId']?.toString() ?? '',
      entityType: type,
      title: json['title']?.toString() ?? '',
      aliases: (json['aliases'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      description: json['description']?.toString() ?? '',
    );
  }

  RegistryWork toRegistryWork() {
    return RegistryWork(
      workId: entityId,
      title: title,
      aliases: aliases,
      category: MediaCategory.book,
      domain: AppDomain.subculture,
      description: description,
      extensions: {
        'globalEntityFact': true,
        'entityType': entityType.name,
      },
    );
  }

  bool matchesQuery(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return false;
    final q = normalizedQuery.toLowerCase();
    if (title.toLowerCase().contains(q)) return true;
    for (final alias in aliases) {
      if (alias.toLowerCase().contains(q)) return true;
    }
    if (description.toLowerCase().contains(q)) return true;
    return false;
  }
}
