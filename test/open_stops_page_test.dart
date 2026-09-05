import 'package:akdenizcep/features/ring/pages/components/open_stops_page.dart';
import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:akdenizcep/shared/providers/location_provider.dart';
import 'package:akdenizcep/shared/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'support/ring_fixtures.dart';

class _UnavailableLocationService extends LocationService {
  @override
  Future<Position?> getPositionIfPermitted() async => null;

  @override
  Future<Position?> requestPosition() async => null;
}

void main() {
  testWidgets('secilen duragi gorunur yapip rota parametresiyle acar', (
    tester,
  ) async {
    final target = stop(
      'durak_103',
      name: 'SU ÜRÜNLERİ',
      servedBy: [service('AÜ103')],
    );
    final container = ProviderContainer(
      overrides: [
        ringStopsProvider.overrideWith((ref) => [target]),
        routeShapesProvider.overrideWith((ref) => routeBundle()),
        locationServiceProvider.overrideWith(
          (ref) => _UnavailableLocationService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Consumer(
            builder: (context, ref, child) => ElevatedButton(
              onPressed: () =>
                  openStopsPage(context, ref, focusStopId: target.id),
              child: const Text('Aç'),
            ),
          ),
        ),
        GoRoute(
          path: '/ring/stops',
          builder: (context, state) => Scaffold(
            body: Text('durak=${state.uri.queryParameters['stop']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    container.read(stopQueryProvider.notifier).state = 'eski arama';
    container.read(selectedRouteLineProvider.notifier).state = 'AÜ102';
    container.read(selectedRouteDirectionProvider.notifier).state = 1;

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    expect(find.text('durak=durak_103'), findsOneWidget);
    expect(container.read(stopQueryProvider), isEmpty);
    expect(container.read(selectedStopProvider), target.id);
    expect(container.read(selectedRouteLineProvider), 'AÜ103');
    expect(container.read(selectedRouteDirectionProvider), 0);
  });
}
