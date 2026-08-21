import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers/event_feed_provider.dart';

/// Kaynak filtresi: Akıcı animasyonlu Topluluk / Öğrenci toggle'ı ve Toplulukları Keşfet butonu.
class SourceFilterRow extends ConsumerWidget {
  const SourceFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSourceProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Smooth Animated Sliding Toggle
          _SlidingSourceToggle(
            selected: selected,
            onChanged: (filter) =>
                ref.read(selectedSourceProvider.notifier).state = filter,
          ),
          const SizedBox(width: 10),
          // Toplulukları Keşfet Button
          _DiscoverCommunitiesButton(
            onTap: () => context.push('/community'),
          ),
        ],
      ),
    );
  }
}

class _SlidingSourceToggle extends StatelessWidget {
  final EventSourceFilter selected;
  final ValueChanged<EventSourceFilter> onChanged;

  const _SlidingSourceToggle({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClub = selected == EventSourceFilter.club;

    return Container(
      width: 208,
      height: 40,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : const Color(0xFFF1F3F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // 1. Sliding Indicator Capsule
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            alignment: isClub ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.08,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Interactive Segments
          Row(
            children: [
              Expanded(
                child: _ToggleItem(
                  label: 'Topluluk',
                  icon: Icons.groups_2_rounded,
                  isSelected: isClub,
                  onTap: () => onChanged(EventSourceFilter.club),
                ),
              ),
              Expanded(
                child: _ToggleItem(
                  label: 'Öğrenci',
                  icon: Icons.person_rounded,
                  isSelected: !isClub,
                  onTap: () => onChanged(EventSourceFilter.student),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final targetColor = isSelected
        ? (isDark ? Colors.white : const Color(0xFF0C2442))
        : (isDark ? colorScheme.onSurfaceVariant : const Color(0xFF5E6573));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 200),
          tween: ColorTween(end: targetColor),
          builder: (context, color, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: color,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DiscoverCommunitiesButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DiscoverCommunitiesButton({required this.onTap});

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


