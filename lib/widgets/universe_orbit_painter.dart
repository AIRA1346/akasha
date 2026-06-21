import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 지식 우주 현황을 시각화하는 공전 궤도 애니메이션 위젯.
class UniverseOrbitWidget extends StatefulWidget {
  const UniverseOrbitWidget({super.key});

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
          painter: _UniverseOrbitPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _UniverseOrbitPainter extends CustomPainter {
  _UniverseOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);

    // 우주 먼지 / 미세 배경 그리드 데코레이션
    final bgPaint = Paint()
      ..color = const Color(0xFF1E1E2E).withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, size.height * 0.45, bgPaint);
    canvas.drawCircle(center, size.height * 0.35, bgPaint);

    // 1. 중앙 항성 (Sun) 드로잉 - 글로우 효과 포함
    final sunGlowPaint = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 22, sunGlowPaint);

    final sunCorePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFD700), // Gold
          Color(0xFFFF4500), // OrangeRed
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 12));
    canvas.drawCircle(center, 12, sunCorePaint);

    // 2. 궤도 파라미터 정의 (장반경 a, 단반경 b, 궤도 회전각(기울기), 공전 속도 배수, 초기 위상, 노드 정보)
    final orbits = [
      _OrbitData(
        label: '작품',
        count: '10,048',
        a: size.width * 0.32,
        b: size.height * 0.22,
        tiltAngle: -math.pi / 10,
        speedFactor: 1.5,
        phase: 0.0,
        color: const Color(0xFF6C63FF), // Indigo
        labelOffset: const Offset(-80, -20),
      ),
      _OrbitData(
        label: '인물',
        count: '38,742',
        a: size.width * 0.38,
        b: size.height * 0.28,
        tiltAngle: -math.pi / 28,
        speedFactor: -1.0, // 반시계 방향
        phase: math.pi / 3,
        color: const Color(0xFF00E5FF), // Aqua
        labelOffset: const Offset(30, -24),
      ),
      _OrbitData(
        label: '장소',
        count: '2,341',
        a: size.width * 0.26,
        b: size.height * 0.16,
        tiltAngle: math.pi / 8,
        speedFactor: 2.2,
        phase: math.pi * 0.8,
        color: const Color(0xFFFFB74D), // Yellow Orange
        labelOffset: const Offset(-80, 20),
      ),
      _OrbitData(
        label: '사건',
        count: '5,812',
        a: size.width * 0.42,
        b: size.height * 0.34,
        tiltAngle: math.pi / 16,
        speedFactor: -0.7,
        phase: math.pi * 1.3,
        color: const Color(0xFF81C784), // Light Green
        labelOffset: const Offset(30, 20),
      ),
    ];

    final orbitLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final orbit in orbits) {
      // (1) 기울어진 타원 궤도선 그리기
      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(orbit.tiltAngle);
      
      orbitLinePaint.color = orbit.color.withValues(alpha: 0.12);
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

      // (3) 노드 구체 및 글로우 그리기
      final nodeGlow = Paint()
        ..color = orbit.color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(nodePos, 8, nodeGlow);

      final nodeCore = Paint()..color = orbit.color;
      canvas.drawCircle(nodePos, 4, nodeCore);

      // (4) 고유 라벨 매핑 텍스트 렌더링
      final textPos = nodePos + orbit.labelOffset;

      // 텍스트 배경 반투명 박스
      final rectPaint = Paint()
        ..color = const Color(0xFF0F0F1A).withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = orbit.color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      const rectW = 68.0;
      const rectH = 34.0;
      final textRect = Rect.fromLTWH(
        textPos.dx - rectW / 2,
        textPos.dy - rectH / 2,
        rectW,
        rectH,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(textRect, const Radius.circular(6)),
        rectPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(textRect, const Radius.circular(6)),
        borderPaint,
      );

      // 카테고리 텍스트 ("작품" 등)
      final labelSpan = TextSpan(
        text: orbit.label,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(
          textRect.center.dx - labelPainter.width / 2,
          textRect.top + 3,
        ),
      );

      // 수치 텍스트 ("10,048")
      final countSpan = TextSpan(
        text: orbit.count,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Consolas',
        ),
      );
      final countPainter = TextPainter(
        text: countSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      countPainter.paint(
        canvas,
        Offset(
          textRect.center.dx - countPainter.width / 2,
          textRect.bottom - countPainter.height - 3,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UniverseOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
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
    required this.labelOffset,
  });

  final String label;
  final String count;
  final double a;
  final double b;
  final double tiltAngle;
  final double speedFactor;
  final double phase;
  final Color color;
  final Offset labelOffset;
}
