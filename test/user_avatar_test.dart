import 'package:akdenizcep/shared/components/user_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fotoğraf yoksa kullanıcı baş harfini gösterir', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UserAvatar(name: 'Ayşe Deniz', imageUrl: '', diameter: 76),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('fotoğraf adresi varsa ağ görseli kullanır', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UserAvatar(
            name: 'Ayşe Deniz',
            imageUrl: 'https://example.com/avatar.jpg',
            diameter: 76,
          ),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });
}
