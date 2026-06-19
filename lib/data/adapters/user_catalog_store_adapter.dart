import '../../models/enums.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/user_catalog_entity.dart';
import '../../services/user_catalog_store.dart';

class UserCatalogStoreAdapter implements UserCatalogPort {
  static final UserCatalogStoreAdapter _instance =
      UserCatalogStoreAdapter._internal();
  factory UserCatalogStoreAdapter() => _instance;
  UserCatalogStoreAdapter._internal();

  UserCatalogStore get _store => UserCatalogStore.instance;

  @override
  Future<void> load() => _store.load();

  @override
  List<UserCatalogEntity> get all => _store.all;

  @override
  List<UserCatalogEntity> search(String query, {MediaCategory? subtype}) =>
      _store.search(query, subtype: subtype);

  @override
  UserCatalogEntity? getById(String entityId) => _store.getById(entityId);

  @override
  Future<void> upsert(UserCatalogEntity entity) => _store.upsert(entity);

  @override
  Future<void> remove(String entityId) => _store.remove(entityId);

  @override
  Stream<void> get onChanged => _store.onChanged;
}
