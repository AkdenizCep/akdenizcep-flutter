import 'package:flutter/material.dart';

import '../../../../shared/components/app_top_bar.dart';

class CampusHeader extends StatelessWidget {
  final List<Widget> actions;

  const CampusHeader({
    super.key,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: _CampusRoutePainter(color: colorScheme.primary),
            ),
          ),
        ),
        AppTopBar(
          title: 'Kampüs',
          actions: actions,
          bottom: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 285),
            child: Text(
              'Kampüs yaşamında ihtiyaç duyabileceğin hizmetler.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CampusRoutePainter extends CustomPainter {
  final Color color;

  const _CampusRoutePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = color.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final secondaryRoutePaint = Paint()
      ..color = color.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final mainRoute = Path()
      ..moveTo(size.width * 0.71, -8)
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.25,
        size.width * 0.94,
        size.height * 0.38,
        size.width * 0.84,
        size.height * 0.64,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.82,
        size.width * 0.92,
        size.height * 0.94,
        size.width * 1.04,
        size.height * 0.82,
      );
    canvas.drawPath(mainRoute, routePaint);

    final secondaryRoute = Path()
      ..moveTo(size.width * 0.90, -4)
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.18,
        size.width * 1.02,
        size.height * 0.38,
        size.width * 0.92,
        size.height * 0.55,
      );
    canvas.drawPath(secondaryRoute, secondaryRoutePaint);

    final nodeFill = Paint()..color = color.withValues(alpha: 0.12);
    final nodeStroke = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final point in [
      Offset(size.width * 0.72, size.height * 0.16),
      Offset(size.width * 0.86, size.height * 0.53),
      Offset(size.width * 0.86, size.height * 0.88),
    ]) {
      canvas.drawCircle(point, 5.5, nodeFill);
      canvas.drawCircle(point, 5.5, nodeStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _CampusRoutePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
