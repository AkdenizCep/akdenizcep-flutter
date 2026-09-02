import 'package:akdenizcep/features/auth/models/app_user.dart';
import 'package:akdenizcep/features/profile/pages/components/profile_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  testWidgets('profil kartındaki fotoğrafa tıklandığında düzenleme akışını açar', (
    tester,
  ) async {
    var tapped = false;
    final user = AppUser(
      id: 'student-1',
      name: 'Ayşe Deniz',
      email: 'ayse@ogr.akdeniz.edu.tr',
      studentId: '20260001',
      followedClubs: const [],
      createdAt: DateTime(2026, 9, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileInfoCard(
            user: user,
            photoBusy: false,
            onPhotoTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Profil fotoğrafını değiştir'));
    expect(tapped, isTrue);
  });
}
