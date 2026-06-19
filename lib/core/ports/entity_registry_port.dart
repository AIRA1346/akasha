import '../archiving/entity_anchor.dart';
import '../../models/entity_fact.dart';

/// Global Entity Fact registry (Person MVP · Wave 4).
abstract class EntityRegistryPort {
  Future<void> init();

  List<EntityFact> search(String query, {EntityAnchorType? type});

  EntityFact? getById(String entityId);
}
