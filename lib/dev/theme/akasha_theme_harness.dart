import 'package:flutter/material.dart';

import '../../theme/akasha_palette.dart';
import '../../theme/akasha_theme.dart';
import '../../theme/akasha_theme_preset.dart';
import '../../widgets/akasha_theme_backdrop.dart';

/// Stable Material-surface fixture for theme smoke and golden tests.
///
/// It is not routed from the production application.
class AkashaThemeHarness extends StatelessWidget {
  const AkashaThemeHarness({
    super.key,
    required this.preset,
    this.textScale = 1,
    this.reduceMotion = false,
  });

  final AkashaThemePreset preset;
  final double textScale;
  final bool reduceMotion;

  static const surfaceKey = ValueKey<String>('akasha-theme-harness-surface');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey<String>('akasha-theme-harness-${preset.id}'),
      debugShowCheckedModeBanner: false,
      theme: AkashaTheme.forPreset(preset),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Builder(
        builder: (context) {
          final palette = context.akashaPalette;
          return RepaintBoundary(
            key: surfaceKey,
            child: AkashaThemeBackdrop(
              preset: preset,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(title: Text(preset.id)),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Primary text'),
                            Text(
                              'Secondary text',
                              style: TextStyle(color: palette.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            const TextField(
                              decoration: InputDecoration(labelText: 'Input'),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton(
                                  onPressed: _noop,
                                  child: const Text('Primary'),
                                ),
                                OutlinedButton(
                                  onPressed: _noop,
                                  child: const Text('Secondary'),
                                ),
                                const Chip(label: Text('Tag')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(value: 0.62),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static void _noop() {}
}
