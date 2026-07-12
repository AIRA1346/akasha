# AKASHA Commerce Server

Deployable payment authority for Steam microtransactions.

**Not part of the Flutter client.** Publisher Web API keys, Steam HTTP adapters,
authoritative ledger / entitlement writes, and GetReport reconciliation live here
(or in a future separate repo that vendors this package).

## Boundary

| Flutter (`lib/`) | This package (`backend/`) |
|---|---|
| Auth ticket acquisition | `AuthenticateUserTicket` → verified SteamID |
| `CommerceApiClient` | Orders, ledger, InitTxn / FinalizeTxn / QueryTxn |
| UI | GetReport reconciliation worker |
| Shared DTOs via `akasha_commerce_domain` | Secrets from env / secret manager only |

## Local harness

```bash
cd backend/akasha_commerce_server
dart pub get
dart test
```

Production keys: set `STEAM_PUBLISHER_WEB_API_KEY` (and optional `STEAM_APP_ID`)
on the server only. Unit tests use `SteamPublisherCredentials.forLocalHarness()`.
