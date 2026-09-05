import 'package:akdenizcep/features/ring/models/route_shape.dart';
import 'package:akdenizcep/features/ring/pages/components/route_map_animation_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

void main() {
  final route = RouteShape(
    id: 'AU102_0',
    shortName: 'AÜ102',
    directionId: 0,
    headsign: 'Başlangıç → Bitiş',
    label: 'AÜ102 · Bitiş yönü',
    color: '#1565C0',
    lengthKm: 3,
    bounds: const RouteBounds(south: 0, west: 0, north: 0, east: 3),
    // İkinci parça ilkinin iki katı: indis değil mesafe hesabını doğrular.
    points: const [RoutePoint(0, 0), RoutePoint(0, 1), RoutePoint(0, 3)],
  );

  test('cizgi gercek mesafeye gore gidis yonunde ilerler', () {
    final plan = RouteMapAnimationPlan(route: route, stops: const []);

    final halfway = plan.pointsAt(0.5);

    expect(halfway, hasLength(3));
    expect(halfway.first.lng, 0);
    expect(halfway[1].lng, 1);
    expect(halfway.last.lng, closeTo(1.5, 0.000001));
    expect(plan.pointsAt(1).last.lng, 3);
  });

  test('duraklar cizgi kendilerine ulastikca sirayla gorunur', () {
    final first = stop('first', lat: 0, lng: 0.5);
    final second = stop('second', lat: 0, lng: 2.5);
    final plan = RouteMapAnimationPlan(route: route, stops: [first, second]);

    expect(plan.visibleStopIdsAt(0.1), isEmpty);
    expect(plan.visibleStopIdsAt(0.2), {'first'});
    expect(plan.visibleStopIdsAt(0.9), {'first', 'second'});
  });
}
