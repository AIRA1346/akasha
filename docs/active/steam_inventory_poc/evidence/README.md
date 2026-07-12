# GetReport evidence (admin only)

Raw and redacted GetReport outputs land here after:

```bash
dart run tool/steam_get_report.dart --fixture tool/fixtures/steam_getreport_settlement.json
# or with STEAM_PUBLISHER_WEB_API_KEY:
# dart run tool/steam_get_report.dart --type SETTLEMENT --time 2026-07-01T00:00:00Z
```

Do not commit Publisher keys. Prefer committing **redacted** samples only when needed for review packs.
