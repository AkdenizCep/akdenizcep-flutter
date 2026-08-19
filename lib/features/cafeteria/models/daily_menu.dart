/// Bir gunun yemekhane menusu. Ogun ayrimi yoktur — universite gun basina
/// tek bir liste yayinlar.
class DailyMenu {
  /// "YYYY-MM-DD"
  final String date;
  final List<String> items;

  DailyMenu({required this.date, required this.items});

  bool get isEmpty => items.isEmpty;

  factory DailyMenu.fromJson(Map<String, dynamic> json) => DailyMenu(
    date: json['date'] as String? ?? '',
    items: List<String>.from(json['items'] ?? []),
  );

  /// `cafeteria_menu/{date}` dugumunu duz bir listeye cevirir.
  ///
  /// Uc bicimi de kaldirir:
  /// - gercek dizi: `["Corba", "Pilav"]`
  /// - RTDB'nin seyrek diziyi cevirdigi sayisal anahtarli map: `{"0": ...}`
  /// - ogun ayrimi kaldirilmadan onceki bicim: `{"lunch": [...], "dinner": [...]}`
  ///
  /// Son bicimde **yalnizca ilk ogun** okunur (kahvalti < ogle < aksam).
  /// Ikisini birlestirmek gunun menusunu iki katina cikarip yaniltici oluyordu;
  /// tek gun tek liste kuralini bozmamak icin gerisi yok sayilir. Bu, veri duz
  /// diziye tasinana kadar gecerli bir ara cozumdur.
  factory DailyMenu.fromRtdb(String date, Object? value) =>
      DailyMenu(date: date, items: _readItems(value));

  static List<String> _readItems(Object? value) {
    if (value == null) return const [];

    if (value is List) {
      return value.whereType<Object>().map((e) => '$e').toList();
    }

    if (value is Map) {
      if (value.isEmpty) return const [];
      final entries = value.entries.toList();

      final isIndexed = entries.every((e) => int.tryParse('${e.key}') != null);
      if (isIndexed) {
        entries.sort(
          (a, b) => int.parse('${a.key}').compareTo(int.parse('${b.key}')),
        );
        return entries.map((e) => '${e.value}').toList();
      }

      entries.sort(
        (a, b) => _legacyOrder('${a.key}').compareTo(_legacyOrder('${b.key}')),
      );
      return _readItems(entries.first.value);
    }

    return ['$value'];
  }

  static const _legacyMealKeys = [
    'breakfast',
    'kahvalti',
    'lunch',
    'ogle',
    'dinner',
    'aksam',
  ];

  static int _legacyOrder(String key) {
    final index = _legacyMealKeys.indexOf(key.toLowerCase());
    return index == -1 ? _legacyMealKeys.length : index;
  }

  Map<String, dynamic> toJson() => {'date': date, 'items': items};

  DailyMenu copyWith({String? date, List<String>? items}) =>
      DailyMenu(date: date ?? this.date, items: items ?? this.items);
}

/// Bir menu satirinin ayristirilmis hali. Universite kalori bilgisini
/// "Tavuk Sote - 450 kcal" bicimindeki bir sonekle giriyor; girmediginde
/// [calories] `null` olur.
class MenuEntry {
  final String name;
  final int? calories;

  const MenuEntry({required this.name, this.calories});

  static final _caloriePattern = RegExp(
    r'^(.*?)\s*-\s*(\d+)\s*kcal$',
    caseSensitive: false,
  );

  factory MenuEntry.parse(String raw) {
    final trimmed = raw.trim();
    final match = _caloriePattern.firstMatch(trimmed);
    if (match == null) return MenuEntry(name: trimmed);

    return MenuEntry(
      name: match.group(1)!.trim(),
      calories: int.parse(match.group(2)!),
    );
  }

  /// Kalori girilmis satirlarin toplami. Hicbiri girilmemisse `null`.
  static int? totalCalories(List<MenuEntry> entries) {
    final known = entries.where((e) => e.calories != null);
    if (known.isEmpty) return null;
    return known.fold(0, (sum, e) => sum! + e.calories!);
  }
}
