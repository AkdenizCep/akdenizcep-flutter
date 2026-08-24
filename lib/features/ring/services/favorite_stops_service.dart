import 'package:shared_preferences/shared_preferences.dart';

/// Favori durak id'lerinin cihaz yerel kaliciligi.
///
/// Kullaniciya bagli degil, cihaza bagli — hesap degistiginde favoriler kalir.
/// Cihazlar arasi senkron gerekirse burasi Firestore'a tasinir; arayuz yalnizca
/// [FavoriteStopsNotifier] uzerinden konustugu icin degisiklik tek noktada olur.
class FavoriteStopsService {
  static const _key = 'ring_favorite_stops';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> save(Set<String> stopIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, stopIds.toList());
  }
}
