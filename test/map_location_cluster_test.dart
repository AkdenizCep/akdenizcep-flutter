import 'package:akdenizcep/features/map/models/campus_location.dart';
import 'package:akdenizcep/features/map/pages/components/map_location_cluster.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const firstFaculty = CampusLocation(
    id: 'faculty-a',
    name: 'A Fakültesi',
    latitude: 36.89690,
    longitude: 30.65120,
    category: LocationCategory.faculty,
  );
  const secondFaculty = CampusLocation(
    id: 'faculty-b',
    name: 'B Fakültesi',
    latitude: 36.89702,
    longitude: 30.65134,
    category: LocationCategory.faculty,
  );
  const diningHall = CampusLocation(
    id: 'dining',
    name: 'Yemekhane',
    latitude: 36.90690,
    longitude: 30.66120,
    category: LocationCategory.dining,
  );

  test('uzak görünümde yalnızca yakın konumları aynı gruba alır', () {
    final groups = clusterMapLocations(const [
      firstFaculty,
      secondFaculty,
      diningHall,
    ], zoom: 14.5);

    expect(groups, hasLength(2));
    expect(
      groups.singleWhere((group) => group.isCluster).locations,
      hasLength(2),
    );
  });
}
