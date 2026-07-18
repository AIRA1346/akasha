import 'dart:async';

import 'package:akasha/core/commerce/commerce.dart';
import 'package:akasha/models/build_identity.dart';
import 'package:akasha/services/build_identity_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildIdentity', () {
    test('formats app build and Steam BuildID as separate identifiers', () {
      const identity = BuildIdentity(
        version: '0.9.0',
        buildNumber: '42',
        steamBuildId: 24271481,
        gitCommitShort: 'f9d0b94b',
        buildMode: 'release',
        executionEnvironment: 'steamInstall',
        steamState: SteamBuildIdentityState.available,
      );

      expect(identity.versionLabel, 'v0.9.0+42');
      expect(
        identity.summaryLabel(
          localLabel: 'Local',
          steamCheckingLabel: 'Steam checking',
        ),
        'v0.9.0+42 • Steam 24271481',
      );
      expect(
        identity.copyText(),
        'AKASHA v0.9.0+42 | Steam 24271481 | Git f9d0b94b | '
        'release | steamInstall',
      );
    });

    test('omits an empty build number and unavailable Steam suffix', () {
      const identity = BuildIdentity(
        version: '0.9.0',
        buildNumber: '',
        steamBuildId: null,
        gitCommitShort: null,
        buildMode: 'debug',
        executionEnvironment: 'steamInstall',
        steamState: SteamBuildIdentityState.unavailable,
      );

      expect(identity.versionLabel, 'v0.9.0');
      expect(
        identity.summaryLabel(
          localLabel: 'Local',
          steamCheckingLabel: 'Steam checking',
        ),
        'v0.9.0',
      );
      expect(identity.copyText(), isNot(contains('null')));
      expect(identity.copyText(), isNot(contains('Steam 0')));
    });
  });

  group('BuildIdentityController', () {
    test('loads metadata once and shortens an injected Git commit', () async {
      var packageCalls = 0;
      var diagnosticCalls = 0;
      final controller = BuildIdentityController(
        packageMetadataLoader: () async {
          packageCalls += 1;
          return const PackageBuildMetadata(
            version: '0.9.0',
            buildNumber: '42',
          );
        },
        steamDiagnosticLoader: () async {
          diagnosticCalls += 1;
          return const SteamInventoryDiagnostic(
            status: SteamInventoryReadStatus.success,
            initialized: true,
            steamBuildId: 24271481,
            gitCommit: 'f9d0b94b00c77feb6483f4df4e13886c78aa8175',
            buildMode: 'Release',
            executablePath:
                r'D:\SteamLibrary\steamapps\common\AKASHA\akasha.exe',
          );
        },
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.load();

      expect(packageCalls, 1);
      expect(diagnosticCalls, 1);
      expect(controller.identity.versionLabel, 'v0.9.0+42');
      expect(controller.identity.steamBuildId, 24271481);
      expect(controller.identity.gitCommitShort, 'f9d0b94b');
      expect(controller.identity.buildMode, 'release');
      expect(controller.identity.executionEnvironment, 'steamInstall');
      expect(controller.identity.steamState, SteamBuildIdentityState.available);
    });

    test('publishes checking before a delayed Steam diagnostic', () async {
      final diagnostic = Completer<SteamInventoryDiagnostic>();
      final controller = BuildIdentityController(
        packageMetadataLoader: () async =>
            const PackageBuildMetadata(version: '1.0.0', buildNumber: '1'),
        steamDiagnosticLoader: () => diagnostic.future,
      );
      addTearDown(controller.dispose);

      final load = controller.load();
      await pumpEventQueue();
      expect(controller.identity.versionLabel, 'v1.0.0+1');
      expect(controller.identity.steamState, SteamBuildIdentityState.checking);

      diagnostic.complete(
        const SteamInventoryDiagnostic(
          status: SteamInventoryReadStatus.unavailable,
          initializationAttempted: true,
          buildMode: 'Debug',
          executablePath: r'C:\repo\build\windows\x64\runner\Debug\akasha.exe',
        ),
      );
      await load;

      expect(controller.identity.steamBuildId, isNull);
      expect(controller.identity.steamState, SteamBuildIdentityState.local);
      expect(controller.identity.executionEnvironment, 'localDebug');
    });

    test(
      'Steam install with BuildID zero uses the safe unavailable fallback',
      () async {
        final controller = BuildIdentityController(
          packageMetadataLoader: () async =>
              const PackageBuildMetadata(version: '1.0.0', buildNumber: '1'),
          steamDiagnosticLoader: () async => const SteamInventoryDiagnostic(
            status: SteamInventoryReadStatus.offline,
            initialized: true,
            steamBuildId: 0,
            executablePath:
                r'D:\SteamLibrary\steamapps\common\AKASHA\akasha.exe',
          ),
        );
        addTearDown(controller.dispose);

        await controller.load();

        expect(controller.identity.steamBuildId, isNull);
        expect(
          controller.identity.steamState,
          SteamBuildIdentityState.unavailable,
        );
        expect(
          controller.identity.summaryLabel(
            localLabel: 'Local',
            steamCheckingLabel: 'Steam checking',
          ),
          'v1.0.0+1',
        );
      },
    );

    test(
      'local debug remains identifiable even when Steam returns a BuildID',
      () async {
        final controller = BuildIdentityController(
          packageMetadataLoader: () async =>
              const PackageBuildMetadata(version: '1.0.0', buildNumber: '1'),
          steamDiagnosticLoader: () async => const SteamInventoryDiagnostic(
            status: SteamInventoryReadStatus.success,
            initialized: true,
            steamBuildId: 24271481,
            executablePath:
                r'C:\repo\build\windows\x64\runner\Debug\akasha.exe',
          ),
        );
        addTearDown(controller.dispose);

        await controller.load();

        expect(controller.identity.steamState, SteamBuildIdentityState.local);
        expect(
          controller.identity.summaryLabel(
            localLabel: 'Local',
            steamCheckingLabel: 'Steam checking',
          ),
          'v1.0.0+1 • Local',
        );
      },
    );

    test('does not publish a late Steam result after dispose', () async {
      final diagnostic = Completer<SteamInventoryDiagnostic>();
      final controller = BuildIdentityController(
        packageMetadataLoader: () async =>
            const PackageBuildMetadata(version: '1.0.0', buildNumber: '1'),
        steamDiagnosticLoader: () => diagnostic.future,
      );

      final load = controller.load();
      await pumpEventQueue();
      controller.dispose();
      diagnostic.complete(
        const SteamInventoryDiagnostic(
          status: SteamInventoryReadStatus.success,
          initialized: true,
          steamBuildId: 24271481,
        ),
      );
      await load;

      expect(controller.identity.steamState, SteamBuildIdentityState.checking);
    });
  });
}
