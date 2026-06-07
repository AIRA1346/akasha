import '../models/enums.dart';
import '../services/works_registry.dart';

/// Registry `extensions` 필드를 상세 UI용 텍스트로 변환
List<String> formatRegistryExtensionLines(RegistryWork work) {
  if (work.extensions.isEmpty) return const [];

  final lines = <String>[];

  switch (work.category) {
    case MediaCategory.game:
      final platforms = work.extensions['platforms'];
      if (platforms is List && platforms.isNotEmpty) {
        lines.add('플랫폼: ${platforms.map((e) => e.toString()).join(' · ')}');
      }
      final steamAppId = work.extensions['steamAppId'];
      if (steamAppId != null) {
        lines.add('Steam App ID: $steamAppId');
      }
    case MediaCategory.book:
      final isbn = work.extensions['isbn'];
      if (isbn != null && isbn.toString().isNotEmpty) {
        lines.add('ISBN: $isbn');
      }
    default:
      break;
  }

  return lines;
}
