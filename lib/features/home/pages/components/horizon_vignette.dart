import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../models/sky_position.dart';

/// Karşılama alanının sağındaki küçük deniz ufku. Güneş ya da ay, günün
/// saatine göre gökyüzündeki yerinde durur; açılışta ufuktan bir kez yükselir.
///
/// Renkler temadan gelir. Çizim sola doğru saydamlaşır, böylece yanındaki
/// metne karışır.
class HorizonVignette extends StatelessWidget {
  static const double width = 104;
  static const double height = 44;

  final DateTime now;

  const HorizonVignette({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final sky = skyPositionAt(now);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: reduceMotion ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, rise, _) => CustomPaint(
            painter: _HorizonPainter(
              sky: sky,
              rise: rise,
              water: scheme.primary,
              horizonSun: scheme.secondary,
              moon: isDark ? const Color(0xFFE6ECFA) : const Color(0xFF8A97B3),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizonPainter extends CustomPainter {
  static const _bodyRadius = 6.0;
  static const _zenithSun = Color(0xFFFFB02E);

  final SkyPosition sky;

  /// 0..1: güneşin ya da ayın ufuktan yerine yükselme ilerlemesi.
  final double rise;
  final Color water;
  final Color horizonSun;
  final Color moon;

  const _HorizonPainter({
    required this.sky,
    required this.rise,
    required this.water,
    required this.horizonSun,
    required this.moon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.62;
    final center = _bodyCenter(size, horizonY);
    final height = math.sin(math.pi * sky.progress);
    final bodyColor = sky.isDay
        ? Color.lerp(horizonSun, _zenithSun, height)!
        : moon;

    // Gökyüzü: yalnızca ufkun üstü görünür, cisim denize batıp çıkar.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY));
    if (sky.isDay) {
      _paintSun(canvas, center, bodyColor);
    } else {
      _paintMoonAndStars(canvas, size, center);
    }
    canvas.restore();

    _paintWater(canvas, size, horizonY);
    _paintReflection(canvas, center.dx, horizonY, bodyColor);
  }

  Offset _bodyCenter(Size size, double horizonY) {
    final progress = sky.progress;
    final x = size.width * (0.14 + 0.72 * progress);
    // Tepe noktasında halo üst kenara kırpılmasın diye 12 px pay bırakılır.
    final apex = horizonY - math.sin(math.pi * progress) * (horizonY - 12);
    final hidden = horizonY + _bodyRadius + 3;
    return Offset(x, lerpDouble(hidden, apex, rise)!);
  }

  void _paintSun(Canvas canvas, Offset center, Color color) {
    final halo = Rect.fromCircle(center: center, radius: 12);
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.34), color.withValues(alpha: 0)],
        ).createShader(halo),
    );
    canvas.drawCircle(center, _bodyRadius, Paint()..color = color);
  }

  void _paintMoonAndStars(Canvas canvas, Size size, Offset center) {
    const stars = [Offset(0.20, 0.16), Offset(0.50, 0.12), Offset(0.84, 0.30)];
    final starPaint = Paint()..color = moon.withValues(alpha: 0.7 * rise);
    for (final star in stars) {
      final point = Offset(size.width * star.dx, size.height * star.dy);
      if ((point - center).distance < 10) continue;
      canvas.drawCircle(point, 1, starPaint);
    }

    final disc = Path()
      ..addOval(Rect.fromCircle(center: center, radius: _bodyRadius));
    final bite = Path()
      ..addOval(
        Rect.fromCircle(
          center: center.translate(3.2, -1.6),
          radius: _bodyRadius * 0.88,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, disc, bite),
      Paint()..color = moon,
    );
  }

  /// Ufuk çizgisi ve üç dalga. Hepsi sola doğru saydamlaşır.
  void _paintWater(Canvas canvas, Size size, double horizonY) {
    _fadedLine(
      canvas,
      size,
      Path()
        ..moveTo(0, horizonY)
        ..lineTo(size.width, horizonY),
      water.withValues(alpha: 0.38),
      1,
    );

    const offsets = [3.5, 7.5, 11.5];
    const alphas = [0.45, 0.30, 0.18];
    for (var i = 0; i < offsets.length; i++) {
      final y = horizonY + offsets[i];
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 1) {
        // Her dalga bir öncekine göre kaymış, hepsi sakin.
        path.lineTo(x, y + math.sin(x / 14 * 2 * math.pi + i * 1.3) * 1.2);
      }
      _fadedLine(canvas, size, path, water.withValues(alpha: alphas[i]), 1.4);
    }
  }

  void _fadedLine(
    Canvas canvas,
    Size size,
    Path path,
    Color color,
    double width,
  ) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0), color],
          stops: const [0, 0.5],
        ).createShader(Offset.zero & size),
    );
  }

  /// Cismin suya düşen kısa yansıma çizgileri; dalgaların arasına oturur.
  void _paintReflection(Canvas canvas, double x, double horizonY, Color color) {
    const rows = [(5.5, 12.0, 0.55), (9.5, 8.0, 0.40), (13.5, 5.0, 0.25)];
    for (final (offset, length, alpha) in rows) {
      final y = horizonY + offset;
      canvas.drawLine(
        Offset(x - length / 2, y),
        Offset(x + length / 2, y),
        Paint()
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: alpha * rise),
      );
    }
  }

  @override
  bool shouldRepaint(_HorizonPainter old) =>
      old.sky != sky ||
      old.rise != rise ||
      old.water != water ||
      old.horizonSun != horizonSun ||
      old.moon != moon;
}
