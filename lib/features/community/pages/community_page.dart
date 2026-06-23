import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/utils/error_message.dart';
import '../providers/community_provider.dart';

class CommunityPage extends ConsumerWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kulupler')),
      body: clubsAsync.when(
        data: (clubs) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clubs.length,
          itemBuilder: (context, index) {
            final club = clubs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: club.logoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(club.logoUrl)
                      : null,
                  child: club.logoUrl.isEmpty
                      ? Text(club.name.isNotEmpty ? club.name[0] : '')
                      : null,
                ),
                title: Text(club.name),
                subtitle: Text(club.category),
                trailing: Text('${club.followerCount} takipci'),
                onTap: () => context.go('/home/community/${club.id}'),
              ),
            );
          },
        ),
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
    );
  }
}
