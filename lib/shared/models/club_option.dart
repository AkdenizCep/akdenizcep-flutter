/// Etkinlik oluşturma formundaki "kimin adına" seçeneği için kulüp özeti.
///
/// Kulübün tamamını (community feature'ının `Club` modeli) taşımaz; form yalnız
/// id ve ad ile çalışır.
class ClubOption {
  final String id;
  final String name;

  const ClubOption({required this.id, required this.name});

  factory ClubOption.fromJson(Map<String, dynamic> json) => ClubOption(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  ClubOption copyWith({String? id, String? name}) =>
      ClubOption(id: id ?? this.id, name: name ?? this.name);
}
