import 'package:shared_preferences/shared_preferences.dart';

import '../models/quick_action.dart';

/// Hızlı erişim seçiminin cihaz yerel kalıcılığı.
///
/// Kullanıcıya bağlı değil, cihaza bağlı — hesap değiştiğinde seçim kalır.
/// Cihazlar arası senkron gerekirse burası Firestore'a taşınır; arayüz yalnızca
/// [QuickActionsNotifier] üzerinden konuştuğu için değişiklik tek noktada olur.
class QuickActionsService {
  static const _key = 'home_quick_actions';

  /// Kayıtlı [QuickAction.name] listesi; hiç kayıt yoksa null.
  Future<List<String>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key);
  }

  Future<void> save(List<QuickAction> actions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, actions.map((a) => a.name).toList());
  }
}
