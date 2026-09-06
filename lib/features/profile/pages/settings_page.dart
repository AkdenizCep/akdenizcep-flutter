import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import 'components/settings_tile.dart';
import 'components/change_password_button.dart';
import 'components/feedback_button.dart';
import 'components/sign_out_button.dart';
import 'components/theme_selection_button.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), centerTitle: false),
      body: SafeArea(
        top: false,
        child: user.when(
          loading: () => const LoadingOverlay(),
          error: (e, _) => ErrorView(
            message: errorMessage(e),
            onRetry: () => ref.invalidate(currentUserProvider),
          ),
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text('Ayarlar için oturum açmalısın.'),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _SettingsGroup(
                  title: 'HESAP',
                  children: [
                    SettingsTile(
                      title: 'Hesap bilgileri',
                      subtitle: 'E-posta ve öğrenci numarası',
                      onTap: () => context.push('/profile/settings/account'),
                    ),
                    ChangePasswordButton(email: user.email),
                  ],
                ),
                const SizedBox(height: 28),
                _SettingsGroup(
                  title: 'UYGULAMA',
                  children: [
                    const ThemeSelectionButton(asSettingsTile: true),
                    FeedbackButton(user: user),
                  ],
                ),
                const SizedBox(height: 28),
                const SignOutButton(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    ],
  );
}
