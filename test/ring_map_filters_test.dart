import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

void main() {
  test('hat ve yon cizgiyi, pinleri ve kartlari birlikte filtreler', () async {
    final outboundFirst = stop(
      'gidis_1',
      servedBy: [service('AÜ102', sequence: 1)],
    );
    final outboundSecond = stop(
      'gidis_2',
      servedBy: [service('AÜ102', sequence: 2)],
    );
    final inbound = stop(
      'donus_1',
      servedBy: [service('AÜ102', isReturn: true, sequence: 1)],
    );

    final container = ProviderContainer(
      overrides: [
        nearbyStopsProvider.overrideWith(
          (ref) => [
            NearbyStop(
              stop: outboundSecond,
              distanceMeters: null,
              schedules: const [],
            ),
            NearbyStop(
              stop: inbound,
              distanceMeters: null,
              schedules: const [],
            ),
            NearbyStop(
              stop: outboundFirst,
              distanceMeters: null,
              schedules: const [],
            ),
          ],
        ),
        routeShapesProvider.overrideWith((ref) => routeBundle()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(routeShapesProvider.future);
    container.read(selectedRouteLineProvider.notifier).state = 'AÜ102';
    container.read(selectedRouteDirectionProvider.notifier).state = 0;

    expect(
      container.read(visibleRouteShapesProvider).map((route) => route.id),
      ['AU102_0'],
    );
    expect(
      container.read(visibleStopsProvider).map((nearby) => nearby.stop.id),
      ['gidis_1', 'gidis_2'],
    );

    container.read(selectedRouteDirectionProvider.notifier).state = 1;

    expect(
      container.read(visibleRouteShapesProvider).map((route) => route.id),
      ['AU102_1'],
    );
    expect(
      container.read(visibleStopsProvider).map((nearby) => nearby.stop.id),
      ['donus_1'],
    );
  });

  test('konum varken guzergahtan once yakinlik sirasi korunur', () async {
    final routeFirst = stop('uzak', servedBy: [service('AÜ103', sequence: 1)]);
    final routeSecond = stop(
      'yakin',
      servedBy: [service('AÜ103', sequence: 2)],
    );
    final container = ProviderContainer(
      overrides: [
        nearbyStopsProvider.overrideWith(
          (ref) => [
            NearbyStop(
              stop: routeSecond,
              distanceMeters: 100,
              schedules: const [],
            ),
            NearbyStop(
              stop: routeFirst,
              distanceMeters: 500,
              schedules: const [],
            ),
          ],
        ),
        routeShapesProvider.overrideWith((ref) => routeBundle()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(routeShapesProvider.future);
    container.read(selectedRouteLineProvider.notifier).state = 'AÜ103';
    container.read(selectedRouteDirectionProvider.notifier).state = 0;

    expect(
      container.read(visibleStopsProvider).map((nearby) => nearby.stop.id),
      ['yakin', 'uzak'],
    );
  });
}
