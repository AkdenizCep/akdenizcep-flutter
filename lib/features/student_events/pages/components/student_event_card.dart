import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/student_event.dart';

class StudentEventCard extends StatelessWidget {
  final StudentEvent event;
  final VoidCallback onTap;

  const StudentEventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visualStyle = _EventVisualStyle.fromEvent(event);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: visualStyle.color.withValues(alpha: 0.14),
                    child: Icon(
                      visualStyle.icon,
                      color: visualStyle.color,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Öğrenci Etkinliği',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_relativeCreatedAt(event.createdAt)} paylaşıldı',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Etkinlik seçenekleri',
                    onPressed: () {},
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _EventVisual(event: event, style: visualStyle),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 19,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    event.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 19,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          DateFormat('d MMMM, HH:mm', 'tr').format(event.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(96, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Detay'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeCreatedAt(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inMinutes < 1) return 'Şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
    if (difference.inHours < 24) return '${difference.inHours} saat önce';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';

    return DateFormat('d MMMM', 'tr').format(createdAt);
  }
}

class _EventVisual extends StatelessWidget {
  final StudentEvent event;
  final _EventVisualStyle style;

  const _EventVisual({required this.event, required this.style});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  style.color.withValues(alpha: 0.95),
                  style.color.withValues(alpha: 0.48),
                  colorScheme.primary.withValues(alpha: 0.52),
                ],
              ),
            ),
          ),
          Positioned(
            right: -28,
            top: -24,
            child: Icon(
              style.icon,
              size: 154,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 22,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Icon(style.icon, color: Colors.white, size: 38),
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat(
                      'd MMM, HH:mm',
                      'tr',
                    ).format(event.date).toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventVisualStyle {
  final Color color;
  final IconData icon;

  const _EventVisualStyle({required this.color, required this.icon});

  factory _EventVisualStyle.fromEvent(StudentEvent event) {
    final text = '${event.title} ${event.description}'.toLowerCase();

    if (_containsAny(text, const ['spor', 'turnuva', 'koşu', 'futbol'])) {
      return const _EventVisualStyle(
        color: Color(0xFF168A5B),
        icon: Icons.sports_soccer_rounded,
      );
    }
    if (_containsAny(text, const ['fotoğraf', 'çekim', 'sanat', 'sergi'])) {
      return const _EventVisualStyle(
        color: Color(0xFFE8601C),
        icon: Icons.photo_camera_rounded,
      );
    }
    if (_containsAny(text, const [
      'teknoloji',
      'yazılım',
      'yapay zeka',
      'ai',
    ])) {
      return const _EventVisualStyle(
        color: Color(0xFF135BEC),
        icon: Icons.memory_rounded,
      );
    }
    if (_containsAny(text, const ['müzik', 'konser', 'sahne'])) {
      return const _EventVisualStyle(
        color: Color(0xFF7B3FF2),
        icon: Icons.music_note_rounded,
      );
    }

    return const _EventVisualStyle(
      color: Color(0xFF135BEC),
      icon: Icons.event_rounded,
    );
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}
