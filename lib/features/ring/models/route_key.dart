/// RTDB tarife anahtarlari ile asset guzergah kimlikleri arasindaki tek kopru.
///
/// Iki ayri kaynak var ve ikisi hatti farkli adlandiriyor:
///
/// | Kaynak | Hat | Yon |
/// | --- | --- | --- |
/// | RTDB `ring_schedule` | `au_102_gidis` -> `lineCode` "au102" | `isReturn` |
/// | Asset `au_hatlar.json` | `shortName` "AÜ102" | `directionId` 0/1 |
///
/// Ikisini birbirine baglayan bilgi tek bir yerde toplanir; yanlis oldugu
/// anlasilirsa duzeltilecek tek nokta burasidir.
library;

import 'turkish_text.dart';

/// Gidis yonunun `directionId` karsiligi.
///
/// AU102_0'in headsign'i "ADLİ TIP → MELTEM KAPISI"; bunun universitenin
/// "gidis" dedigi yon oldugu kabul edildi. Ters cikarsa **yalnizca bu sabit**
/// degisir — tum eslesme buradan turuyor.
const kGidisDirectionId = 0;

int directionIdFor(bool isReturn) =>
    isReturn ? 1 - kGidisDirectionId : kGidisDirectionId;

bool isReturnFor(int directionId) => directionId != kGidisDirectionId;

/// "AÜ102" -> "au102". `RingSchedule.lineCode` ile ayni bicimi uretir.
String lineCodeOf(String shortName) =>
    normalizeForSearch(shortName).replaceAll(RegExp(r'[^a-z0-9]'), '');

/// "au102" + gidis -> "AU102_0". Asset'teki `routeShapeId`/`id` ile eslesir.
String routeShapeIdFor(String lineCode, bool isReturn) {
  final code = lineCodeOf(lineCode).toUpperCase();
  return '${code}_${directionIdFor(isReturn)}';
}
