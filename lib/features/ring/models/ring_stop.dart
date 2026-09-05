import 'route_shape.dart' show RouteBounds;
import 'turkish_text.dart';

/// Bir duragin bir hat/yone verdigi hizmet — `servedBy` elemani.
///
/// "Bu duraktan hangi hatlar geciyor" sorusunun cevabi artik hesaplanmiyor,
/// veride duruyor.
class StopService {
  /// "AU102_0" — `au_hatlar.json` icindeki guzergahla eslesir.
  final String routeShapeId;

  /// "AÜ102".
  final String shortName;

  /// 0 = gidis. Bkz. `route_key.dart`.
  final int directionId;

  /// Duragin bu guzergahtaki sirasi (1'den baslar).
  ///
  /// Bazi guzergahlarda 2'den basliyor: hattin gercek kalkis duragi kampus
  /// disinda kaldigi icin bu veri setinde yok.
  final int stopSequence;

  /// "#RRGGBB".
  final String color;

  /// "AÜ102 · Meltem Kapısı yönü".
  final String label;

  const StopService({
    required this.routeShapeId,
    required this.shortName,
    required this.directionId,
    required this.stopSequence,
    required this.color,
    required this.label,
  });

  factory StopService.fromJson(Map<String, dynamic> json) => StopService(
    routeShapeId: json['routeShapeId'] as String,
    shortName: json['shortName'] as String,
    directionId: (json['directionId'] as num?)?.toInt() ?? 0,
    stopSequence: (json['stopSequence'] as num?)?.toInt() ?? 0,
    color: json['color'] as String? ?? '#1565C0',
    label: json['label'] as String? ?? json['shortName'] as String,
  );

  Map<String, dynamic> toJson() => {
    'routeShapeId': routeShapeId,
    'shortName': shortName,
    'directionId': directionId,
    'stopSequence': stopSequence,
    'color': color,
    'label': label,
  };

  StopService copyWith({
    String? routeShapeId,
    String? shortName,
    int? directionId,
    int? stopSequence,
    String? color,
    String? label,
  }) => StopService(
    routeShapeId: routeShapeId ?? this.routeShapeId,
    shortName: shortName ?? this.shortName,
    directionId: directionId ?? this.directionId,
    stopSequence: stopSequence ?? this.stopSequence,
    color: color ?? this.color,
    label: label ?? this.label,
  );
}

/// Bir ring duragi. Saf Dart — Flutter veya Firebase bilmez.
///
/// Kaynak `assets/routes/au_duraklar.json`; veri GTFS'ten turetilmis ve
/// fiziksel konuma gore tekillestirilmis. Yolun iki yakasindaki duraklar ayri
/// kayitlardir ([side] ile ayrilir) — kullanici dogru tarafta beklemeli.
class RingStop {
  /// GTFS `stopId`. Favoriler ve secili durak bunu kullanir.
  final String id;

  /// Veride yazdigi hali: "AKDENİZ ÜNİVERSİTESİ MERKEZİ YEMEKHANE".
  final String rawName;

  /// Arayuzde gosterilen ad: "Merkezi Yemekhane".
  final String name;

  /// Ayni adin kacinci kaydi ("EDEBİYAT FAKÜLTESİ-1" -> 1). Tek kayitsa `null`.
  final int? side;

  final double lat;
  final double lng;

  /// Birden fazla hat geciyorsa `true`.
  final bool isTransfer;

  final List<StopService> servedBy;

  const RingStop({
    required this.id,
    required this.rawName,
    required this.name,
    required this.side,
    required this.lat,
    required this.lng,
    required this.isTransfer,
    required this.servedBy,
  });

  factory RingStop.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? json['stopId'] as String;
    final parsed = parseStopName(rawName);

    return RingStop(
      id: json['stopId'] as String,
      rawName: rawName,
      // Veride elle duzeltilmis bir ad varsa algoritmanin onune gecer.
      name: json['displayName'] as String? ?? parsed.name,
      side: parsed.side,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lon'] as num? ?? json['lng'] as num).toDouble(),
      isTransfer: json['isTransfer'] as bool? ?? false,
      servedBy: [
        for (final service in (json['servedBy'] as List<dynamic>? ?? const []))
          StopService.fromJson(service as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'stopId': id,
    'name': rawName,
    'displayName': name,
    'lat': lat,
    'lon': lng,
    'isTransfer': isTransfer,
    'servedBy': [for (final service in servedBy) service.toJson()],
  };

  /// Bu duraktan gecen hat kodlari, tekil ve sirali: ["AÜ102", "AÜ103"].
  List<String> get lineNames {
    final names = servedBy.map((s) => s.shortName).toSet().toList()..sort();
    return names;
  }

  bool servesLine(String shortName) =>
      servedBy.any((s) => s.shortName == shortName);

  /// Durak belirtilen hattin belirtilen yonunde kullaniliyor mu?
  bool servesRoute(String shortName, int directionId) => servedBy.any(
    (service) =>
        service.shortName == shortName && service.directionId == directionId,
  );

  /// Belirtilen hat + yondeki durak sirasi. O guzergahta degilse `null`.
  int? routeSequenceFor(String shortName, int directionId) {
    final matches = servedBy.where(
      (service) =>
          service.shortName == shortName && service.directionId == directionId,
    );
    if (matches.isEmpty) return null;
    return matches
        .map((service) => service.stopSequence)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Guzergah sirasi — konum bilinmiyorken siralama icin.
  /// Birden fazla hatta geciyorsa en kucugu alinir.
  int get routeOrder {
    if (servedBy.isEmpty) return 1 << 20;
    return servedBy.map((s) => s.stopSequence).reduce((a, b) => a < b ? a : b);
  }

  RingStop copyWith({
    String? id,
    String? rawName,
    String? name,
    int? side,
    double? lat,
    double? lng,
    bool? isTransfer,
    List<StopService>? servedBy,
  }) => RingStop(
    id: id ?? this.id,
    rawName: rawName ?? this.rawName,
    name: name ?? this.name,
    side: side ?? this.side,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    isTransfer: isTransfer ?? this.isTransfer,
    servedBy: servedBy ?? this.servedBy,
  );
}

/// `assets/routes/au_duraklar.json` dosyasinin tamami.
class RingStopBundle {
  final int schemaVersion;
  final RouteBounds bounds;
  final List<RingStop> stops;

  const RingStopBundle({
    required this.schemaVersion,
    required this.bounds,
    required this.stops,
  });

  static const empty = RingStopBundle(
    schemaVersion: 0,
    bounds: RouteBounds(south: 0, west: 0, north: 0, east: 0),
    stops: [],
  );

  factory RingStopBundle.fromJson(Map<String, dynamic> json) => RingStopBundle(
    schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    bounds: RouteBounds.fromJson(json['bounds'] as Map<String, dynamic>),
    stops: [
      for (final stop in (json['stops'] as List<dynamic>? ?? const []))
        RingStop.fromJson(stop as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'bounds': bounds.toJson(),
    'stops': [for (final stop in stops) stop.toJson()],
  };
}
