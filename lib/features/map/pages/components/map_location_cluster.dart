import 'dart:math' as math;

import '../../models/campus_location.dart';

class MapLocationCluster {
  final List<CampusLocation> locations;
  final double latitude;
  final double longitude;

  const MapLocationCluster({
    required this.locations,
    required this.latitude,
    required this.longitude,
  });

  bool get isCluster => locations.length > 1;

  String get id {
    final ids = locations.map((location) => location.id).toList()..sort();
    return ids.join('_');
  }
}

List<MapLocationCluster> clusterMapLocations(
  List<CampusLocation> locations, {
  required double zoom,
  double radiusInLogicalPixels = 58,
}) {
  if (locations.isEmpty) return const [];

  final projectedLocations =
      locations
          .map((location) => _ProjectedLocation.fromLocation(location, zoom))
          .toList()
        ..sort(
          (first, second) => first.location.id.compareTo(second.location.id),
        );
  final groups = <_ProjectedCluster>[];

  for (final location in projectedLocations) {
    _ProjectedCluster? nearestGroup;
    var nearestDistance = double.infinity;

    for (final group in groups) {
      final horizontalDistance = location.x - group.centerX;
      final verticalDistance = location.y - group.centerY;
      final distance = math.sqrt(
        horizontalDistance * horizontalDistance +
            verticalDistance * verticalDistance,
      );
      if (distance <= radiusInLogicalPixels && distance < nearestDistance) {
        nearestGroup = group;
        nearestDistance = distance;
      }
    }

    if (nearestGroup == null) {
      groups.add(_ProjectedCluster(location));
    } else {
      nearestGroup.add(location);
    }
  }

  return groups.map((group) => group.toCluster()).toList();
}

class _ProjectedLocation {
  final CampusLocation location;
  final double x;
  final double y;

  const _ProjectedLocation({
    required this.location,
    required this.x,
    required this.y,
  });

  factory _ProjectedLocation.fromLocation(
    CampusLocation location,
    double zoom,
  ) {
    final worldSize = 256 * math.pow(2, zoom);
    final latitudeRadians = location.latitude * math.pi / 180;
    final sine = math.sin(latitudeRadians).clamp(-0.9999, 0.9999);

    return _ProjectedLocation(
      location: location,
      x: (location.longitude + 180) / 360 * worldSize,
      y: (0.5 - math.log((1 + sine) / (1 - sine)) / (4 * math.pi)) * worldSize,
    );
  }
}

class _ProjectedCluster {
  final List<_ProjectedLocation> locations;
  double centerX;
  double centerY;

  _ProjectedCluster(_ProjectedLocation location)
    : locations = [location],
      centerX = location.x,
      centerY = location.y;

  void add(_ProjectedLocation location) {
    locations.add(location);
    centerX =
        locations.fold<double>(0, (sum, item) => sum + item.x) /
        locations.length;
    centerY =
        locations.fold<double>(0, (sum, item) => sum + item.y) /
        locations.length;
  }

  MapLocationCluster toCluster() {
    final campusLocations = locations.map((item) => item.location).toList();
    return MapLocationCluster(
      locations: campusLocations,
      latitude:
          campusLocations.fold<double>(
            0,
            (sum, location) => sum + location.latitude,
          ) /
          campusLocations.length,
      longitude:
          campusLocations.fold<double>(
            0,
            (sum, location) => sum + location.longitude,
          ) /
          campusLocations.length,
    );
  }
}
