import 'package:flutter/material.dart';

/// Akdeniz Cep tipografik logo bileşeni.
/// "Akdeniz" koyu lacivert (#0A2338), "Cep" canlı camgöbeği/mavi (#329CEE) renktedir.
class AkdenizCepLogo extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final Color? akdenizColor;
  final Color? cepColor;

  const AkdenizCepLogo({
    super.key,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = -0.6,
    this.akdenizColor,
    this.cepColor,
  });

  static const defaultNavy = Color(0xFF0A2338);
  static const defaultCyan = Color(0xFF329CEE);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveNavy =
        akdenizColor ?? (isDark ? Colors.white : defaultNavy);
    final effectiveCyan = cepColor ?? defaultCyan;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Akdeniz',
            style: TextStyle(
              color: effectiveNavy,
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: 'Cep',
            style: TextStyle(
              color: effectiveCyan,
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
            ),
          ),
        ],
      ),
    );
  }
}
