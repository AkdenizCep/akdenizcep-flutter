import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/user_provider.dart';
import 'profile_provider.dart';

enum ProfileSettingsAction { password, feedback, signOut }

final profileSettingsActionProvider = AsyncNotifierProvider.autoDispose
    .family<ProfileSettingsController, void, ProfileSettingsAction>(
      ProfileSettingsController.new,
    );

class ProfileSettingsController
    extends AutoDisposeFamilyAsyncNotifier<void, ProfileSettingsAction> {
  @override
  void build(ProfileSettingsAction arg) {}

  Future<void> submit({String message = ''}) async {
    if (state.isLoading) return;
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      final service = ref.read(userServiceProvider);
      if (arg == ProfileSettingsAction.signOut) {
        await service.signOut();
      } else {
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user == null) throw Exception('Bu işlem için oturum açmalısın.');
        if (arg == ProfileSettingsAction.password) {
          await service.sendPasswordResetEmail(user.email);
        } else {
          final trimmed = message.trim();
          if (trimmed.isEmpty) throw Exception('Lütfen bir mesaj yaz.');
          await ref
              .read(profileServiceProvider)
              .sendFeedback(
                uid: user.id,
                authorName: user.name,
                email: user.email,
                message: trimmed,
              );
        }
      }
      state = const AsyncData(null);
    } catch (error, stack) {
      state = AsyncError(error, stack);
      Error.throwWithStackTrace(error, stack);
    } finally {
      keepAlive.close();
    }
  }
}
