import 'dart:math' as math;

import '../../models/ring_stop.dart';
import '../../models/route_shape.dart';

/// Bir guzergahi haritada bastan sona gostermek icin gereken saf hesaplar.
///
/// Cizgi indis sayisina gore degil, kat edilen mesafeye gore ilerler. Boylece
/// shape noktalarinin sikligi degisse bile animasyonun hizi tutarli kalir.
/// Duraklar da en yakin polyline parcasi uzerindeki konumlarinda gorunur.
class RouteMapAnimationPlan {
  final RouteShape route;
  final Map<String, double> _stopProgress;
  final List<double> _cumulativeLengths;
  final double _totalLength;

  RouteMapAnimationPlan._({
    required this.route,
    required Map<String, double> stopProgress,
    required List<double> cumulativeLengths,
    required double totalLength,
  }) : _stopProgress = stopProgress,
       _cumulativeLengths = cumulativeLengths,
       _totalLength = totalLength;

  factory RouteMapAnimationPlan({
    required RouteShape route,
    required List<RingStop> stops,
  }) {
    final points = route.points;
    if (points.length < 2) {
      return RouteMapAnimationPlan._(
        route: route,
        stopProgress: {for (final stop in stops) stop.id: 0},
        cumulativeLengths: points.isEmpty ? const [] : const [0],
        totalLength: 0,
      );
    }

    // Kampus olceginde equirectangular duzlem hem yeterince dogru hem de her
    // animasyon karesinde haversine hesaplamaktan daha hafiftir.
    final longitudeScale = _longitudeScale(points);
    final cumulative = <double>[0];
    for (var index = 0; index < points.length - 1; index++) {
      cumulative.add(
        cumulative.last +
            _distance(points[index], points[index + 1], longitudeScale),
      );
    }
    final totalLength = cumulative.last;

    return RouteMapAnimationPlan._(
      route: route,
      stopProgress: {
        for (final stop in stops)
          stop.id: _progressAlongRoute(
            stop,
            points,
            cumulative,
            totalLength,
            longitudeScale,
          ),
      },
      cumulativeLengths: cumulative,
      totalLength: totalLength,
    );
  }

  /// [progress] aninda cizilmis olan polyline on eki. Son nokta iki shape
  /// noktasi arasinda enterpole edilir; cizgi parcali atlamaz.
  List<RoutePoint> pointsAt(double progress) {
    final points = route.points;
    if (points.length < 2 || _totalLength == 0) return List.of(points);

    final value = progress.clamp(0.0, 1.0);
    if (value == 0) return [points.first];
    if (value == 1) return List.of(points);

    final targetLength = _totalLength * value;
    var segment = 0;
    while (segment < _cumulativeLengths.length - 2 &&
        _cumulativeLengths[segment + 1] < targetLength) {
      segment++;
    }

    final startLength = _cumulativeLengths[segment];
    final segmentLength =
        _cumulativeLengths[segment + 1] - _cumulativeLengths[segment];
    final fraction = segmentLength == 0
        ? 1.0
        : ((targetLength - startLength) / segmentLength).clamp(0.0, 1.0);
    final start = points[segment];
    final end = points[segment + 1];

    return [
      ...points.take(segment + 1),
      RoutePoint(
        start.lat + ((end.lat - start.lat) * fraction),
        start.lng + ((end.lng - start.lng) * fraction),
      ),
    ];
  }

  Set<String> visibleStopIdsAt(double progress) {
    final value = progress.clamp(0.0, 1.0);
    return {
      for (final entry in _stopProgress.entries)
        if (entry.value <= value) entry.key,
    };
  }

  static double _longitudeScale(List<RoutePoint> points) {
    final meanLatitude =
        points.fold<double>(0, (sum, point) => sum + point.lat) / points.length;
    return math.cos(meanLatitude * math.pi / 180);
  }

  static double _distance(
    RoutePoint start,
    RoutePoint end,
    double longitudeScale,
  ) {
    final x = (end.lng - start.lng) * longitudeScale;
    final y = end.lat - start.lat;
    return math.sqrt((x * x) + (y * y));
  }

  static double _progressAlongRoute(
    RingStop stop,
    List<RoutePoint> points,
    List<double> cumulative,
    double totalLength,
    double longitudeScale,
  ) {
    if (totalLength == 0) return 0;

    var closestSquaredDistance = double.infinity;
    var closestLength = 0.0;

    for (var index = 0; index < points.length - 1; index++) {
      final start = points[index];
      final end = points[index + 1];
      final segmentX = (end.lng - start.lng) * longitudeScale;
      final segmentY = end.lat - start.lat;
      final stopX = (stop.lng - start.lng) * longitudeScale;
      final stopY = stop.lat - start.lat;
      final segmentSquared = (segmentX * segmentX) + (segmentY * segmentY);
      final projection = segmentSquared == 0
          ? 0.0
          : ((stopX * segmentX) + (stopY * segmentY)) / segmentSquared;
      final fraction = projection.clamp(0.0, 1.0);
      final deltaX = stopX - (segmentX * fraction);
      final deltaY = stopY - (segmentY * fraction);
      final squaredDistance = (deltaX * deltaX) + (deltaY * deltaY);

      if (squaredDistance >= closestSquaredDistance) continue;
      closestSquaredDistance = squaredDistance;
      final segmentLength = cumulative[index + 1] - cumulative[index];
      closestLength = cumulative[index] + (segmentLength * fraction);
    }

    return (closestLength / totalLength).clamp(0.0, 1.0);
  }
}
