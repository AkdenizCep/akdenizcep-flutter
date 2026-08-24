import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/route_shape.dart';

/// Hat guzergahlarini asset'ten okur.
///
/// Veri statik oldugu icin bir kez okunup bellekte tutulur — her rebuild'de
/// 8 KB JSON'u yeniden cozmek gereksiz.
///
/// Hat sayisi, renkler, isimler ve yonler tamamen veriden gelir; JSON
/// degistiginde kodda hicbir degisiklik gerekmez.
class RouteShapesService {
  static const _assetPath = 'assets/routes/au_hatlar.json';

  Future<RouteShapeBundle>? _cached;

  Future<RouteShapeBundle> load() {
    // Basarisiz bir yukleme cache'lenmez: hatali Future bir kez saklanirsa
    // oturum boyunca her cagri ayni hatayi doner ve arayuz kalici olarak
    // "alinamadi" durumunda kalir. Hata halinde cache temizlenir ki sonraki
    // deneme gercekten yeniden okusun.
    return _cached ??= _read().onError<Object>((error, stackTrace) {
      _cached = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<RouteShapeBundle> _read() async {
    // rootBundle.loadString zaten UTF-8 okur; ek bir decode gerekmez.
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return RouteShapeBundle.fromJson(json);
  }
}
