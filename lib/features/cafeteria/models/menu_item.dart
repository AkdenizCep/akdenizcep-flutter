class MenuItem {
  final String date;
  final String mealType;
  final List<String> items;

  MenuItem({required this.date, required this.mealType, required this.items});

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    date: json['date'] as String? ?? '',
    mealType: json['mealType'] as String? ?? '',
    items: List<String>.from(json['items'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'mealType': mealType,
    'items': items,
  };

  MenuItem copyWith({String? date, String? mealType, List<String>? items}) =>
      MenuItem(
        date: date ?? this.date,
        mealType: mealType ?? this.mealType,
        items: items ?? this.items,
      );
}
