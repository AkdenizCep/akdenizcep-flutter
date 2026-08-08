import 'package:flutter/material.dart';

/// Yon secici.
///
/// Durak verisi girilmisse [route] uzerinden "Rektörlük ⇄ Meltem Kapısı"
/// seklinde gercek durak adlarini gosterir. Girilmemisse [fallbackLabel] ile
/// sade "Yön · Gidiş" satirina duser — uydurma durak adi gostermez.
///
/// [canSwitch] false ise (hattin tek yonu tanimliysa) dokunma kapalidir.
class DirectionSwitcher extends StatelessWidget {
  final ({String from, String to})? route;
  final String fallbackLabel;
  final bool canSwitch;
  final VoidCallback onSwitch;

  const DirectionSwitcher({
    super.key,
    required this.route,
    required this.fallbackLabel,
    required this.canSwitch,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: canSwitch,
      label: route == null
          ? 'Yön: $fallbackLabel. Değiştirmek için dokun.'
          : '${route!.from} durağından ${route!.to} durağına. '
                'Yönü çevirmek için dokun.',
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: canSwitch ? onSwitch : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: route == null
                ? _buildSimple(context)
                : _buildRoute(context, route!),
          ),
        ),
      ),
    );
  }

  Widget _buildSimple(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Yön',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        _SwapIcon(enabled: canSwitch),
        Text(
          fallbackLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildRoute(BuildContext context, ({String from, String to}) route) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            route.from,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _SwapIcon(enabled: canSwitch),
        Expanded(
          child: Text(
            route.to,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwapIcon extends StatelessWidget {
  final bool enabled;

  const _SwapIcon({required this.enabled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(
        Icons.swap_horiz_rounded,
        size: 20,
        color: enabled
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}
