import '../../../../core/archiving/record_kind.dart';
import '../../../../services/record_summary_index_service.dart';

enum HomeArchiveActivityKind { added, updated }

class HomeArchiveActivity {
  const HomeArchiveActivity({
    required this.recordId,
    required this.title,
    required this.recordKind,
    required this.kind,
    required this.occurredAt,
  });

  final String recordId;
  final String title;
  final RecordKind recordKind;
  final HomeArchiveActivityKind kind;
  final DateTime occurredAt;
}

class HomeArchiveActivityData {
  const HomeArchiveActivityData({
    required this.vaultAvailable,
    required this.todayCount,
    required this.items,
  });

  static const unavailable = HomeArchiveActivityData(
    vaultAvailable: false,
    todayCount: 0,
    items: [],
  );

  final bool vaultAvailable;
  final int todayCount;
  final List<HomeArchiveActivity> items;
}

Future<HomeArchiveActivityData> loadHomeArchiveActivity({
  required String? vaultPath,
  required RecordSummaryIndexService recordIndex,
  required DateTime now,
  int limit = 3,
}) async {
  final normalizedPath = vaultPath?.trim() ?? '';
  if (normalizedPath.isEmpty) return HomeArchiveActivityData.unavailable;

  final activities = <HomeArchiveActivity>[];
  for (final summary in await recordIndex.load(normalizedPath)) {
    final addedAt = summary.addedAt;
    final updatedAt = summary.updatedAt;
    final occurredAt = _latest(addedAt, updatedAt);
    if (occurredAt == null || !_sameLocalDay(occurredAt, now)) continue;

    final isMeaningfulUpdate =
        updatedAt != null &&
        (addedAt == null ||
            updatedAt.toUtc().isAfter(
              addedAt.toUtc().add(const Duration(minutes: 1)),
            ));
    activities.add(
      HomeArchiveActivity(
        recordId: summary.id,
        title: summary.title,
        recordKind: summary.recordKind,
        kind: isMeaningfulUpdate
            ? HomeArchiveActivityKind.updated
            : HomeArchiveActivityKind.added,
        occurredAt: occurredAt,
      ),
    );
  }

  activities.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return HomeArchiveActivityData(
    vaultAvailable: true,
    todayCount: activities.length,
    items: activities.take(limit).toList(growable: false),
  );
}

DateTime? _latest(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}

bool _sameLocalDay(DateTime value, DateTime now) {
  final localValue = value.toLocal();
  final localNow = now.toLocal();
  return localValue.year == localNow.year &&
      localValue.month == localNow.month &&
      localValue.day == localNow.day;
}
