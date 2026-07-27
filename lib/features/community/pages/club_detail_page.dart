import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../providers/community_provider.dart';

class ClubDetailPage extends ConsumerWidget {
  final String clubId;

  const ClubDetailPage({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubDetailProvider(clubId));
    final eventsAsync = ref.watch(clubEventsProvider(clubId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Kulup Detay')),
      body: clubAsync.when(
        data: (club) {
          final isFollowing =
              currentUser?.followedClubs.contains(clubId) ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: club.logoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(club.logoUrl)
                        : null,
                    child: club.logoUrl.isEmpty
                        ? Text(
                            club.name.isNotEmpty ? club.name[0] : '',
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    club.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Chip(label: Text(club.category))),
                const SizedBox(height: 8),
                Center(child: Text('${club.followerCount} takipci')),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (currentUser == null) return;
                      final service = ref.read(communityServiceProvider);
                      if (isFollowing) {
                        await service.unfollowClub(currentUser.id, clubId);
                      } else {
                        await service.followClub(currentUser.id, clubId);
                      }
                    },
                    icon: Icon(isFollowing ? Icons.check : Icons.add),
                    label: Text(isFollowing ? 'Takip Ediliyor' : 'Takip Et'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Etkinlikler',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Henuz etkinlik yok.'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(event.title),
                            subtitle: Text(event.location),
                            onTap: () => context.go(
                              '/home/community/$clubId/event/${event.id}',
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingOverlay(),
                  error: (e, _) => ErrorView(message: errorMessage(e)),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
    );
  }
}
