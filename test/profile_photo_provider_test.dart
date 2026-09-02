import 'dart:async';
import 'dart:typed_data';

import 'package:akdenizcep/features/auth/models/app_user.dart';
import 'package:akdenizcep/features/profile/providers/profile_provider.dart';
import 'package:akdenizcep/features/profile/services/profile_photo_service.dart';
import 'package:akdenizcep/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _testUser = AppUser(
  id: 'test-user-1',
  name: 'Test Öğrenci',
  email: 'ogrenci@ogr.akdeniz.edu.tr',
  studentId: '20210001',
  followedClubs: const [],
  createdAt: DateTime(2026, 1, 1),
);

class _FakeProfilePhotoService implements ProfilePhotoService {
  final uploadCompleter = Completer<String>();
  int uploadCalls = 0;
  int removeCalls = 0;

  @override
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List jpegBytes,
  }) {
    uploadCalls++;
    return uploadCompleter.future;
  }

  @override
  Future<void> removeProfilePhoto({required String uid}) async {
    removeCalls++;
  }
}

class _ThrowingProfilePhotoService implements ProfilePhotoService {
  @override
  Future<void> removeProfilePhoto({required String uid}) =>
      throw Exception('silinemedi');

  @override
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List jpegBytes,
  }) => throw UnimplementedError();
}

void main() {
  test('yükleme sürerken ikinci yükleme çağrısını yok sayar', () async {
    final service = _FakeProfilePhotoService();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(_testUser)),
        profilePhotoServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final controller = container.read(profilePhotoControllerProvider.notifier);

    final first = controller.upload(Uint8List.fromList([0xff, 0xd8, 0xff]));
    final second = controller.upload(Uint8List.fromList([0xff, 0xd8, 0xff]));

    expect(service.uploadCalls, 1);
    expect(container.read(profilePhotoControllerProvider).isLoading, isTrue);
    service.uploadCompleter.complete('https://cdn.example/avatar.jpg');
    await Future.wait([first, second]);
    expect(container.read(profilePhotoControllerProvider).hasValue, isTrue);
  });

  test('kaldırma hatasını işlem durumunda yayınlar', () async {
    final service = _ThrowingProfilePhotoService();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(_testUser)),
        profilePhotoServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final controller = container.read(profilePhotoControllerProvider.notifier);

    await expectLater(controller.remove(), throwsException);

    expect(container.read(profilePhotoControllerProvider).hasError, isTrue);
  });

  test('kullanıcı oturum açmamışsa yükleme hata fırlatır', () async {
    final service = _FakeProfilePhotoService();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
        profilePhotoServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(profilePhotoControllerProvider.notifier);

    await expectLater(
      controller.upload(Uint8List.fromList([0xff, 0xd8, 0xff])),
      throwsException,
    );
    expect(service.uploadCalls, 0);
  });
}
