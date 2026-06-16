import 'package:flutter/widgets.dart';

import '../generated/l10n/app_localizations.dart';

/// [AppLocalizations.of]는 delegate 미등록 시 예외 — 테스트·위젯 단독 사용 대비.
AppLocalizations? lookupAppL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations);
