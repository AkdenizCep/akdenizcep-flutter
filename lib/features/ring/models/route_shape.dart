/// Bir hattin tek yonunun harita uzerindeki cizgi geometrisi.
///
/// Saf Dart — `LatLng` veya `Color` gibi Flutter tipleri **kullanilmaz**;
/// donusum sunum katmaninda yapilir. Boylece model Firebase'siz ve haritasiz
/// test edilebilir kalir.
///
/// Veri GTFS `shapes.txt`'ten uretilmistir ve **yola oturtulmus degildir**;
/// ardisik noktalar arasi mesafe yer yer yuzlerce metreye cikar, cizgi bazi
/// virajlarda yolu keser. Bu beklenen bir durumdur.
class RoutePoint {
  final double lat;
  final double lng;

  const RoutePoint(this.lat, this.lng);

  /// Veride sira **[enlem, boylam]** — GeoJSON'un `[lon, lat]` sirasi degil.
  factory RoutePoint.fromJson(List<dynamic> json) =>
      RoutePoint((json[0] as num).toDouble(), (json[1] as num).toDouble());

  List<double> toJson() => [lat, lng];

  RoutePoint copyWith({double? lat, double? lng}) =>
      RoutePoint(lat ?? this.lat, lng ?? this.lng);
}

class RouteBounds {
  final double south;
  final double west;
  final double north;
  final double east;

  const RouteBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  factory RouteBounds.fromJson(Map<String, dynamic> json) => RouteBounds(
    south: (json['south'] as num).toDouble(),
    west: (json['west'] as num).toDouble(),
    north: (json['north'] as num).toDouble(),
    east: (json['east'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'south': south,
    'west': west,
    'north': north,
    'east': east,
  };

  RouteBounds copyWith({
    double? south,
    double? west,
    double? north,
    double? east,
  }) => RouteBounds(
    south: south ?? this.south,
    west: west ?? this.west,
    north: north ?? this.north,
    east: east ?? this.east,
  );
}

class RouteShape {
  /// Benzersiz — `PolylineId` olarak kullanilir. Ornek: "AU102_0".
  final String id;

  /// Kullaniciya gosterilen hat kodu. Ornek: "AÜ102".
  final String shortName;

  /// 0 = gidis, 1 = donus.
  final int directionId;

  /// "ADLİ TIP → MELTEM KAPISI".
  final String headsign;

  /// "AÜ102 · Meltem Kapısı yönü".
  final String label;

  /// "#RRGGBB".
  final String color;

  final double lengthKm;
  final RouteBounds bounds;
  final List<RoutePoint> points;

  const RouteShape({
    required this.id,
    required this.shortName,
    required this.directionId,
    required this.headsign,
    required this.label,
    required this.color,
    required this.lengthKm,
    required this.bounds,
    required this.points,
  });

  factory RouteShape.fromJson(Map<String, dynamic> json) => RouteShape(
    id: json['id'] as String,
    shortName: json['shortName'] as String,
    directionId: (json['directionId'] as num?)?.toInt() ?? 0,
    headsign: json['headsign'] as String? ?? '',
    label: json['label'] as String? ?? json['shortName'] as String,
    color: json['color'] as String? ?? '#1565C0',
    lengthKm: (json['lengthKm'] as num?)?.toDouble() ?? 0,
    bounds: RouteBounds.fromJson(json['bounds'] as Map<String, dynamic>),
    points: [
      for (final point in (json['points'] as List<dynamic>? ?? const []))
        RoutePoint.fromJson(point as List<dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'shortName': shortName,
    'directionId': directionId,
    'headsign': headsign,
    'label': label,
    'color': color,
    'lengthKm': lengthKm,
    'bounds': bounds.toJson(),
    'points': [for (final point in points) point.toJson()],
  };

  RouteShape copyWith({
    String? id,
    String? shortName,
    int? directionId,
    String? headsign,
    String? label,
    String? color,
    double? lengthKm,
    RouteBounds? bounds,
    List<RoutePoint>? points,
  }) => RouteShape(
    id: id ?? this.id,
    shortName: shortName ?? this.shortName,
    directionId: directionId ?? this.directionId,
    headsign: headsign ?? this.headsign,
    label: label ?? this.label,
    color: color ?? this.color,
    lengthKm: lengthKm ?? this.lengthKm,
    bounds: bounds ?? this.bounds,
    points: points ?? this.points,
  );
}

/// `assets/routes/au_hatlar.json` dosyasinin tamami.
class RouteShapeBundle {
  final int schemaVersion;

  /// Tum guzergahlari kapsayan sinir kutusu — kamera bunu kullanir.
  final RouteBounds bounds;

  final List<RouteShape> routes;

  const RouteShapeBundle({
    required this.schemaVersion,
    required this.bounds,
    required this.routes,
  });

  static const empty = RouteShapeBundle(
    schemaVersion: 0,
    bounds: RouteBounds(south: 0, west: 0, north: 0, east: 0),
    routes: [],
  );

  factory RouteShapeBundle.fromJson(Map<String, dynamic> json) =>
      RouteShapeBundle(
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        bounds: RouteBounds.fromJson(json['bounds'] as Map<String, dynamic>),
        routes: [
          for (final route in (json['routes'] as List<dynamic>? ?? const []))
            RouteShape.fromJson(route as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'bounds': bounds.toJson(),
    'routes': [for (final route in routes) route.toJson()],
  };

  /// Veride bulunan hat kodlari, ilk gorulme sirasiyla: ["AÜ102", "AÜ103"].
  /// Toggle'in secenekleri buradan gelir — kodda sabit hat listesi tutulmaz.
  List<String> get lineNames {
    final names = <String>[];
    for (final route in routes) {
      if (!names.contains(route.shortName)) names.add(route.shortName);
    }
    return names;
  }

  /// Bir hattin tum yonleri (gidis + donus).
  List<RouteShape> forLine(String shortName) =>
      routes.where((r) => r.shortName == shortName).toList();

  RouteShapeBundle copyWith({
    int? schemaVersion,
    RouteBounds? bounds,
    List<RouteShape>? routes,
  }) => RouteShapeBundle(
    schemaVersion: schemaVersion ?? this.schemaVersion,
    bounds: bounds ?? this.bounds,
    routes: routes ?? this.routes,
  );
}
