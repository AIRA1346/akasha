enum TasteSignalType { rating, status, tag, favorite, memo, quote, link }

class TasteSignal {
  const TasteSignal({
    required this.signalId,
    required this.signalType,
    required this.sourceRecordId,
    required this.sourceRecordKind,
    required this.targetId,
    required this.targetKind,
    required this.weight,
    required this.evidencePath,
    required this.evidenceField,
    this.value,
    this.snippet,
    this.updatedAt,
  });

  final String signalId;
  final TasteSignalType signalType;
  final String sourceRecordId;
  final String sourceRecordKind;
  final String targetId;
  final String targetKind;
  final Object? value;
  final double weight;
  final String evidencePath;
  final String evidenceField;
  final String? snippet;
  final DateTime? updatedAt;

  factory TasteSignal.fromJson(Map<String, dynamic> json) {
    return TasteSignal(
      signalId: json['signalId']?.toString() ?? '',
      signalType: _signalTypeFromJson(json['signalType']?.toString()),
      sourceRecordId: json['sourceRecordId']?.toString() ?? '',
      sourceRecordKind: json['sourceRecordKind']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      targetKind: json['targetKind']?.toString() ?? '',
      value: json['value'],
      weight: _double(json['weight']) ?? 0,
      evidencePath: json['evidencePath']?.toString() ?? '',
      evidenceField: json['evidenceField']?.toString() ?? '',
      snippet: _jsonString(json['snippet']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'signalId': signalId,
    'signalType': signalType.name,
    'sourceRecordId': sourceRecordId,
    'sourceRecordKind': sourceRecordKind,
    'targetId': targetId,
    'targetKind': targetKind,
    if (value != null) 'value': value,
    'weight': weight,
    'evidencePath': evidencePath,
    'evidenceField': evidenceField,
    if (snippet != null && snippet!.isNotEmpty) 'snippet': snippet,
    if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
  };
}

class TasteIndex {
  const TasteIndex({required this.generatedAt, required this.signals});

  final DateTime? generatedAt;
  final List<TasteSignal> signals;

  static const empty = TasteIndex(generatedAt: null, signals: []);

  factory TasteIndex.fromJson(Map<String, dynamic> json) {
    final rawSignals = json['signals'];
    return TasteIndex(
      generatedAt: _date(json['generatedAt']),
      signals: rawSignals is List
          ? rawSignals
                .whereType<Map>()
                .map(
                  (raw) => TasteSignal.fromJson(Map<String, dynamic>.from(raw)),
                )
                .where(
                  (signal) =>
                      signal.signalId.isNotEmpty &&
                      signal.sourceRecordId.isNotEmpty &&
                      signal.evidencePath.isNotEmpty,
                )
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson({required int version}) => {
    'version': version,
    'storage': 'tasteIndex',
    if (generatedAt != null) 'generatedAt': generatedAt!.toIso8601String(),
    'signals': signals.map((signal) => signal.toJson()).toList(),
    'targetIndex': buildTargetIndex(signals),
    'sourceIndex': buildSourceIndex(signals),
  };

  List<TasteSignal> signalsForTarget(String targetId) => signals
      .where((signal) => signal.targetId == targetId)
      .toList(growable: false);

  List<TasteSignal> signalsForSource(String sourceRecordId) => signals
      .where((signal) => signal.sourceRecordId == sourceRecordId)
      .toList(growable: false);

  static Map<String, List<String>> buildTargetIndex(List<TasteSignal> signals) {
    final index = <String, Set<String>>{};
    for (final signal in signals) {
      index.putIfAbsent(signal.targetId, () => <String>{}).add(signal.signalId);
    }
    return _sortedStringListMap(index);
  }

  static Map<String, List<String>> buildSourceIndex(List<TasteSignal> signals) {
    final index = <String, Set<String>>{};
    for (final signal in signals) {
      index
          .putIfAbsent(signal.sourceRecordId, () => <String>{})
          .add(signal.signalId);
    }
    return _sortedStringListMap(index);
  }
}

TasteSignalType _signalTypeFromJson(String? raw) {
  for (final type in TasteSignalType.values) {
    if (type.name == raw) return type;
  }
  return TasteSignalType.memo;
}

Map<String, List<String>> _sortedStringListMap(Map<String, Set<String>> input) {
  final keys = input.keys.toList()..sort();
  return {for (final key in keys) key: (input[key]!.toList()..sort())};
}

String? _jsonString(Object? raw) {
  final value = raw?.toString();
  return value == null || value.isEmpty ? null : value;
}

double? _double(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}

DateTime? _date(Object? raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString())?.toUtc();
}
