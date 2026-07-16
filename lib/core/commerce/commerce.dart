/// Shared commerce domain and provider boundaries (Astra/Echo).
///
/// Payment authority is **not** in this tree. The v1 path is Steam Inventory;
/// the custom HTTP backend remains an unwired, deferred alternative. See
/// `docs/active/COMMERCE_CURRENCY_CONTRACT.md`.
library;

export 'package:akasha_commerce_domain/akasha_commerce_domain.dart';

export 'client/commerce_api_client.dart';
export 'commerce_support_gateway.dart';
export 'steam_inventory/steam_inventory.dart';
