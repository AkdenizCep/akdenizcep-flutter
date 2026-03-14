import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/club.dart';
import '../models/club_event.dart';
import '../services/community_service.dart';

final communityServiceProvider = Provider((_) => CommunityService());

final clubsProvider = StreamProvider<List<Club>>((ref) {
  return ref.watch(communityServiceProvider).getClubs();
});

final clubDetailProvider =
    StreamProvider.family<Club, String>((ref, clubId) {
  return ref.watch(communityServiceProvider).getClub(clubId);
});

final clubEventsProvider =
    StreamProvider.family<List<ClubEvent>, String>((ref, clubId) {
  return ref.watch(communityServiceProvider).getClubEvents(clubId);
});
