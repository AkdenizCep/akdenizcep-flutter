import 'package:flutter/material.dart';

/// Etkinlik akışının altındaki "Toplulukları Keşfet" kısayolu.
class DiscoverCommunitiesButton extends StatelessWidget {
  final VoidCallback onTap;

  const DiscoverCommunitiesButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? colorScheme.primaryContainer.withValues(alpha: 0.35)
        : const Color(0xFFEAF1FD);
    final badgeColor = isDark ? colorScheme.primary : const Color(0xFF0C2744);
    final textColor = isDark
        ? colorScheme.onPrimaryContainer
        : const Color(0xFF0C2744);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Toplulukları Keşfet',
                style: textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
