import 'package:flutter/material.dart';

/// Üst üste binen katılımcı avatarları. Katılımcı adları elimizde olmadığı için
/// baş harf uid'den türetilir — görsel bir yoğunluk göstergesi olarak yeterli.
class AttendeeAvatars extends StatelessWidget {
  final List<String> attendeeIds;
  final double size;
  final double overlap;
  final int maxVisible;

  const AttendeeAvatars({
    super.key,
    required this.attendeeIds,
    this.size = 28,
    this.overlap = 9,
    this.maxVisible = 4,
  });

  static const _palette = <Color>[
    Color(0xFF135BEC),
    Color(0xFF168A5B),
    Color(0xFFE8601C),
    Color(0xFF7B3FF2),
    Color(0xFF0F7B8A),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visible = attendeeIds.take(maxVisible).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: size,
      width: size + (visible.length - 1) * (size - overlap),
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * (size - overlap),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _palette[visible[index].hashCode.abs() %
                      _palette.length],
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Text(
                  _initial(visible[index]),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.39,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _initial(String uid) =>
      uid.isEmpty ? '?' : uid.substring(0, 1).toUpperCase();
}
