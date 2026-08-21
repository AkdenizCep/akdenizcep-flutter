import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/campus_location.dart';
import '../services/map_service.dart';

final mapServiceProvider = Provider<MapService>((_) => MapService());

final campusLocationsProvider = FutureProvider<List<CampusLocation>>((ref) {
  return ref.watch(mapServiceProvider).getCampusLocations();
});

final selectedMapCategoryProvider = StateProvider<LocationCategory?>(
  (_) => null,
);

final mapSearchQueryProvider = StateProvider<String>((_) => '');

final selectedCampusLocationProvider = StateProvider<CampusLocation?>(
  (_) => null,
);

final mapMyLocationEnabledProvider = StateProvider<bool>((_) => false);

final filteredCampusLocationsProvider =
    Provider<AsyncValue<List<CampusLocation>>>((ref) {
      final locationsAsync = ref.watch(campusLocationsProvider);
      final selectedCategory = ref.watch(selectedMapCategoryProvider);
      final query = _normalizeSearchText(ref.watch(mapSearchQueryProvider));

      return locationsAsync.whenData((locations) {
        return locations.where((location) {
          final matchesCategory =
              selectedCategory == null || location.category == selectedCategory;
          final searchableText = [
            location.name,
            location.description,
            location.category.label,
            ...location.services,
          ].whereType<String>().join(' ');
          final matchesQuery =
              query.isEmpty ||
              _normalizeSearchText(searchableText).contains(query);
          return matchesCategory && matchesQuery;
        }).toList();
      });
    });

String _normalizeSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('i̇', 'i')
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}
