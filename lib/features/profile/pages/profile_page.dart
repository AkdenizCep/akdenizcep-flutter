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
import 'components/followed_clubs_section.dart';
import 'components/my_events_section.dart';
import 'components/profile_info_card.dart';
import 'components/profile_section.dart';

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
      debugPrint(
        'Profil fotoğrafı güncellenirken hata oluştu: $error\n$stackTrace',
      );
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
      debugPrint(
        'Profil fotoğrafı kaldırılırken hata oluştu: $error\n$stackTrace',
      );
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
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Profilim'),
        centerTitle: false,
        backgroundColor: colors.surface,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            onPressed: () => context.push('/profile/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text('Profilini görmek için oturum açmalısın.'),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileInfoCard(
                    user: user,
                    photoBusy: photoBusy,
                    onPhotoTap: () => _openPhotoActions(context, ref, user),
                  ),
                  const SizedBox(height: 48),
                  ProfileSection(
                    title: 'Topluluklarım',
                    onViewAll: () => context.push('/profile/clubs'),
                    child: const FollowedClubsSection(),
                  ),
                  const SizedBox(height: 32),
                  ProfileSection(
                    title: 'Katıldığım',
                    onViewAll: () => context.push('/profile/joined-events'),
                    child: const MyEventsSection(joined: true),
                  ),
                  const SizedBox(height: 24),
                  ProfileSection(
                    title: 'Oluşturduğum',
                    onViewAll: () => context.push('/profile/created-events'),
                    child: const MyEventsSection(),
                  ),
                ],
              ),
            );
          },
          loading: () => const LoadingOverlay(),
          error: (e, _) => ErrorView(
            message: errorMessage(e),
            onRetry: () => ref.invalidate(currentUserProvider),
          ),
        ),
      ),
    );
  }
}
