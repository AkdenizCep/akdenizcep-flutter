import 'package:flutter/material.dart';

enum CampusServiceTone { primary, alert }

class CampusServiceDestination {
  final String title;
  final String description;
  final IconData icon;
  final CampusServiceTone tone;
  final VoidCallback onTap;

  const CampusServiceDestination({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.tone = CampusServiceTone.primary,
  });
}

class CampusServiceGroup extends StatelessWidget {
  final List<CampusServiceDestination> destinations;

  const CampusServiceGroup({super.key, required this.destinations});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.56),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < destinations.length; index++) ...[
              _CampusServiceRow(destination: destinations[index]),
              if (index != destinations.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 72,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.62),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class CampusSectionTitle extends StatelessWidget {
  final String title;

  const CampusSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        fontSize: 12,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _CampusServiceRow extends StatelessWidget {
  final CampusServiceDestination destination;

  const _CampusServiceRow({required this.destination});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = destination.tone == CampusServiceTone.alert
        ? colorScheme.error
        : colorScheme.primary;

    return Semantics(
      button: true,
      label: destination.title,
      hint: destination.description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: destination.onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(destination.icon, size: 22, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        destination.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
