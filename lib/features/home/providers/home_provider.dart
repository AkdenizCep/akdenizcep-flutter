import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement.dart';
import '../models/home_event.dart';
import '../services/home_service.dart';

final homeServiceProvider = Provider((_) => HomeService());

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  return ref.watch(homeServiceProvider).getAnnouncements();
});

final upcomingEventsProvider = StreamProvider<List<HomeEvent>>((ref) {
  return ref.watch(homeServiceProvider).getUpcomingEvents();
});
