import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_provider.dart';

/// Üst üste binen katılımcı profil avatarları.
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

  @override
  Widget build(BuildContext context) {
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
              child: _SingleAttendeeAvatar(
                uid: visible[index],
                size: size,
              ),
            ),
        ],
      ),
    );
  }
}

class _SingleAttendeeAvatar extends ConsumerWidget {
  final String uid;
  final double size;

  const _SingleAttendeeAvatar({
    required this.uid,
    required this.size,
  });

  static const _palette = <Color>[
    Color(0xFF135BEC),
    Color(0xFF168A5B),
    Color(0xFFE8601C),
    Color(0xFF7B3FF2),
    Color(0xFF0F7B8A),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(userProfileProvider(uid));
    final profile = profileAsync.valueOrNull;

    final photoUrl = profile?.photoUrl ?? '';
    final name = profile?.name ?? '';
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : (uid.isNotEmpty ? uid.substring(0, 1).toUpperCase() : '?');

    final fallback = ColoredBox(
      color: _palette[uid.hashCode.abs() % _palette.length],
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.39,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 2),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}
