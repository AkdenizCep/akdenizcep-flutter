/// Etkinlik oluşturma formundaki "kimin adına" seçeneği için kulüp özeti.
///
/// Kulübün tamamını (community feature'ının `Club` modeli) taşımaz; form yalnız
/// id ve ad ile çalışır.
class ClubOption {
  final String id;
  final String name;
  final String category;

  const ClubOption({required this.id, required this.name, this.category = ''});

  factory ClubOption.fromJson(Map<String, dynamic> json) => ClubOption(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
  };

  ClubOption copyWith({String? id, String? name, String? category}) =>
      ClubOption(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
      );
}
