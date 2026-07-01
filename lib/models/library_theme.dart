import 'package:flutter/material.dart';

/// 나의 서재 비주얼 테마 (기본 무료 + IAP 팩)
class LibraryTheme {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color accentColor;
  final bool requiresIap;

  const LibraryTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    this.accentColor = Colors.tealAccent,
    this.requiresIap = false,
  });

  static const LibraryTheme classic = LibraryTheme(
    id: 'classic',
    name: 'Classic Dark',
    backgroundColor: Color(0xFF13131D),
  );

  static const LibraryTheme midnight = LibraryTheme(
    id: 'midnight',
    name: 'Midnight Blue',
    backgroundColor: Color(0xFF0D1B2A),
    accentColor: Color(0xFF64B5F6),
  );

  static const LibraryTheme sakura = LibraryTheme(
    id: 'sakura',
    name: 'Sakura (IAP)',
    backgroundColor: Color(0xFF2A1A22),
    accentColor: Color(0xFFF48FB1),
    requiresIap: true,
  );

  static const LibraryTheme amethyst = LibraryTheme(
    id: 'amethyst',
    name: 'Amethyst (IAP)',
    backgroundColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFB39DDB),
    requiresIap: true,
  );

  static const List<LibraryTheme> all = [classic, midnight, sakura, amethyst];

  static LibraryTheme? byId(String id) {
    final normalized = id == 'obsidian' ? 'amethyst' : id;
    for (final theme in all) {
      if (theme.id == normalized) return theme;
    }
    return null;
  }
}
