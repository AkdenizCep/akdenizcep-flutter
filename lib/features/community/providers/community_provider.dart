import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/club.dart';
import '../models/club_event.dart';
import '../models/club_member.dart';
import '../services/community_service.dart';

final communityServiceProvider = Provider((_) => CommunityService());

final clubsProvider = StreamProvider<List<Club>>((ref) {
  return ref.watch(communityServiceProvider).getClubs();
});

final clubDetailProvider = StreamProvider.family<Club, String>((ref, clubId) {
  return ref.watch(communityServiceProvider).getClub(clubId);
});

final clubEventsProvider = StreamProvider.family<List<ClubEvent>, String>((
  ref,
  clubId,
) {
  return ref.watch(communityServiceProvider).getClubEvents(clubId);
});

final clubMembersProvider = StreamProvider.family<List<ClubMember>, String>((
  ref,
  clubId,
) {
  return ref.watch(communityServiceProvider).getClubMembers(clubId);
});

final clubSearchQueryProvider = StateProvider<String>((ref) => '');
final clubCategoryFilterProvider = StateProvider<String>((ref) => 'Tümü');

final filteredClubsProvider = Provider<AsyncValue<List<Club>>>((ref) {
  final clubsAsync = ref.watch(clubsProvider);
  final query = ref.watch(clubSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(clubCategoryFilterProvider);

  return clubsAsync.whenData((clubs) {
    return clubs.where((club) {
      final matchesQuery = query.isEmpty ||
          club.name.toLowerCase().contains(query) ||
          club.description.toLowerCase().contains(query) ||
          club.category.toLowerCase().contains(query);
      final matchesCategory = category == 'Tümü' || club.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  });
});

