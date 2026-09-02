import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akdenizcep/features/auth/models/app_user.dart';
import 'package:akdenizcep/shared/components/attendee_avatars.dart';
import 'package:akdenizcep/shared/models/user_profile_summary.dart';
import 'package:akdenizcep/shared/providers/user_provider.dart';

void main() {
  testWidgets('katılımcı profil fotoğrafına sahipse CachedNetworkImage gösterir', (tester) async {
    const profile = UserProfileSummary(
      uid: 'user-1',
      name: 'Ahmet Yılmaz',
      photoUrl: 'https://res.cloudinary.com/example/avatar.jpg',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider('user-1').overrideWith((ref) => Future.value(profile)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AttendeeAvatars(attendeeIds: ['user-1']),
          ),
        ),
      ),
    );
    await tester.pump();

    final imageFinder = find.byType(CachedNetworkImage);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<CachedNetworkImage>(imageFinder);
    expect(imageWidget.imageUrl, 'https://res.cloudinary.com/example/avatar.jpg');
  });

  testWidgets('katılımcı fotoğrafı yoksa adının baş harfini fallback olarak gösterir', (tester) async {
    const profile = UserProfileSummary(
      uid: 'user-2',
      name: 'Mehmet Kaya',
      photoUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider('user-2').overrideWith((ref) => Future.value(profile)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AttendeeAvatars(attendeeIds: ['user-2']),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('oturum açmış kullanıcının profili currentUserProviderdan doğrudan alınır', (tester) async {
    final currentUser = AppUser(
      id: 'current-user-uid',
      name: 'Zeynep Demir',
      email: 'zeynep@ogr.akdeniz.edu.tr',
      studentId: '20220002',
      photoUrl: 'https://res.cloudinary.com/example/zeynep.jpg',
      followedClubs: const [],
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(currentUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AttendeeAvatars(attendeeIds: ['current-user-uid']),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final imageFinder = find.byType(CachedNetworkImage);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<CachedNetworkImage>(imageFinder);
    expect(imageWidget.imageUrl, 'https://res.cloudinary.com/example/zeynep.jpg');
  });
}
