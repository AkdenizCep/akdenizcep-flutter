import 'package:flutter/material.dart';

class RatingRow extends StatelessWidget {
  final double? avgRating;
  final bool enabled;
  final ValueChanged<int> onStarTap;

  const RatingRow({
    super.key,
    required this.avgRating,
    required this.enabled,
    required this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filledCount = avgRating?.round() ?? 0;
    final label = !enabled
        ? 'Puan vermek için giriş yapın'
        : avgRating == null
        ? 'İlk oyu sen ver!'
        : 'Bu yemeği puanla';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8A317), Color(0xFFE85D17)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.star_rate_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
          Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Row(
              children: List.generate(5, (i) {
                return _StarButton(
                  filled: i < filledCount,
                  onTap: enabled ? () => onStarTap(i + 1) : null,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  final bool filled;
  final VoidCallback? onTap;

  const _StarButton({required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.star_rounded,
            size: 26,
            color: filled
                ? const Color(0xFFE8A317)
                : colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}
