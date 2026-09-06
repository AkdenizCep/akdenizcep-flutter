import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/models/app_user.dart';
import '../../../../shared/utils/error_message.dart';
import '../../providers/profile_settings_provider.dart';
import 'settings_tile.dart';

class FeedbackButton extends ConsumerWidget {
  final AppUser user;
  const FeedbackButton({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsTile(
    title: 'Geri bildirim',
    subtitle: 'Görüş ve önerilerini paylaş',
    onTap: () async {
      final sent = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _FeedbackDialog(),
      );
      if (sent == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teşekkürler! Geri bildirimin iletildi.'),
          ),
        );
      }
    },
  );
}

class _FeedbackDialog extends ConsumerStatefulWidget {
  const _FeedbackDialog();

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = profileSettingsActionProvider(
      ProfileSettingsAction.feedback,
    );
    final state = ref.watch(provider);
    return PopScope(
      canPop: !state.isLoading,
      child: AlertDialog(
        title: const Text('Geri bildirim'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _controller,
                  enabled: !state.isLoading,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Mesajın',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Lütfen bir mesaj yaz.'
                      : null,
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      errorMessage(state.error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.isLoading ? null : () => context.pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    try {
                      await ref
                          .read(provider.notifier)
                          .submit(message: _controller.text);
                      if (context.mounted) context.pop(true);
                    } catch (_) {
                      // Mesaj ve hata dialogda korunur; öğrenci tekrar deneyebilir.
                    }
                  },
            child: state.isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}
