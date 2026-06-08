/// Discovery Layer 타입 — Signal은 일회성, Registry는 영구.
///
/// AniList는 Discovery Source이지 Canonical Source가 아님.
/// AKASHA identity = wk_.
library;

/// official_sync가 허용하는 Fact 필드 (data-policy + discovery-policy)
const discoveryAllowedFactKeys = {
  'externalId',
  'title',
  'titles',
  'releaseYear',
  'creator',
  'format',
  'category',
  'domain',
  'aliases',
};

/// Signal·Registry에 절대 남기지 않는 필드
const discoveryForbiddenFactKeys = {
  'description',
  'synopsis',
  'overview',
  'tags',
  'coverImage',
  'bannerImage',
  'characters',
  'popularity',
  'score',
  'favourites',
  'averageScore',
  'meanScore',
  'siteUrl',
  'relations',
  'rawResponse',
  'apiResponse',
  'edges',
  'nodes',
};

/// Discovery 성공 KPI (수집량이 아님)
class DiscoveryRunKpi {
  final int signalsFetched;
  final int signalsNew;
  final int wkCreated;
  final int dedupeRejected;
  final int policyRejected;

  const DiscoveryRunKpi({
    this.signalsFetched = 0,
    this.signalsNew = 0,
    this.wkCreated = 0,
    this.dedupeRejected = 0,
    this.policyRejected = 0,
  });

  int get policyViolations => policyRejected;

  double get dedupePassRate =>
      signalsNew == 0 ? 1.0 : wkCreated / signalsNew;

  DiscoveryRunKpi merge(DiscoveryRunKpi other) => DiscoveryRunKpi(
        signalsFetched: signalsFetched + other.signalsFetched,
        signalsNew: signalsNew + other.signalsNew,
        wkCreated: wkCreated + other.wkCreated,
        dedupeRejected: dedupeRejected + other.dedupeRejected,
        policyRejected: policyRejected + other.policyRejected,
      );

  Map<String, dynamic> toJson() => {
        'signalsFetched': signalsFetched,
        'signalsNew': signalsNew,
        'wkCreated': wkCreated,
        'dedupeRejected': dedupeRejected,
        'policyRejected': policyRejected,
        'dedupePassRate': dedupePassRate,
      };
}

/// 일회성 존재 신호 — Git·Registry에 raw로 저장하지 않음
class DiscoverySignal {
  final String channelId;
  final String source;
  final String externalId;
  final String category;
  final String domain;
  final DiscoveryFacts facts;
  final DateTime discoveredAt;

  const DiscoverySignal({
    required this.channelId,
    required this.source,
    required this.externalId,
    required this.category,
    required this.domain,
    required this.facts,
    required this.discoveredAt,
  });

  Map<String, dynamic> toEphemeralJson() => {
        'channelId': channelId,
        'source': source,
        'externalId': externalId,
        'category': category,
        'domain': domain,
        'facts': facts.toJson(),
        'discoveredAt': discoveredAt.toUtc().toIso8601String(),
      };
}

/// Signal이 carry하는 Facts만 (금지 필드 없음)
class DiscoveryFacts {
  final String title;
  final Map<String, String> titles;
  final int? releaseYear;
  final String creator;
  final List<String> aliases;
  final String? format;

  const DiscoveryFacts({
    required this.title,
    this.titles = const {},
    this.releaseYear,
    this.creator = '',
    this.aliases = const [],
    this.format,
  });

  bool get hasMinimalCoreIdentity =>
      title.isNotEmpty && (releaseYear != null || title.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'title': title,
        if (titles.isNotEmpty) 'titles': titles,
        if (releaseYear != null) 'releaseYear': releaseYear,
        if (creator.isNotEmpty) 'creator': creator,
        if (aliases.isNotEmpty) 'aliases': aliases,
        if (format != null && format!.isNotEmpty) 'format': format,
      };
}

/// manifest 채널 설정
class DiscoveryChannelConfig {
  final String id;
  final String source;
  final String category;
  final String domain;
  final bool enabled;
  final int dailyLimit;
  final int trialBatchSize;
  final String cursorPath;

  const DiscoveryChannelConfig({
    required this.id,
    required this.source,
    required this.category,
    required this.domain,
    required this.enabled,
    required this.dailyLimit,
    required this.trialBatchSize,
    required this.cursorPath,
  });
}

/// official_sync 1회 실행 결과
class OfficialSyncResult {
  final String channelId;
  final bool dryRun;
  final DiscoveryRunKpi kpi;
  final List<DiscoverySignal> signals;
  final List<String> errors;

  const OfficialSyncResult({
    required this.channelId,
    required this.dryRun,
    required this.kpi,
    this.signals = const [],
    this.errors = const [],
  });

  bool get ok => errors.isEmpty && kpi.policyViolations == 0;
}
