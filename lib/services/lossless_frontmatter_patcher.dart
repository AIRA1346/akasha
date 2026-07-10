import 'package:yaml/yaml.dart';

/// Raised when AKASHA cannot safely patch a record without reconstructing or
/// discarding frontmatter it does not own.
class LosslessFrontmatterPatchException implements Exception {
  const LosslessFrontmatterPatchException({
    required this.message,
    required this.proposedContent,
  });

  final String message;
  final String proposedContent;

  @override
  String toString() => message;
}

/// Patches app-owned top-level YAML fields while retaining unknown source
/// frontmatter. It deliberately operates on frontmatter source segments rather
/// than serializing a reduced YAML map back to text.
abstract final class LosslessFrontmatterPatcher {
  static final RegExp _topLevelKey = RegExp(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:');

  static String patch({
    required String existingContent,
    required String proposedContent,
    required Set<String> ownedKeys,
  }) {
    final existing = _FrontmatterSplit.tryParse(existingContent);
    if (existing == null) return proposedContent;
    final proposed = _FrontmatterSplit.tryParse(proposedContent);
    if (proposed == null) {
      throw LosslessFrontmatterPatchException(
        message: 'AKASHA-generated frontmatter could not be patched safely.',
        proposedContent: proposedContent,
      );
    }

    _validateYaml(
      existing.frontmatter,
      message:
          'Existing frontmatter is malformed; original was not overwritten.',
      proposedContent: proposedContent,
    );
    _validateYaml(
      proposed.frontmatter,
      message:
          'Proposed frontmatter is malformed; original was not overwritten.',
      proposedContent: proposedContent,
    );

    final existingSegments = _segments(existing.frontmatter);
    final proposedSegments = _segments(proposed.frontmatter);
    final proposedByKey = {
      for (final segment in proposedSegments) segment.key: segment,
    };
    final emittedOwnedKeys = <String>{};
    final output = StringBuffer();
    output.write(_leadingSource(existing.frontmatter));

    for (final segment in existingSegments) {
      if (!ownedKeys.contains(segment.key)) {
        output.write(segment.raw);
        output.write(segment.trailingSource);
        continue;
      }

      final replacement = proposedByKey[segment.key];
      if (replacement != null) {
        output.write(replacement.raw);
        output.write(segment.trailingSource);
        emittedOwnedKeys.add(segment.key);
      }
      // The app intentionally removed this owned field. Unknown fields are
      // never removed through this branch.
    }

    for (final segment in proposedSegments) {
      if (!ownedKeys.contains(segment.key) ||
          emittedOwnedKeys.contains(segment.key)) {
        continue;
      }
      output.write(segment.raw);
      emittedOwnedKeys.add(segment.key);
    }

    final patchedFrontmatter = output.toString().trimRight();
    return '---\n$patchedFrontmatter\n---${proposed.bodyPrefix}${proposed.body}';
  }

  static void _validateYaml(
    String frontmatter, {
    required String message,
    required String proposedContent,
  }) {
    try {
      final parsed = loadYaml(frontmatter);
      if (parsed != null && parsed is! Map) {
        throw const FormatException('frontmatter must be a mapping');
      }
    } catch (_) {
      throw LosslessFrontmatterPatchException(
        message: message,
        proposedContent: proposedContent,
      );
    }
  }

  static List<_FrontmatterSegment> _segments(String frontmatter) {
    final lines = frontmatter.split('\n');
    final starts = <_SegmentStart>[];
    for (var index = 0; index < lines.length; index += 1) {
      final match = _topLevelKey.firstMatch(lines[index]);
      if (match != null) {
        starts.add(_SegmentStart(index, match.group(1)!));
      }
    }
    if (starts.isEmpty) return const [];

    final segments = <_FrontmatterSegment>[];
    for (var index = 0; index < starts.length; index += 1) {
      final start = starts[index];
      final end = index + 1 < starts.length
          ? starts[index + 1].line
          : lines.length;
      final sourceLines = lines.sublist(start.line, end);
      var trailingStart = sourceLines.length;
      while (trailingStart > 1 &&
          (sourceLines[trailingStart - 1].trim().isEmpty ||
              sourceLines[trailingStart - 1].trimLeft().startsWith('#'))) {
        trailingStart -= 1;
      }
      segments.add(
        _FrontmatterSegment(
          key: start.key,
          raw: '${sourceLines.sublist(0, trailingStart).join('\n')}\n',
          trailingSource: trailingStart < sourceLines.length
              ? '${sourceLines.sublist(trailingStart).join('\n')}\n'
              : '',
        ),
      );
    }
    return segments;
  }

  static String _leadingSource(String frontmatter) {
    final lines = frontmatter.split('\n');
    for (var index = 0; index < lines.length; index += 1) {
      if (_topLevelKey.hasMatch(lines[index])) {
        return index == 0 ? '' : '${lines.sublist(0, index).join('\n')}\n';
      }
    }
    return frontmatter.isEmpty ? '' : '$frontmatter\n';
  }
}

class _FrontmatterSplit {
  const _FrontmatterSplit({
    required this.frontmatter,
    required this.bodyPrefix,
    required this.body,
  });

  final String frontmatter;
  final String bodyPrefix;
  final String body;

  static _FrontmatterSplit? tryParse(String content) {
    final normalized = content.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return null;

    var end = -1;
    for (var index = 1; index < lines.length; index += 1) {
      if (lines[index].trim() == '---') {
        end = index;
        break;
      }
    }
    if (end < 0) return null;

    final bodyLines = lines.sublist(end + 1);
    final hasBodyPrefix = end + 1 < lines.length;
    return _FrontmatterSplit(
      frontmatter: lines.sublist(1, end).join('\n'),
      bodyPrefix: hasBodyPrefix ? '\n' : '',
      body: bodyLines.join('\n'),
    );
  }
}

class _SegmentStart {
  const _SegmentStart(this.line, this.key);
  final int line;
  final String key;
}

class _FrontmatterSegment {
  const _FrontmatterSegment({
    required this.key,
    required this.raw,
    required this.trailingSource,
  });
  final String key;
  final String raw;
  final String trailingSource;
}
