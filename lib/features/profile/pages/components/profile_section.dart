import 'package:flutter/material.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  final Widget child;

  const ProfileSection({
    super.key,
    required this.title,
    required this.onViewAll,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Tümünü gör'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      child,
    ],
  );
}
