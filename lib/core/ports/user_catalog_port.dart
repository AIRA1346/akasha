import '../../models/enums.dart';
import '../../models/user_catalog_entity.dart';

abstract class UserCatalogPort {
  Future<void> load();

  List<UserCatalogEntity> get all;

  List<UserCatalogEntity> search(String query, {MediaCategory? subtype});

  UserCatalogEntity? getById(String entityId);

  Future<void> upsert(UserCatalogEntity entity);

  Future<void> remove(String entityId);

  Stream<void> get onChanged;
}
