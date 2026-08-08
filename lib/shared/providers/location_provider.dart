import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

final locationServiceProvider = Provider((_) => LocationService());

/// Kullanicinin konumu. `null` = konum yok (izin verilmemis, servis kapali
/// veya henuz istenmemis). Bu durumda cagiran arayuz mesafesiz calisir.
class UserLocationNotifier extends StateNotifier<Position?> {
  final LocationService _service;

  UserLocationNotifier(this._service) : super(null);

  /// Izin daha once verilmisse konumu sessizce yukler.
  /// Izin diyalogu **gostermez** — sayfa acilisinda guvenle cagrilir.
  Future<void> loadIfPermitted() async {
    final position = await _service.getPositionIfPermitted();
    if (position != null && mounted) state = position;
  }

  /// Gerekiyorsa izin diyalogunu gosterir. Konum alinabildiyse `true` doner.
  Future<bool> request() async {
    final position = await _service.requestPosition();
    if (position == null) return false;
    if (mounted) state = position;
    return true;
  }

  Future<bool> isPermanentlyDenied() => _service.isPermanentlyDenied();

  Future<void> openSettings() => _service.openSettings();
}

final userPositionProvider =
    StateNotifierProvider<UserLocationNotifier, Position?>((ref) {
      return UserLocationNotifier(ref.watch(locationServiceProvider))
        ..loadIfPermitted();
    });
