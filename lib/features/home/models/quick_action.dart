/// Ana sayfadaki "Hızlı Erişim" ızgarasına konabilecek kısayollar.
///
/// Enum sırası katalog sırasıdır: ilk [kQuickActionSlotCount] öğe varsayılan
/// ızgaradır. Kalıcılıkta `name` yazıldığı için bir öğeyi yeniden adlandırmak
/// kayıtlı seçimleri sessizce düşürür; [normalizeQuickActions] bu durumu
/// varsayılanlarla tamamlayarak karşılar.
enum QuickAction {
  obs('OBS', 'Öğrenci Bilgi Sistemi'),
  campusCard('TL Yükleme', 'Kampüs kart bakiye işlemleri'),
  academicCalendar('Akademik Takvim', 'Kayıt, sınav ve tatil tarihleri'),
  campusSecurity('Acil Güvenlik', 'Güvenliği hemen ara'),
  chatbot('Chatbot', 'Akdeniz Üniversitesi asistanı'),
  mediko('Mediko', 'Sağlık merkezi randevusu'),
  campusMap('Kampüs Haritası', 'Binalar, kapılar ve önemli noktalar'),
  lostFound('Kayıp & Buluntu', 'İlanları incele veya yeni ilan oluştur'),
  campusPhotos('Kampüs Fotoğrafları', 'Kampüsten paylaşılan kareler'),
  emergencyContacts('Numaralar', 'Güvenlik birimleri ve nöbet noktaları');

  /// Izgara kartında ve düzenleme listesinde görünen ad.
  final String title;

  /// Düzenleme listesinde başlığın altında görünen açıklama.
  final String description;

  const QuickAction(this.title, this.description);

  /// Kalıcı kayıttaki [name] değerinden öğeyi bulur; bilinmeyen id için null.
  static QuickAction? fromId(String id) {
    for (final action in values) {
      if (action.name == id) return action;
    }
    return null;
  }
}

/// Izgaradaki sabit kısayol sayısı (3 sütun x 2 satır).
const kQuickActionSlotCount = 6;

/// Hiç seçim yapılmamış kullanıcının gördüğü ızgara.
const List<QuickAction> kDefaultQuickActions = [
  QuickAction.obs,
  QuickAction.campusCard,
  QuickAction.academicCalendar,
  QuickAction.campusSecurity,
  QuickAction.chatbot,
  QuickAction.mediko,
];

/// Kayıtlı id listesini her zaman tam [kQuickActionSlotCount] öğelik, tekrarsız
/// bir ızgaraya çevirir.
///
/// Bilinmeyen id'ler ve tekrarlar atılır, fazlası kesilir, eksik kalan yerler
/// [kDefaultQuickActions] sırasıyla (zaten seçili olanlar atlanarak) doldurulur.
List<QuickAction> normalizeQuickActions(List<String>? storedIds) {
  final result = <QuickAction>[];

  for (final id in storedIds ?? const <String>[]) {
    final action = QuickAction.fromId(id);
    if (action == null || result.contains(action)) continue;
    result.add(action);
    if (result.length == kQuickActionSlotCount) return result;
  }

  for (final action in kDefaultQuickActions) {
    if (result.length == kQuickActionSlotCount) break;
    if (!result.contains(action)) result.add(action);
  }
  return result;
}
