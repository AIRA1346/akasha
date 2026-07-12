/// Stable currency ids for ledger / DB / orders.
///
/// Display names (Astra / Echo) live in [CurrencyDisplay] and localization —
/// never store display strings as authority keys.
enum CurrencyKind {
  /// Paid currency. Display: Astra / 아스트라. UI qualifier: Paid / 유료.
  premium,

  /// Free-earned currency. Display: Echo / 에코. UI qualifier: Earned / 무료 획득.
  earned,
}

/// Localization/catalog surface for currency labels (UI only).
abstract final class CurrencyDisplay {
  static String name(CurrencyKind kind, {required String languageTag}) {
    final ko = languageTag.toLowerCase().startsWith('ko');
    return switch (kind) {
      CurrencyKind.premium => ko ? '아스트라' : 'Astra',
      CurrencyKind.earned => ko ? '에코' : 'Echo',
    };
  }

  static String qualifier(CurrencyKind kind, {required String languageTag}) {
    final ko = languageTag.toLowerCase().startsWith('ko');
    return switch (kind) {
      CurrencyKind.premium => ko ? '유료' : 'Paid',
      CurrencyKind.earned => ko ? '무료 획득' : 'Earned',
    };
  }

  /// e.g. `Astra (Paid)` / `아스트라 (유료)`.
  static String labeled(CurrencyKind kind, {required String languageTag}) =>
      '${name(kind, languageTag: languageTag)} (${qualifier(kind, languageTag: languageTag)})';
}
