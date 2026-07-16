/// Admin-only GetReport fetcher for Steam review evidence.
///
/// NEVER ship in the Flutter client build. Publisher key from env only:
///   STEAM_PUBLISHER_WEB_API_KEY
/// Optional: STEAM_APP_ID (default 4677560)
///
/// Usage:
///   dart run tool/steam_get_report.dart --type SETTLEMENT --time 2026-07-01T00:00:00Z
///   dart run tool/steam_get_report.dart --fixture tool/fixtures/steam_getreport_settlement.json
library;

import 'dart:convert';
import 'dart:io';

const _defaultAppId = 4677560;
const _allowedTypes = {
  'STEAMSTORESALES',
  'SETTLEMENT',
  'CHARGEBACK',
  'GAMESALES',
};

Future<void> main(List<String> args) async {
  final opts = _parse(args);
  if (opts.containsKey('help')) {
    stdout.writeln(_usage);
    return;
  }

  final type = (opts['type'] ?? 'SETTLEMENT').toUpperCase();
  if (!_allowedTypes.contains(type)) {
    stderr.writeln('Invalid --type. Allowed: ${_allowedTypes.join(', ')}');
    exitCode = 64;
    return;
  }

  final time = opts['time'] ?? '2026-07-01T00:00:00Z';
  final fixture = opts['fixture'];
  final outDir = Directory(
    opts['out'] ?? 'build/steam/get_report_evidence',
  );
  await outDir.create(recursive: true);

  late final String rawBody;
  late final int status;

  if (fixture != null) {
    rawBody = await File(fixture).readAsString();
    status = 200;
    stdout.writeln('Loaded fixture: $fixture (no network, no key required)');
  } else {
    final key = Platform.environment['STEAM_PUBLISHER_WEB_API_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      stderr.writeln(
        'STEAM_PUBLISHER_WEB_API_KEY is not set.\n'
        'For dry-run use --fixture tool/fixtures/steam_getreport_settlement.json',
      );
      exitCode = 78;
      return;
    }
    final appId = int.parse(
      opts['appid'] ??
          Platform.environment['STEAM_APP_ID'] ??
          '$_defaultAppId',
    );
    final sandbox = opts.containsKey('sandbox');
    final iface = sandbox ? 'ISteamMicroTxnSandbox' : 'ISteamMicroTxn';
    final uri = Uri.https('partner.steam-api.com', '/$iface/GetReport/v5/', {
      'key': key,
      'appid': '$appId',
      'type': type,
      'time': time,
      'maxresults': opts['maxresults'] ?? '1000',
    });
    stdout.writeln(
      'GET GetReport type=$type time=$time appid=$appId sandbox=$sandbox',
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      status = response.statusCode;
      rawBody = await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }

  final ts = DateTime.now().toUtc().toIso8601String().replaceAll(':', '');
  final rawPath = File('${outDir.path}/getreport_${type}_${ts}_raw.json');
  final redPath = File('${outDir.path}/getreport_${type}_${ts}_redacted.json');
  await rawPath.writeAsString(rawBody);
  await redPath.writeAsString(redact(rawBody));

  stdout.writeln('HTTP $status');
  stdout.writeln('raw:      ${rawPath.path}');
  stdout.writeln('redacted: ${redPath.path}');
  if (status != 200 && fixture == null) {
    exitCode = 1;
  }
}

String redact(String body) {
  var out = body;
  out = out.replaceAll(RegExp(r'(key|Key)=[^&\s"]+'), 'key=***');
  out = out.replaceAll(RegExp(r'"key"\s*:\s*"[^"]+"'), '"key":"***"');
  out = out.replaceAllMapped(
    RegExp(
      r'"(steamid|steamId|email|ipaddress)"\s*:\s*"([^"]*)"',
      caseSensitive: false,
    ),
    (m) => '"${m.group(1)}":"***"',
  );
  return out;
}

Map<String, String> _parse(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--help' || a == '-h') {
      out['help'] = '1';
      continue;
    }
    if (a == '--sandbox') {
      out['sandbox'] = '1';
      continue;
    }
    if (a.startsWith('--') && i + 1 < args.length) {
      out[a.substring(2)] = args[++i];
    }
  }
  return out;
}

const _usage = '''
Admin GetReport tool (not for Flutter client).

  dart run tool/steam_get_report.dart --type SETTLEMENT --time 2026-07-01T00:00:00Z
  dart run tool/steam_get_report.dart --type CHARGEBACK --time 2026-07-01T00:00:00Z --sandbox
  dart run tool/steam_get_report.dart --fixture tool/fixtures/steam_getreport_settlement.json

Env: STEAM_PUBLISHER_WEB_API_KEY (required unless --fixture)
     STEAM_APP_ID (optional, default 4677560)
''';
