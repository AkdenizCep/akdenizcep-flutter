import 'package:flutter/material.dart';

/// Etkinlik kategorileri — hem kulüp hem öğrenci etkinlikleri için ortak katalog.
///
/// Renkler marka renkleri gibi davranır: tema değişse de sabit kalırlar, çünkü
/// kategori kimliğini taşırlar. Zeminler her zaman `colorScheme` üzerinden gelir.
class EventCategory {
  /// Firestore'daki `category` alanına yazılan değer.
  final String id;
  final String label;
  final Color color;
  final IconData icon;

  const EventCategory({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
  });

  static const all = EventCategory(
    id: 'hepsi',
    label: 'Hepsi',
    color: Color(0xFF135BEC),
    icon: Icons.apps_rounded,
  );

  static const technology = EventCategory(
    id: 'teknoloji',
    label: 'Teknoloji',
    color: Color(0xFF135BEC),
    icon: Icons.memory_rounded,
  );

  static const sports = EventCategory(
    id: 'spor',
    label: 'Spor',
    color: Color(0xFF168A5B),
    icon: Icons.sports_soccer_rounded,
  );

  static const art = EventCategory(
    id: 'sanat',
    label: 'Sanat',
    color: Color(0xFFE8601C),
    icon: Icons.photo_camera_rounded,
  );

  static const music = EventCategory(
    id: 'muzik',
    label: 'Müzik',
    color: Color(0xFF7B3FF2),
    icon: Icons.music_note_rounded,
  );

  static const academic = EventCategory(
    id: 'akademik',
    label: 'Akademik',
    color: Color(0xFF0F7B8A),
    icon: Icons.menu_book_rounded,
  );

  static const social = EventCategory(
    id: 'sosyal',
    label: 'Sosyal',
    color: Color(0xFF135BEC),
    icon: Icons.groups_2_rounded,
  );

  /// 2a kategori şeridinin sırası — "Hepsi" başta.
  static const stripItems = <EventCategory>[
    all,
    technology,
    sports,
    art,
    music,
    academic,
  ];

  /// 1f formunda seçilebilen kategoriler — "Hepsi" bir kategori değil, filtredir.
  static const selectableItems = <EventCategory>[
    technology,
    sports,
    art,
    music,
    academic,
    social,
  ];

  /// `category` alanı doluysa onu çözer; boşsa [fallbackText] içinden anahtar
  /// kelimeyle tahmin eder. Tahmin, `category` alanı eklenmeden önce yazılmış
  /// eski dokümanların da renkli görünmesini sağlar.
  static EventCategory resolve(String? category, {String fallbackText = ''}) {
    final id = category?.trim().toLowerCase() ?? '';
    if (id.isNotEmpty) {
      for (final item in selectableItems) {
        if (item.id == id || item.label.toLowerCase() == id) return item;
      }
    }

    return _guessFromText(fallbackText.toLowerCase());
  }

  static EventCategory _guessFromText(String text) {
    if (_containsAny(text, const ['spor', 'turnuva', 'koşu', 'futbol'])) {
      return sports;
    }
    if (_containsAny(text, const ['fotoğraf', 'çekim', 'sanat', 'sergi'])) {
      return art;
    }
    if (_containsAny(text, const ['teknoloji', 'yazılım', 'yapay zeka', 'ai'])) {
      return technology;
    }
    if (_containsAny(text, const ['müzik', 'konser', 'sahne'])) {
      return music;
    }
    if (_containsAny(text, const ['seminer', 'konferans', 'ders', 'akademik'])) {
      return academic;
    }

    return social;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}
