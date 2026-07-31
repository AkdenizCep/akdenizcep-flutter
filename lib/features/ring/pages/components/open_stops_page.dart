import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers/location_provider.dart';

/// "Yakındaki Duraklar" sayfasini acar: once gezinir, konumu **bekletmeden**
/// ister.
///
/// Konumu beklemek acilisi GPS fix suresi kadar geciktirir (soguk baslangicta
/// ve emulatorde birkac saniye, en kotu durumda [LocationService] icindeki
/// 10 sn'lik timeLimit kadar). Bu sure boyunca ekranda hicbir sey degismedigi
/// icin kullaniciya "buton tepki vermedi" gibi gorunur.
///
/// Beklemek zaten gereksiz: Duraklar sayfasi konumsuz calisacak sekilde
/// tasarlandi — harita kampuse odaklanir, liste guzergah sirasina gore
/// dizilir, mesafeler gizlenir, izin afisi konumu istemeyi ustlenir. Konum
/// sonradan geldiginde liste mesafeye gore yeniden siralanir ve harita
/// kamerayi kendisi tasir.
///
/// Bu fonksiyon **tek giris noktasidir**. Sayfaya iki yerden gidiliyor
/// ([NearestStopButton] ve [RingGridActions]); davranis daha once bu iki
/// yerde birbirinden ayri yazilmisti ve biri duzeltilip digeri unutuldugu
/// icin gecikme fark edilmeden surdu. Yeni bir giris noktasi eklerken de
/// buradan gecirin.
void openStopsPage(BuildContext context, WidgetRef ref) {
  // Notifier provider kapsayicisina ait; cagiran widget gezinme sirasinda
  // dispose olsa da istek guvenle surer. `ref` gezinmeden sonra
  // kullanilamayacagi icin once okunur.
  final locator = ref.read(userPositionProvider.notifier);
  final hasLocation = ref.read(userPositionProvider) != null;

  context.go('/ring/stops');

  // Konum zaten biliniyorsa yeniden istemeye gerek yok. Izin diyalogu yine
  // yalnizca dokunulunca cikar — sadece artik yeni sayfanin uzerinde.
  if (!hasLocation) locator.request();
}
