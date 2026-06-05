import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 확장형 올인원 아카이브 앱
//  앱 진입점 & 테마 설정
// ════════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AkashaApp());
}

class AkashaApp extends StatelessWidget {
  const AkashaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AKASHA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF13131D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF1A1A28),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A28),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E2E),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
