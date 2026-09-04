import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../models/campus_location.dart';
import 'map_category_style.dart';

class LocationDetailsSheet extends StatelessWidget {
  final CampusLocation location;
  final VoidCallback onClose;
  final VoidCallback onShowOnMap;
  final VoidCallback onGetDirections;

  const LocationDetailsSheet({
    super.key,
    required this.location,
    required this.onClose,
    required this.onShowOnMap,
    required this.onGetDirections,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categoryColor = location.category.color(colorScheme);

    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return PointerInterceptor(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 1, end: 0),
          builder: (context, value, child) {
            return FractionalTranslation(
              translation: Offset(0, value),
              child: Opacity(opacity: 1 - value, child: child),
            );
          },
          child: Container(
            key: const ValueKey('location-details-sheet-surface'),
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.50,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22, 12, 22, 22 + safeBottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      SizedBox.square(
                        dimension: 38,
                        child: IconButton(
                          tooltip: 'Kapat',
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          location.category.icon,
                          color: categoryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.name,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              location.category.label,
                              style: textTheme.bodyMedium?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (location.description != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      location.description!,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (location.workingHours != null)
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      title: 'Çalışma Saatleri',
                      content: location.workingHours!,
                    ),
                  if (location.phoneNumber != null)
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      title: 'Telefon',
                      content: location.phoneNumber!,
                    ),
                  if (location.services.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Hizmetler',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final service in location.services)
                          Chip(
                            label: Text(service),
                            avatar: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: categoryColor,
                            ),
                            backgroundColor: categoryColor.withValues(
                              alpha: 0.10,
                            ),
                            labelStyle: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onShowOnMap,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Haritada Göster'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                          ),
                          onPressed: onGetDirections,
                          icon: const Icon(
                            Icons.directions_walk_rounded,
                            size: 18,
                          ),
                          label: const Text('Yol Tarifi'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
