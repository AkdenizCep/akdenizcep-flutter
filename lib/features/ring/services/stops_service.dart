import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/ring_stop.dart';

/// Ring duraklarini asset'ten okur.
///
/// **Neden veritabani degil:** duraklar GTFS turevi topolojidir — konum, hat
/// uyeligi ve guzergah sirasi yilda bir degisir. Universitenin gercekten
/// guncelledigi veri kalkis saatleridir ve o RTDB'de kalir. Bu ayrim, durak
/// arayuzunun elle veri girisine bagimli olmasini bitirir: `ring_stops`
/// dugumu uzun sure bos kaldigi icin harita, en yakin durak ve favoriler
/// hic calismiyordu.
///
/// Asset statik oldugu icin bir kez okunup bellekte tutulur.
class StopsService {
  static const _assetPath = 'assets/routes/au_duraklar.json';

  Future<RingStopBundle>? _cached;

  Future<RingStopBundle> load() {
    // Basarisiz bir yukleme cache'lenmez: hatali Future bir kez saklanirsa
    // oturum boyunca her cagri ayni hatayi doner ve arayuz kalici olarak
    // "alinamadi" durumunda kalir. Hata halinde cache temizlenir ki sonraki
    // deneme gercekten yeniden okusun.
    return _cached ??= _read().onError<Object>((error, stackTrace) {
      _cached = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<RingStopBundle> _read() async {
    // rootBundle.loadString zaten UTF-8 okur; ek bir decode gerekmez.
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return RingStopBundle.fromJson(json);
  }
}
