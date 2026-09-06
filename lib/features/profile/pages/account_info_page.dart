import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';

class AccountInfoPage extends ConsumerWidget {
  const AccountInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Hesap bilgileri')),
    body: SafeArea(
      top: false,
      child: ref
          .watch(currentUserProvider)
          .when(
            loading: () => const LoadingOverlay(),
            error: (e, _) => ErrorView(
              message: errorMessage(e),
              onRetry: () => ref.invalidate(currentUserProvider),
            ),
            data: (user) {
              if (user == null) {
                return const Center(
                  child: Text('Hesap bilgilerin için oturum açmalısın.'),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  for (final entry in {
                    'Ad soyad': user.name,
                    'E-posta': user.email,
                    'Öğrenci numarası': user.studentId,
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            entry.value.isEmpty ? 'Kayıtlı değil' : entry.value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
    ),
  );
}
