import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/components/progress_snackbar.dart';
import '../../../../shared/providers/nav_visibility_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/utils/error_message.dart';
import '../../../../shared/utils/phone_launcher.dart';
import '../../models/lost_found_category.dart';
import '../../models/lost_found_item.dart';
import '../../providers/lost_found_provider.dart';

/// Bir kayıp/buluntu ilanının tam detayı — fotoğraf, açıklama, iletişim ve
/// (yalnızca ilan sahibine görünen) çözüldü/sil eylemleri.
class LostFoundItemSheet extends ConsumerWidget {
  final LostFoundItem item;

  const LostFoundItemSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, LostFoundItem item) async {
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => LostFoundItemSheet(item: item),
      );
    } finally {
      container.read(bottomNavVisibleProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final category = LostFoundCategory.resolve(item.category);
    final typeColor = item.isLost ? colorScheme.error : const Color(0xFF168A5B);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwner = currentUser != null && currentUser.id == item.authorUid;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (item.imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Text(
                    item.isLost ? 'KAYIP' : 'BULUNDU',
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  if (item.isResolved) ...[
                    const SizedBox(width: 10),
                    Container(width: 3, height: 3, decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    )),
                    const SizedBox(width: 10),
                    Text(
                      'ÇÖZÜLDÜ',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              _InfoRow(icon: category.icon, text: category.label),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.location_on_outlined, text: item.location),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.schedule_rounded,
                text: DateFormat('d MMMM yyyy, HH:mm', 'tr').format(item.createdAt),
              ),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.person_outline_rounded, text: item.authorName),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  item.description,
                  style: textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ],
              const SizedBox(height: 24),
              if (item.contactPhone.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _call(context, item.contactPhone),
                    icon: const Icon(Icons.phone_rounded),
                    label: Text('Ara · ${item.contactPhone}'),
                  ),
                ),
              if (isOwner) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleResolved(context, ref, currentUser.id),
                    icon: Icon(
                      item.isResolved
                          ? Icons.replay_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                    label: Text(
                      item.isResolved
                          ? 'Yeniden aç'
                          : 'Sahibine ulaştı, çözüldü işaretle',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _delete(context, ref, currentUser.id),
                    style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('İlanı sil'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final launched = await launchPhoneCall(phone);
    if (!launched && context.mounted) {
      showProgressSnackBar(
        context,
        message: 'Arama uygulaması açılamadı.',
        icon: Icons.error_outline_rounded,
        accentColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _toggleResolved(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) async {
    try {
      await ref
          .read(lostFoundServiceProvider)
          .setResolved(itemId: item.id, authorUid: uid, resolved: !item.isResolved);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        showProgressSnackBar(
          context,
          message: errorMessage(e),
          icon: Icons.error_outline_rounded,
          accentColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İlanı Sil'),
        content: const Text('Bu ilanı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(lostFoundServiceProvider)
          .deleteItem(itemId: item.id, authorUid: uid);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        showProgressSnackBar(
          context,
          message: errorMessage(e),
          icon: Icons.error_outline_rounded,
          accentColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
