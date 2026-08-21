import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyQrButton extends StatelessWidget {
  const MyQrButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/qr'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.qr_code_2_rounded),
        label: const Text(
          'QR Kodunuz',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
