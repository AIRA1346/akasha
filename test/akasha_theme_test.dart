import 'package:akasha/models/library_theme.dart';
import 'package:akasha/theme/akasha_palette.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app theme projects LibraryTheme into ThemeData and AkashaPalette', () {
    final theme = AkashaTheme.withAppTheme(
      ThemeData.dark(useMaterial3: true),
      LibraryTheme.sakura,
    );
    final palette = theme.extension<AkashaPalette>();

    expect(theme.scaffoldBackgroundColor, LibraryTheme.sakura.backgroundColor);
    expect(theme.colorScheme.primary, LibraryTheme.sakura.accentColor);
    expect(theme.colorScheme.secondary, LibraryTheme.sakura.accentColor);
    expect(palette, isNotNull);
    expect(palette!.background, LibraryTheme.sakura.backgroundColor);
    expect(palette.accent, LibraryTheme.sakura.accentColor);
    expect(palette.sidebar, isNot(LibraryTheme.classic.backgroundColor));
  });
}
