import 'package:akdenizcep/features/ring/pages/components/route_map_filters.dart';
import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

void main() {
  testWidgets('hat ve hedefiyle birlikte gidis donus secilir', (tester) async {
    var filterChangeCount = 0;
    final container = ProviderContainer(
      overrides: [routeShapesProvider.overrideWith((ref) => routeBundle())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: RouteMapFilters(
                onFilterChanged: () => filterChangeCount++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AÜ102'), findsOneWidget);
    expect(find.text('AÜ103'), findsOneWidget);
    expect(find.text('Gidiş yönü'), findsOneWidget);
    expect(find.text('Meltem Kapısı'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    final lineTarget = find.ancestor(
      of: find.text('AÜ102'),
      matching: find.byType(InkWell),
    );
    final directionTarget = find.ancestor(
      of: find.text('Meltem Kapısı'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(lineTarget).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(directionTarget).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Meltem Kapısı'));
    await tester.pumpAndSettle();

    expect(container.read(selectedRouteDirectionProvider), 1);
    expect(find.text('Dönüş yönü'), findsOneWidget);
    expect(find.text('Adli Tıp'), findsOneWidget);
    expect(filterChangeCount, 1);
  });
}
