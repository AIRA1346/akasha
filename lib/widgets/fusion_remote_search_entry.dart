import '../core/archiving/entity_anchor.dart';
import '../models/registry_work.dart';
import '../services/registry_visibility_service.dart';

class FusionRemoteSearchEntry {
  final RegistryWork work;
  final RegistryRemoteHint hint;
  final bool isUserLocal;
  final EntityAnchorType entityType;
  final bool catalogOnly;

  const FusionRemoteSearchEntry({
    required this.work,
    required this.hint,
    this.isUserLocal = false,
    this.entityType = EntityAnchorType.work,
    this.catalogOnly = false,
  });
}
