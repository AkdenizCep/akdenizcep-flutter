import 'package:flutter/material.dart';

class MapActionButtons extends StatelessWidget {
  final VoidCallback onMyLocation;
  final VoidCallback onCenterCampus;

  const MapActionButtons({
    super.key,
    required this.onMyLocation,
    required this.onCenterCampus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapActionButton(
          tooltip: 'Konumuma git',
          icon: Icons.my_location_rounded,
          onPressed: onMyLocation,
        ),
        const SizedBox(height: 10),
        _MapActionButton(
          tooltip: 'Kampüse dön',
          icon: Icons.center_focus_strong_rounded,
          onPressed: onCenterCampus,
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _MapActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surface.withValues(alpha: 0.96),
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
