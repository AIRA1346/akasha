import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 지식 우주 현황을 시각화하는 공전 궤도 애니메이션 위젯.
class UniverseOrbitWidget extends StatefulWidget {
  const UniverseOrbitWidget({
    super.key,
    required this.workCount,
    required this.personCount,
    required this.placeCount,
    required this.eventCount,
  });

  final int workCount;
  final int personCount;
  final int placeCount;
  final int eventCount;

  @override
  State<UniverseOrbitWidget> createState() => _UniverseOrbitWidgetState();
}

class _UniverseOrbitWidgetState extends State<UniverseOrbitWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 320),
          painter: _UniverseOrbitPainter(
            progress: _controller.value,
            workCount: widget.workCount,
            personCount: widget.personCount,
            placeCount: widget.placeCount,
            eventCount: widget.eventCount,
          ),
        );
      },
    );
  }
}

class _UniverseOrbitPainter extends CustomPainter {
  _UniverseOrbitPainter({
    required this.progress,
    required this.workCount,
    required this.personCount,
    required this.placeCount,
    required this.eventCount,
  });

  final double progress;
  final int workCount;
  final int personCount;
  final int placeCount;
  final int eventCount;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);

    // 고정 비율 궤도 반경 상수 r
    final r = size.height * 0.38;

    // 우주 먼지 / 미세 배경 그리드 데코레이션
    final bgPaint = Paint()
      ..color = const Color(0xFF1E1E2E).withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, size.height * 0.45, bgPaint);
    canvas.drawCircle(center, size.height * 0.35, bgPaint);

    // 1. 중앙 항성 (Sun) 드로잉 - 글로우 효과 보강
    final sunGlowPaint1 = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, 38, sunGlowPaint1);

    final sunGlowPaint2 = Paint()
      ..color = const Color(0xFFFF4500).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 22, sunGlowPaint2);

    final sunCorePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFD700), // Gold
          Color(0xFFFF4500), // OrangeRed
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 12));
    canvas.drawCircle(center, 12, sunCorePaint);

    // 포맷팅 (1,000 이상 콤마)
    final fmt = NumberFormat('#,###');

    // 2. 궤도 파라미터 정의 (고정 비율화 및 대칭 정적 위치 매핑)
    final orbits = [
      _OrbitData(
        label: '작품',
        count: fmt.format(workCount),
        a: r * 2.1,
        b: r * 0.85,
        tiltAngle: -math.pi / 10,
        speedFactor: 1.5,
        phase: 0.0,
        color: const Color(0xFF6C63FF), // Indigo
        staticPos: Offset(centerX - r * 2.3, centerY - r * 0.6),
      ),
      _OrbitData(
        label: '인물',
        count: fmt.format(personCount),
        a: r * 2.5,
        b: r * 1.05,
        tiltAngle: -math.pi / 28,
        speedFactor: -1.0,
        phase: math.pi / 3,
        color: const Color(0xFF00E5FF), // Aqua
        staticPos: Offset(centerX + r * 1.6, centerY - r * 0.6),
      ),
      _OrbitData(
        label: '장소',
        count: fmt.format(placeCount),
        a: r * 1.7,
        b: r * 0.65,
        tiltAngle: math.pi / 8,
        speedFactor: 2.2,
        phase: math.pi * 0.8,
        color: const Color(0xFFFFB74D), // Yellow Orange
        staticPos: Offset(centerX - r * 2.0, centerY + r * 0.65),
      ),
      _OrbitData(
        label: '사건',
        count: fmt.format(eventCount),
        a: r * 2.8,
        b: r * 1.25,
        tiltAngle: math.pi / 16,
        speedFactor: -0.7,
        phase: math.pi * 1.3,
        color: const Color(0xFF81C784), // Light Green
        staticPos: Offset(centerX + r * 1.3, centerY + r * 0.65),
      ),
    ];

    final orbitLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    for (final orbit in orbits) {
      // (1) 기울어진 타원 궤도선 그리기
      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(orbit.tiltAngle);
      
      orbitLinePaint.color = orbit.color.withValues(alpha: 0.14);
      canvas.drawOval(
        Rect.fromLTRB(-orbit.a, -orbit.b, orbit.a, orbit.b),
        orbitLinePaint,
      );
      canvas.restore();

      // (2) 공전하는 노드(행성) 좌표 계산
      final t = (progress * 2 * math.pi * orbit.speedFactor) + orbit.phase;
      final localX = orbit.a * math.cos(t);
      final localY = orbit.b * math.sin(t);

      // 회전 변환 적용
      final rotatedX = localX * math.cos(orbit.tiltAngle) - localY * math.sin(orbit.tiltAngle);
      final rotatedY = localX * math.sin(orbit.tiltAngle) + localY * math.cos(orbit.tiltAngle);

      final nodePos = Offset(centerX + rotatedX, centerY + rotatedY);

      // (3) 노드 구체 및 2중 글로우 그리기
      final nodeGlow1 = Paint()
        ..color = orbit.color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(nodePos, 11, nodeGlow1);

      final nodeGlow2 = Paint()
        ..color = orbit.color.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(nodePos, 7, nodeGlow2);

      final nodeCore = Paint()..color = Colors.white;
      canvas.drawCircle(nodePos, 3.5, nodeCore);

      // (4) 고정 대칭 텍스트 라벨 드로잉
      final staticPos = orbit.staticPos;

      // 수치 텍스트
      final countSpan = TextSpan(
        text: orbit.count,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Consolas',
        ),
      );
      final countPainter = TextPainter(
        text: countSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      // 카테고리 텍스트
      final labelSpan = TextSpan(
        text: orbit.label,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      // 카테고리 라벨 그리기 (위쪽)
      labelPainter.paint(
        canvas,
        Offset(staticPos.dx, staticPos.dy - 12),
      );

      // 수치 그리기 (아래쪽)
      countPainter.paint(
        canvas,
        Offset(staticPos.dx, staticPos.dy + 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UniverseOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.workCount != workCount ||
           oldDelegate.personCount != personCount ||
           oldDelegate.placeCount != placeCount ||
           oldDelegate.eventCount != eventCount;
  }
}

class _OrbitData {
  const _OrbitData({
    required this.label,
    required this.count,
    required this.a,
    required this.b,
    required this.tiltAngle,
    required this.speedFactor,
    required this.phase,
    required this.color,
    required this.staticPos,
  });

  final String label;
  final String count;
  final double a;
  final double b;
  final double tiltAngle;
  final double speedFactor;
  final double phase;
  final Color color;
  final Offset staticPos;
}
