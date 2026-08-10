import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/event_category.dart';

/// Etkinlik görsel alanı — kart, hero ve kulüp kapağında ortak kullanılır.
///
/// `imageUrl` boşken kategori renginden türeyen gradyan + 45° çizgili doku
/// gösterilir; bu bir yer tutucu değil, kalıcı tasarım kararıdır.
class EventVisual extends StatelessWidget {
  final String imageUrl;
  final EventCategory category;

  /// Sağ altta taşan filigran ikon boyutu. `null` ise filigran çizilmez.
  final double? watermarkSize;

  /// Alt kenardaki okunabilirlik gradyanının yüksekliği. 0 ise çizilmez.
  final double scrimHeight;
  final double scrimOpacity;

  const EventVisual({
    super.key,
    required this.imageUrl,
    required this.category,
    this.watermarkSize = 170,
    this.scrimHeight = 110,
    this.scrimOpacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, _) =>
                ColoredBox(color: colorScheme.surfaceContainer),
            errorWidget: (context, _, _) => _Fallback(
              category: category,
              watermarkSize: watermarkSize,
            ),
          )
        else
          _Fallback(category: category, watermarkSize: watermarkSize),
        if (scrimHeight > 0)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: scrimHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: scrimOpacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  final EventCategory category;
  final double? watermarkSize;

  const _Fallback({required this.category, this.watermarkSize});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.color.withValues(alpha: 0.95),
                category.color.withValues(alpha: 0.48),
                colorScheme.primary.withValues(alpha: 0.52),
              ],
            ),
          ),
        ),
        CustomPaint(painter: _DiagonalStripePainter()),
        if (watermarkSize != null)
          Positioned(
            right: -24,
            bottom: -30,
            child: Icon(
              category.icon,
              size: watermarkSize,
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
      ],
    );
  }
}

/// 45° çizgili doku: 12px dolu / 12px boşluk, beyaz %9.
class _DiagonalStripePainter extends CustomPainter {
  static const _stripeWidth = 12.0;
  static const _gap = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = _stripeWidth
      ..style = PaintingStyle.stroke;

    const step = _stripeWidth + _gap;
    final extent = size.width + size.height;

    for (var offset = -size.height; offset < extent; offset += step) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripePainter oldDelegate) => false;
}
