import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/components/photo_source_sheet.dart';
import '../../../shared/components/progress_snackbar.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../auth/models/app_user.dart';
import '../providers/profile_provider.dart';
import 'components/change_password_button.dart';
import 'components/feedback_button.dart';
import 'components/followed_clubs_section.dart';
import 'components/my_events_section.dart';
import 'components/my_qr_button.dart';
import 'components/profile_info_card.dart';
import 'components/rated_meals_section.dart';
import 'components/sign_out_button.dart';
import 'components/theme_selection_button.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _openPhotoActions(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final action = await chooseProfilePhotoAction(
      context,
      canRemove: user.photoUrl.isNotEmpty,
    );
    if (action == null || !context.mounted) return;

    if (action == ProfilePhotoAction.remove) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Profil fotoğrafı kaldırılsın mı?'),
          content: const Text(
            'Fotoğrafın silinecek ve profilinde yeniden baş harfin görünecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => dialogContext.pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => dialogContext.pop(true),
              child: const Text('Kaldır'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await _removePhoto(context, ref);
      return;
    }

    await _pickAndEditPhoto(context, ref, action);
  }

  Future<void> _pickAndEditPhoto(
    BuildContext context,
    WidgetRef ref,
    ProfilePhotoAction action,
  ) async {
    try {
      final source = action == ProfilePhotoAction.camera
          ? ImageSource.camera
          : ImageSource.gallery;
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 92,
        requestFullMetadata: false,
      );
      if (picked == null || !context.mounted) return;

      final sourceBytes = await picked.readAsBytes();
      if (!context.mounted) return;
      final jpegBytes = await context.push<Uint8List>(
        '/profile/photo-editor',
        extra: sourceBytes,
      );
      if (jpegBytes == null || !context.mounted) return;

      await ref.read(profilePhotoControllerProvider.notifier).upload(jpegBytes);
      if (!context.mounted) return;
      showProgressSnackBar(
        context,
        message: 'Profil fotoğrafın güncellendi.',
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (error, stackTrace) {
      debugPrint('Profil fotoğrafı güncellenirken hata oluştu: $error\n$stackTrace');
      if (!context.mounted) return;
      showProgressSnackBar(
        context,
        message: errorMessage(error),
        icon: Icons.error_outline_rounded,
        accentColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _removePhoto(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profilePhotoControllerProvider.notifier).remove();
      if (!context.mounted) return;
      showProgressSnackBar(
        context,
        message: 'Profil fotoğrafın kaldırıldı.',
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (error, stackTrace) {
      debugPrint('Profil fotoğrafı kaldırılırken hata oluştu: $error\n$stackTrace');
      if (!context.mounted) return;
      showProgressSnackBar(
        context,
        message: errorMessage(error),
        icon: Icons.error_outline_rounded,
        accentColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final photoBusy = ref.watch(profilePhotoControllerProvider).isLoading;

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
                ProfileInfoCard(
                  user: user,
                  photoBusy: photoBusy,
                  onPhotoTap: () => _openPhotoActions(context, ref, user),
                ),
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
                const ThemeSelectionButton(),
                const SizedBox(height: 12),
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
