import 'package:akdenizcep/features/campus_photos/models/campus_photo.dart';
import 'package:akdenizcep/features/campus_photos/providers/campus_photo_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CampusPhoto _photo({List<String> likedBy = const []}) {
  return CampusPhoto(
    id: 'p1',
    authorUid: 'owner',
    authorName: 'Test',
    imageUrl: '',
    caption: '',
    likedBy: likedBy,
    createdAt: DateTime(2026, 8, 29),
  );
}

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('PhotoLikeNotifier', () {
    test('bekleyen değişiklik yokken gerçek veriye göre karar verir', () {
      final container = makeContainer();
      final notifier = container.read(photoLikeProvider.notifier);
      final photo = _photo(likedBy: ['owner']);

      expect(notifier.isLiked(photo, 'owner'), isTrue);
      expect(notifier.isLiked(photo, 'other'), isFalse);
      expect(notifier.likeCount(photo, 'owner'), 1);
    });

    test('bekleyen "beğen" değişikliği anında yansır ve sayaç +1 gösterir', () {
      final container = makeContainer();
      final photo = _photo(likedBy: const []);

      container.read(photoLikeProvider.notifier).state = {'p1': true};
      final notifier = container.read(photoLikeProvider.notifier);

      expect(notifier.isLiked(photo, 'me'), isTrue);
      expect(notifier.likeCount(photo, 'me'), 1);
    });

    test('bekleyen "geri al" değişikliği sayaç -1 gösterir', () {
      final container = makeContainer();
      final photo = _photo(likedBy: ['me']);

      container.read(photoLikeProvider.notifier).state = {'p1': false};
      final notifier = container.read(photoLikeProvider.notifier);

      expect(notifier.isLiked(photo, 'me'), isFalse);
      expect(notifier.likeCount(photo, 'me'), 0);
    });

    test('bekleyen değişiklik gerçek değerle aynıysa sayaç değişmez', () {
      final container = makeContainer();
      final photo = _photo(likedBy: ['me']);

      container.read(photoLikeProvider.notifier).state = {'p1': true};
      final notifier = container.read(photoLikeProvider.notifier);

      expect(notifier.likeCount(photo, 'me'), 1);
    });

    test('sayaç negatife düşmez', () {
      final container = makeContainer();
      final photo = _photo(likedBy: const []);

      container.read(photoLikeProvider.notifier).state = {'p1': false};
      final notifier = container.read(photoLikeProvider.notifier);

      expect(notifier.likeCount(photo, 'me'), 0);
    });
  });
}
