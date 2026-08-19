import 'package:flutter/material.dart';

/// Yemekhane sayfasindaki uc kartin (menu, puan, yorum) ortak kabugu.
/// Yaricap, golge ve zemin tek yerde tanimli olsun diye ayrildi.
class CafeteriaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CafeteriaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.5 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
