import 'package:geolocator/geolocator.dart';

/// Konum erisimi. Izin akisini cagiran katmana birakmaz; tek bir
/// [requestPosition] cagrisi izin durumunu kontrol eder, gerekiyorsa ister ve
/// alinamadiginda `null` doner. Boylece cagiran taraf hicbir zaman istisna
/// yakalamak zorunda kalmaz.
class LocationService {
  /// Izin daha once verilmisse konumu doner, verilmemisse `null` doner.
  /// Kullaniciya izin diyalogu **gostermez** — sayfa acilisinda guvenle
  /// cagrilabilir.
  Future<Position?> getPositionIfPermitted() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return null;
    }

    return _readPosition();
  }

  /// Gerekiyorsa izin diyalogunu gosterir. Kullanici reddederse veya konum
  /// servisi kapaliysa `null` doner.
  Future<Position?> requestPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return null;
    }

    return _readPosition();
  }

  /// Kullanici izni kalici olarak reddettiyse `true` doner — bu durumda
  /// yeniden izin istemek islevsizdir, ayarlara yonlendirmek gerekir.
  Future<bool> isPermanentlyDenied() async {
    return await Geolocator.checkPermission() ==
        LocationPermission.deniedForever;
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  /// Iki nokta arasindaki mesafeyi metre cinsinden doner.
  double distanceInMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  }

  Future<Position?> _readPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      // Zaman asimi veya donanim hatasi — son bilinen konuma dus.
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }
}
