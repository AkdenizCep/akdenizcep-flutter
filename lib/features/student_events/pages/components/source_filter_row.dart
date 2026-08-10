import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/event_feed_provider.dart';

/// Kaynak filtresi: Tümü / Kulüp etkinlikleri / Öğrenci etkinlikleri.
/// Kategori filtresiyle AND ile birleşir.
class SourceFilterRow extends ConsumerWidget {
  const SourceFilterRow({super.key});

  static const _options = <(EventSourceFilter, String, IconData)>[
    (EventSourceFilter.all, 'Tümü', Icons.apps_rounded),
    (EventSourceFilter.club, 'Kulüp etkinlikleri', Icons.groups_2_rounded),
    (EventSourceFilter.student, 'Öğrenci etkinlikleri', Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSourceProvider);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label, icon) = _options[index];
          return _SourceChip(
            label: label,
            icon: icon,
            selected: value == selected,
            onTap: () =>
                ref.read(selectedSourceProvider.notifier).state = value,
          );
        },
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SourceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? colorScheme.surface
        : colorScheme.onSurfaceVariant;

    return Material(
      color: selected ? colorScheme.onSurface : colorScheme.surface,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: selected ? Colors.transparent : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: foreground),
              const SizedBox(width: 7),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
