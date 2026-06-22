import '../../models/akasha_item.dart';
import '../../models/user_catalog_entity.dart';

/// Preview stack frame — Work 또는 Entity 단일 프레임.
sealed class PreviewFrame {
  const PreviewFrame();
}

class WorkPreviewFrame extends PreviewFrame {
  const WorkPreviewFrame(this.item);

  final AkashaItem item;
}

class EntityPreviewFrame extends PreviewFrame {
  const EntityPreviewFrame(this.entity);

  final UserCatalogEntity entity;
}
