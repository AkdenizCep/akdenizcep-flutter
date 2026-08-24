import 'package:akdenizcep/features/ring/models/ring_stop.dart';
import 'package:akdenizcep/features/ring/models/route_key.dart';
import 'package:akdenizcep/features/ring/models/route_shape.dart';

/// Ring testleri icin ortak kurulum.
///
/// Durak ve guzergah modelleri gercek asset semasindan dogdugu icin elle
/// kurmak uzun; testler veri kurulumuyla degil davranisla ilgilensin diye
/// yardimcilar burada toplandi.

const _bounds = RouteBounds(
  south: 36.89,
  west: 30.64,
  north: 36.90,
  east: 30.66,
);

/// Tek bir hat/yon hizmeti.
StopService service(
  String shortName, {
  bool isReturn = false,
  int sequence = 1,
  String? towards,
}) {
  final directionId = directionIdFor(isReturn);
  final target = towards ?? (isReturn ? 'Adli Tıp' : 'Meltem Kapısı');

  return StopService(
    routeShapeId: routeShapeIdFor(shortName, isReturn),
    shortName: shortName,
    directionId: directionId,
    stopSequence: sequence,
    color: isReturn ? '#64B5F6' : '#1565C0',
    label: '$shortName · $target yönü',
  );
}

/// Test duragi. [name] ham GTFS adi gibi verilir; model onu bicimlendirir.
RingStop stop(
  String id, {
  String? name,
  double lat = 36.895,
  double lng = 30.650,
  List<StopService> servedBy = const [],
}) {
  return RingStop.fromJson({
    'stopId': id,
    'name': name ?? id,
    'lat': lat,
    'lon': lng,
    'isTransfer': servedBy.map((s) => s.shortName).toSet().length > 1,
    'servedBy': [for (final s in servedBy) s.toJson()],
  });
}

/// Yon etiketlerini besleyen guzergah paketi.
///
/// `StopDepartures.merge` yon metnini buradan okur; bos paket verilirse
/// "Gidiş"/"Dönüş"e duser.
RouteShapeBundle routeBundle({
  List<String> lines = const ['AÜ102', 'AÜ103'],
  Map<String, String> towards = const {},
}) {
  return RouteShapeBundle(
    schemaVersion: 1,
    bounds: _bounds,
    routes: [
      for (final line in lines)
        for (final isReturn in [false, true])
          RouteShape(
            id: routeShapeIdFor(line, isReturn),
            shortName: line,
            directionId: directionIdFor(isReturn),
            headsign: isReturn
                ? 'MELTEM KAPISI → ADLİ TIP'
                : 'ADLİ TIP → MELTEM KAPISI',
            label:
                '$line · '
                '${towards['$line${isReturn ? '_1' : '_0'}'] ?? (isReturn ? 'Adli Tıp' : 'Meltem Kapısı')} yönü',
            color: '#1565C0',
            lengthKm: 3.4,
            bounds: _bounds,
            points: const [RoutePoint(36.895, 30.650)],
          ),
    ],
  );
}
