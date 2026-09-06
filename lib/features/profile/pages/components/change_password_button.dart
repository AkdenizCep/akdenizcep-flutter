import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/error_message.dart';
import '../../providers/profile_settings_provider.dart';
import 'settings_tile.dart';

class ChangePasswordButton extends ConsumerWidget {
  final String email;
  const ChangePasswordButton({super.key, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = profileSettingsActionProvider(
      ProfileSettingsAction.password,
    );
    return SettingsTile(
      title: 'Şifre değiştir',
      busy: ref.watch(provider).isLoading,
      onTap: () async {
        try {
          await ref.read(provider.notifier).submit();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Şifre sıfırlama bağlantısı $email adresine gönderildi.',
              ),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
        }
      },
    );
  }
}
