import 'dart:convert';
import 'dart:io';

import 'archive_gateway_candidate_command.dart';

/// Command-mode entry owned by the AKASHA desktop executable.
///
/// Keeping this inside the desktop binary avoids a second independently
/// packaged runtime and lets a command-capable local agent invoke the same
/// Gateway implementation as the app. The command vocabulary is intentionally
/// tiny; only `candidate propose` is currently recognized.
class AkashaCommandRunner {
  AkashaCommandRunner({ArchiveGatewayCandidateCommand? candidateCommand})
    : _candidateCommand = candidateCommand ?? ArchiveGatewayCandidateCommand();

  final ArchiveGatewayCandidateCommand _candidateCommand;

  static bool handles(List<String> args) =>
      args.isNotEmpty && args.first == 'candidate';

  Future<void> runFromProcess(List<String> args) async {
    String resultPath;
    try {
      resultPath = _resultPath(args.skip(2));
    } on FormatException {
      exit(64);
    }
    final outcome = await executeFromRequestFile(args: args);
    try {
      await writeOutcomeFile(path: resultPath, outcome: outcome);
    } on FileSystemException {
      exit(1);
    }
    exit(outcome.exitCode);
  }

  /// Writes an external command result once. Result files are protocol output,
  /// not Vault data; callers choose a temporary path outside their Vault. The
  /// command never overwrites an existing file just to report its outcome.
  Future<void> writeOutcomeFile({
    required String path,
    required AkashaCommandOutcome outcome,
  }) async {
    final file = File(path);
    if (await file.exists()) {
      throw FileSystemException('Command result path already exists.', path);
    }
    if (!await file.parent.exists()) {
      throw FileSystemException('Command result parent does not exist.', path);
    }
    await file.create(exclusive: true);
    final handle = await file.open(mode: FileMode.writeOnly);
    try {
      await handle.writeString(jsonEncode(outcome.response));
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  /// File-backed process entry used by the Windows GUI-subsystem executable.
  ///
  /// A GUI process cannot reliably inherit a pipe as Dart's stdin on every
  /// launcher. The agent therefore gives the explicit request file path; the
  /// command reads it once and never scans a directory for work.
  Future<AkashaCommandOutcome> executeFromRequestFile({
    required List<String> args,
  }) async {
    String requestPath;
    try {
      requestPath = _requestPath(args.skip(2));
    } on FormatException catch (error) {
      return AkashaCommandOutcome.usage(error.message);
    }

    String input;
    try {
      input = await File(requestPath).readAsString();
    } on FileSystemException catch (error) {
      return AkashaCommandOutcome.requestUnreadable(error.message);
    }
    return execute(args: _withoutRequestOption(args), stdinText: input);
  }

  Future<AkashaCommandOutcome> execute({
    required List<String> args,
    required String stdinText,
  }) async {
    if (args.length < 2 || args[0] != 'candidate' || args[1] != 'propose') {
      return AkashaCommandOutcome.usage(
        'Usage: akasha candidate propose --vault <vault-path>.',
      );
    }

    String vaultPath;
    try {
      vaultPath = _vaultPath(args.skip(2));
    } on FormatException catch (error) {
      return AkashaCommandOutcome.usage(error.message);
    }

    try {
      final decoded = jsonDecode(stdinText);
      if (decoded is! Map) {
        throw const FormatException('Command input must be one JSON object.');
      }
      final payload = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final result = await _candidateCommand.propose(
        vaultPath: vaultPath,
        payload: payload,
      );
      return AkashaCommandOutcome(
        exitCode: result.ok ? 0 : 2,
        response: result.toJson(),
      );
    } on FormatException catch (error) {
      return AkashaCommandOutcome.invalidPayload(error.message);
    } on Object catch (error) {
      return AkashaCommandOutcome.failed('$error');
    }
  }

  static String _vaultPath(Iterable<String> args) {
    String? vaultPath;
    final values = args.toList(growable: false);
    for (var index = 0; index < values.length; index += 1) {
      final value = values[index];
      if (value != '--vault') {
        throw FormatException('Unsupported command option: $value.');
      }
      if (vaultPath != null || index + 1 >= values.length) {
        throw const FormatException('--vault <path> is required exactly once.');
      }
      final optionValue = values[++index].trim();
      if (optionValue.isEmpty || optionValue.startsWith('--')) {
        throw const FormatException('--vault <path> is required exactly once.');
      }
      vaultPath = optionValue;
    }
    if (vaultPath == null || vaultPath.isEmpty) {
      throw const FormatException('--vault <path> is required exactly once.');
    }
    return vaultPath;
  }

  static String _requestPath(Iterable<String> args) {
    String? requestPath;
    final values = args.toList(growable: false);
    for (var index = 0; index < values.length; index += 1) {
      if (values[index] != '--request') continue;
      if (requestPath != null || index + 1 >= values.length) {
        throw const FormatException(
          '--request <json-file> is required exactly once.',
        );
      }
      final optionValue = values[++index].trim();
      if (optionValue.isEmpty || optionValue.startsWith('--')) {
        throw const FormatException(
          '--request <json-file> is required exactly once.',
        );
      }
      requestPath = optionValue;
    }
    if (requestPath == null || requestPath.isEmpty) {
      throw const FormatException(
        '--request <json-file> is required exactly once.',
      );
    }
    return requestPath;
  }

  static String _resultPath(Iterable<String> args) {
    String? resultPath;
    final values = args.toList(growable: false);
    for (var index = 0; index < values.length; index += 1) {
      if (values[index] != '--result') continue;
      if (resultPath != null || index + 1 >= values.length) {
        throw const FormatException(
          '--result <json-file> is required exactly once.',
        );
      }
      final optionValue = values[++index].trim();
      if (optionValue.isEmpty || optionValue.startsWith('--')) {
        throw const FormatException(
          '--result <json-file> is required exactly once.',
        );
      }
      resultPath = optionValue;
    }
    if (resultPath == null || resultPath.isEmpty) {
      throw const FormatException(
        '--result <json-file> is required exactly once.',
      );
    }
    return resultPath;
  }

  static List<String> _withoutRequestOption(List<String> args) {
    final normalized = <String>[];
    for (var index = 0; index < args.length; index += 1) {
      if (args[index] == '--request') {
        index += 1;
        continue;
      }
      if (args[index] == '--result') {
        index += 1;
        continue;
      }
      normalized.add(args[index]);
    }
    return normalized;
  }
}

class AkashaCommandOutcome {
  const AkashaCommandOutcome({required this.exitCode, required this.response});

  final int exitCode;
  final Map<String, Object?> response;

  factory AkashaCommandOutcome.usage(String message) => AkashaCommandOutcome(
    exitCode: 64,
    response: {
      'ok': false,
      'error': {'code': 'command_usage', 'message': message},
    },
  );

  factory AkashaCommandOutcome.invalidPayload(String message) =>
      AkashaCommandOutcome(
        exitCode: 64,
        response: {
          'ok': false,
          'error': {'code': 'command_payload_invalid', 'message': message},
        },
      );

  factory AkashaCommandOutcome.requestUnreadable(String message) =>
      AkashaCommandOutcome(
        exitCode: 64,
        response: {
          'ok': false,
          'error': {'code': 'command_request_unreadable', 'message': message},
        },
      );

  factory AkashaCommandOutcome.failed(String message) => AkashaCommandOutcome(
    exitCode: 1,
    response: {
      'ok': false,
      'error': {'code': 'command_failed', 'message': message},
    },
  );
}
