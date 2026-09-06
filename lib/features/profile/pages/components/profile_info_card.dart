import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/models/app_user.dart';
import '../../../../shared/components/user_avatar.dart';

class ProfileInfoCard extends StatelessWidget {
  final AppUser user;
  final bool photoBusy;
  final VoidCallback onPhotoTap;

  const ProfileInfoCard({
    super.key,
    required this.user,
    required this.photoBusy,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Semantics(
          button: true,
          enabled: !photoBusy,
          child: Tooltip(
            message: 'Profil fotoğrafını değiştir',
            child: InkWell(
              onTap: photoBusy ? null : onPhotoTap,
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  UserAvatar(
                    name: user.name,
                    imageUrl: user.photoUrl,
                    diameter: 72,
                  ),
                  if (photoBusy)
                    const SizedBox.square(
                      dimension: 72,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name.isEmpty ? 'Öğrenci' : user.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/qr'),
                icon: const Icon(Icons.qr_code_rounded, size: 24),
                label: const Text('QR kodum'),
                style: FilledButton.styleFrom(
                  foregroundColor: colors.primary,
                  backgroundColor: colors.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
