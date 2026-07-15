# Shared pure-Dart commerce domain (Astra/Echo)

Defines the approved product catalog, currency rules, provider-neutral account
snapshot, and the deferred ledger prototype shared by the Flutter app.

The v1 authority is Steam Inventory through `CommerceGateway`. The package
contains no Flutter UI, Steam secrets, ItemDef registration, or payment
authority. `backend/akasha_commerce_server` is a deferred alternative and may
still reuse the ledger-domain types later.
