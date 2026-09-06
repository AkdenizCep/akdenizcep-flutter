import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/utils/error_message.dart';
import '../../providers/profile_settings_provider.dart';

class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final provider = profileSettingsActionProvider(
      ProfileSettingsAction.signOut,
    );
    final busy = ref.watch(provider).isLoading;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: colors.error,
          backgroundColor: colors.surface,
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: busy
            ? null
            : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Çıkış yap'),
                    content: const Text('Çıkış yapmak istediğine emin misin?'),
                    actions: [
                      TextButton(
                        onPressed: () => dialogContext.pop(false),
                        child: const Text('Vazgeç'),
                      ),
                      FilledButton(
                        onPressed: () => dialogContext.pop(true),
                        child: const Text('Çıkış yap'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                try {
                  await ref.read(provider.notifier).submit();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
                }
              },
        child: busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Çıkış yap',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
