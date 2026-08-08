class RingStop {
  final String id;
  final String name;
  final double lat;
  final double lng;

  RingStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory RingStop.fromJson(String id, Map<String, dynamic> json) => RingStop(
    id: id,
    name: json['name'] as String? ?? id,
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lng': lng};

  RingStop copyWith({String? id, String? name, double? lat, double? lng}) =>
      RingStop(
        id: id ?? this.id,
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}
