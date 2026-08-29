import 'package:akdenizcep/features/lost_found/models/lost_found_item.dart';
import 'package:akdenizcep/features/lost_found/providers/lost_found_provider.dart';
import 'package:akdenizcep/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

LostFoundItem _item({
  required String id,
  required String authorUid,
  String type = 'kayip',
  bool isResolved = false,
}) {
  return LostFoundItem(
    id: id,
    authorUid: authorUid,
    authorName: 'Test',
    type: type,
    title: 'Eşya $id',
    description: '',
    category: 'diger',
    imageUrl: '',
    location: 'Kampüs',
    contactPhone: '',
    isResolved: isResolved,
    createdAt: DateTime(2026, 8, 29),
  );
}

void main() {
  final items = [
    _item(id: '1', authorUid: 'me'), // benim, kayip, acik
    _item(id: '2', authorUid: 'me', isResolved: true), // benim, kayip, cozulmus
    _item(id: '3', authorUid: 'other', type: 'bulundu'), // baskasinin, bulundu, acik
    _item(id: '4', authorUid: 'other', isResolved: true), // baskasinin, kayip, cozulmus
  ];

  ProviderContainer makeContainer({required bool myListingsOnly}) {
    final container = ProviderContainer(
      overrides: [
        lostFoundItemsProvider.overrideWith((ref) => Stream.value(items)),
        currentUserProvider.overrideWith(
          (ref) => Stream.value(null),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('genel gezinme modunda çözülmüş ilanlar gizlenir', () async {
    final container = makeContainer(myListingsOnly: false);
    // StreamProvider ilk degerini asenkron yayar; okumadan once bekleniyor.
    await container.read(lostFoundItemsProvider.future);

    final result = container.read(filteredLostFoundItemsProvider);

    expect(result.map((e) => e.id), containsAll(['1', '3']));
    expect(result.map((e) => e.id), isNot(contains('2')));
    expect(result.map((e) => e.id), isNot(contains('4')));
  });

  test('tip filtresi genel modda uygulanmaya devam eder', () async {
    final container = makeContainer(myListingsOnly: false);
    await container.read(lostFoundItemsProvider.future);
    container.read(lostFoundTypeFilterProvider.notifier).state =
        LostFoundTypeFilter.found;

    final result = container.read(filteredLostFoundItemsProvider);
    expect(result.map((e) => e.id).toList(), ['3']);
  });

  test('oturum yokken "İlanlarım" boş liste döner, çökmez', () async {
    final container = makeContainer(myListingsOnly: true);
    await container.read(lostFoundItemsProvider.future);
    container.read(showMyListingsOnlyProvider.notifier).state = true;

    expect(container.read(filteredLostFoundItemsProvider), isEmpty);
  });
}
