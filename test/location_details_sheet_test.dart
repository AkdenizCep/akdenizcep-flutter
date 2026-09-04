import 'package:akdenizcep/features/map/models/campus_location.dart';
import 'package:akdenizcep/features/map/pages/components/location_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detay paneli navbar paddinginden etkilenmeden alta sabitlenir', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    const location = CampusLocation(
      id: 'fine-arts',
      name: 'Güzel Sanatlar Fakültesi',
      latitude: 36.8969,
      longitude: 30.6512,
      category: LocationCategory.faculty,
      description: 'Sanat ve tasarım eğitimi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 120),
            viewPadding: EdgeInsets.only(bottom: 20),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LocationDetailsSheet(
                  location: location,
                  onClose: _noop,
                  onShowOnMap: _noop,
                  onGetDirections: _noop,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surface = find.byKey(
      const ValueKey('location-details-sheet-surface'),
    );
    expect(surface, findsOneWidget);
    expect(tester.getBottomRight(surface).dy, 844);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
