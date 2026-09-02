import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF135BEC), Color(0xFF5C4FE0)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF135BEC).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: photoBusy ? null : onPhotoTap,
            child: Tooltip(
              message: 'Profil fotoğrafını değiştir',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.42),
                      ),
                    ),
                    child: UserAvatar(
                      name: user.name,
                      imageUrl: user.photoUrl,
                      diameter: 76,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  if (photoBusy)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: const Center(
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name.isNotEmpty ? user.name : 'Öğrenci',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.badge_rounded,
                  label: 'Öğrenci No',
                  value: user.studentId.isNotEmpty ? user.studentId : '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Üyelik',
                  value: DateFormat('d MMMM yyyy', 'tr').format(user.createdAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}
