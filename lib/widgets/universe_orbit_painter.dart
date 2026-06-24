import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/akasha_colors.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.min(220.0, math.max(160.0, width * 0.52));

        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(width, height),
                painter: _UniverseOrbitPainter(
                  progress: _controller.value,
                  workCount: widget.workCount,
                  personCount: widget.personCount,
                  placeCount: widget.placeCount,
                  eventCount: widget.eventCount,
                ),
              );
            },
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
    const pad = 10.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);
    final baseR = math.min(size.width - pad * 2, size.height - pad * 2) * 0.34;

    // 배경 동심원
    final bgPaint = Paint()
      ..color = AkashaColors.surfaceElevated.withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, baseR * 0.55, bgPaint);
    canvas.drawCircle(center, baseR * 0.82, bgPaint);

    // 중앙 항성
    final sunGlowPaint1 = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, baseR * 0.18, sunGlowPaint1);

    final sunGlowPaint2 = Paint()
      ..color = const Color(0xFFFF4500).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, baseR * 0.11, sunGlowPaint2);

    final sunCorePaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFFFD700),
          Color(0xFFFF4500),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseR * 0.07));
    canvas.drawCircle(center, baseR * 0.07, sunCorePaint);

    final fmt = NumberFormat('#,###');

    final labelPositions = [
      Offset(pad + 2, pad + 18),
      Offset(size.width - pad - 52, pad + 18),
      Offset(pad + 2, size.height - pad - 28),
      Offset(size.width - pad - 52, size.height - pad - 28),
    ];

    final orbits = [
      _OrbitData(
        label: '작품',
        count: fmt.format(workCount),
        a: baseR * 0.92,
        b: baseR * 0.36,
        tiltAngle: -math.pi / 10,
        speedFactor: 1.5,
        phase: 0.0,
        color: AkashaColors.accent,
        staticPos: labelPositions[0],
      ),
      _OrbitData(
        label: '인물',
        count: fmt.format(personCount),
        a: baseR * 1.0,
        b: baseR * 0.4,
        tiltAngle: -math.pi / 28,
        speedFactor: -1.0,
        phase: math.pi / 3,
        color: AkashaColors.personAccent,
        staticPos: labelPositions[1],
      ),
      _OrbitData(
        label: '장소',
        count: fmt.format(placeCount),
        a: baseR * 0.78,
        b: baseR * 0.3,
        tiltAngle: math.pi / 8,
        speedFactor: 2.2,
        phase: math.pi * 0.8,
        color: AkashaColors.placeAccent,
        staticPos: labelPositions[2],
      ),
      _OrbitData(
        label: '사건',
        count: fmt.format(eventCount),
        a: baseR * 1.06,
        b: baseR * 0.44,
        tiltAngle: math.pi / 16,
        speedFactor: -0.7,
        phase: math.pi * 1.3,
        color: AkashaColors.eventAccent,
        staticPos: labelPositions[3],
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
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(nodePos, baseR * 0.07, nodeGlow1);

      final nodeGlow2 = Paint()
        ..color = orbit.color.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(nodePos, baseR * 0.045, nodeGlow2);

      final nodeCore = Paint()..color = Colors.white;
      canvas.drawCircle(nodePos, baseR * 0.025, nodeCore);

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
