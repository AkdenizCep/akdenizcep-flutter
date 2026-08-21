import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import 'components/change_password_button.dart';
import 'components/feedback_button.dart';
import 'components/followed_clubs_section.dart';
import 'components/my_events_section.dart';
import 'components/my_qr_button.dart';
import 'components/profile_info_card.dart';
import 'components/rated_meals_section.dart';
import 'components/sign_out_button.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              132 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileInfoCard(user: user),
                const SizedBox(height: 16),
                const MyQrButton(),
                const SizedBox(height: 28),
                _SectionTitle(title: 'Takip Edilen Topluluklar'),
                const SizedBox(height: 12),
                const FollowedClubsSection(),
                const SizedBox(height: 28),
                _SectionTitle(title: 'Oluşturduğun Etkinlikler'),
                const SizedBox(height: 12),
                const MyEventsSection(),
                const SizedBox(height: 28),
                _SectionTitle(title: 'Yemekhane Puanların'),
                const SizedBox(height: 12),
                const RatedMealsSection(),
                const SizedBox(height: 28),
                _SectionTitle(title: 'Geri Bildirim'),
                const SizedBox(height: 12),
                FeedbackButton(user: user),
                const SizedBox(height: 28),
                ChangePasswordButton(email: user.email),
                const SizedBox(height: 12),
                const SignOutButton(),
              ],
            ),
          );
        },
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      // Buyuk yazi tipi olceginde baslik iki satira inebilir; cubuk ilk
      // satirla hizali kalsin.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 14,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              height: 1.35,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}
