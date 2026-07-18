// ignore_for_file: avoid_print

import 'dart:io';

import 'registry_bundle_contract.dart';

void main(List<String> args) {
  try {
    final parsed = _Arguments.parse(args);
    if (parsed.help) {
      print(_usage);
      return;
    }
    final spec = RegistryBundleSpec(
      source: Directory(parsed.source!),
      output: Directory(parsed.output!),
      mode: parsed.mode!,
      sourceRevision: parsed.sourceRevision!,
      releaseId: parsed.releaseId,
    );
    final builder = const RegistryBundleBuilder();
    final audit = parsed.verifyOnly
        ? builder.verify(spec)
        : builder.build(spec);
    print(parsed.verifyOnly ? 'OK: bundle verified' : 'OK: bundle generated');
    print('  source: ${spec.source.path}');
    print('  output: ${spec.output.path}');
    print('  mode: ${audit.bundleMode}');
    print('  releaseId: ${audit.releaseId}');
    print('  sourceRevision: ${audit.sourceRevision}');
    print('  works: ${audit.entryCount}');
    print('  shards: ${audit.bundledShardCount}/${audit.manifestShardCount}');
    print('  files: ${audit.bundleAssetFileCount}');
    print('  bytes: ${audit.bundleAssetBytes}');
    print('  digest: ${registryDirectoryDigest(spec.output)}');
  } on RegistryBundleValidationException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } on ArgumentError catch (error) {
    stderr.writeln('ERROR: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  }
}

class _Arguments {
  const _Arguments({
    required this.source,
    required this.output,
    required this.sourceRevision,
    required this.releaseId,
    required this.mode,
    required this.verifyOnly,
    required this.help,
  });

  final String? source;
  final String? output;
  final String? sourceRevision;
  final String? releaseId;
  final RegistryBundleMode? mode;
  final bool verifyOnly;
  final bool help;

  static _Arguments parse(List<String> args) {
    if (args.contains('--help') || args.contains('-h')) {
      return const _Arguments(
        source: null,
        output: null,
        sourceRevision: null,
        releaseId: null,
        mode: null,
        verifyOnly: false,
        help: true,
      );
    }
    String? valueAfter(String name) {
      final index = args.indexOf(name);
      if (index < 0) return null;
      if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
        throw ArgumentError('missing value for $name');
      }
      return args[index + 1];
    }

    final all = args.contains('--bundle-all');
    final eagerOnly = args.contains('--bundle-eager-only');
    if (all == eagerOnly) {
      throw ArgumentError(
        'exactly one of --bundle-all or --bundle-eager-only is required',
      );
    }
    final knownFlags = {
      '--source',
      '--output',
      '--source-revision',
      '--release-id',
      '--bundle-all',
      '--bundle-eager-only',
      '--verify-only',
    };
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (!arg.startsWith('--')) continue;
      if (!knownFlags.contains(arg)) {
        throw ArgumentError('unknown option: $arg');
      }
      if ({
        '--source',
        '--output',
        '--source-revision',
        '--release-id',
      }.contains(arg)) {
        i++;
      }
    }
    final source = valueAfter('--source');
    final output = valueAfter('--output');
    final sourceRevision = valueAfter('--source-revision');
    if (source == null || output == null || sourceRevision == null) {
      throw ArgumentError(
        '--source, --output, and --source-revision are required',
      );
    }
    return _Arguments(
      source: source,
      output: output,
      sourceRevision: sourceRevision,
      releaseId: valueAfter('--release-id'),
      mode: all ? RegistryBundleMode.all : RegistryBundleMode.eagerOnly,
      verifyOnly: args.contains('--verify-only'),
      help: false,
    );
  }
}

const _usage = '''
Usage:
  dart run tool/registry_bundle_builder.dart
    --source <akasha-db>
    --output <bundle directory>
    (--bundle-all | --bundle-eager-only)
    --source-revision <commit or release ID>
    [--release-id <release ID>]
    [--verify-only]

The source directory is read-only. Generation is staged and replaces output
only after completeness, allowlist, provenance, search-ID, and SHA checks pass.
Production release builds must use --bundle-all.
''';
