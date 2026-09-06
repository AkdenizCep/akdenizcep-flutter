import 'package:flutter/material.dart';
import 'components/followed_clubs_section.dart';
import 'components/my_events_section.dart';

enum ProfileListKind { clubs, joined, created }

class ProfileListPage extends StatelessWidget {
  final ProfileListKind kind;
  const ProfileListPage({super.key, required this.kind});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      title: Text(switch (kind) {
        ProfileListKind.clubs => 'Topluluklarım',
        ProfileListKind.joined => 'Katıldığım etkinlikler',
        ProfileListKind.created => 'Oluşturduğum etkinlikler',
      }),
      backgroundColor: Theme.of(context).colorScheme.surface,
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: kind == ProfileListKind.clubs
            ? const FollowedClubsSection(preview: false)
            : MyEventsSection(
                joined: kind == ProfileListKind.joined,
                limit: null,
              ),
      ),
    ),
  );
}
