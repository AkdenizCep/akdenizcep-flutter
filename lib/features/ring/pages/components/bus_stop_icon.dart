import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/ring_stop.dart';
import '../../models/route_key.dart';
import '../../providers/ring_provider.dart';
import 'line_badge.dart';

/// Durak ikonunun rengi: yanindaki hat rozetiyle ayni palet ([lineColors]).
///
/// Oncelik sirasi:
/// 1. [soonestLineCode] — duraktan siradaki seferin hatti ("au102").
/// 2. Duraktan **tek** hat geciyorsa o hat ([stopLineNames], "AÜ102").
/// 3. Aksi halde (iki hat geciyor ve sefer yok, ya da hat bilinmiyor)
///    notr `primary`.
///
/// [lines] tanimli hat kodlari ("au102"); listede olmayan bir hat icin palet
/// yoktur, bu yuzden `primary`'e dusulur.
Color busStopColor(
  ColorScheme colorScheme,
  List<String> lines, {
  String? soonestLineCode,
  List<String> stopLineNames = const [],
}) {
  final code =
      soonestLineCode ??
      (stopLineNames.length == 1 ? lineCodeOf(stopLineNames.single) : null);

  if (code == null || !lines.contains(code)) return colorScheme.primary;
  return lineColors(colorScheme, lines, code).fill;
}

/// Harita pininin rengi: aktif hat bu duraktan geciyorsa onun rengi.
///
/// Harita ayni anda tek hat gosterir ([activeLine], "AÜ102"); gorunen her
/// durak o hatta durur ve pin hattin rengini alir. Aktif hat yoksa ya da bu
/// duraktan gecmiyorsa durak kendi hat(lar)ina gore boyanir ([busStopColor]).
Color busStopPinColor(
  ColorScheme colorScheme,
  List<String> lines,
  RingStop stop, {
  String? activeLine,
}) {
  final servesActive = activeLine != null && stop.servesLine(activeLine);
  return busStopColor(
    colorScheme,
    lines,
    stopLineNames: servesActive ? [activeLine] : stop.lineNames,
  );
}

/// `assets/images/bus-stop.svg` — "D" durak levhasi, tek renkle boyanir.
///
/// SVG `currentColor` kullanir: cerceve ve harf tam renk, zemin ayni rengin
/// %12 tonu. Bu yuzden acik ve koyu temada ayri varyant gerekmez.
class BusStopIcon extends StatelessWidget {
  final Color color;
  final double size;

  const BusStopIcon({super.key, required this.color, this.size = 24});

  static const asset = 'assets/images/bus-stop.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
      semanticsLabel: 'Durak',
    );
  }
}

/// Bir duragin ikonu; rengi [busStopColor] kuralina gore hattan gelir.
///
/// Durak ikonunun gectigi her yuzey bunu kullanir, boylece renk kurali tek
/// yerde kalir.
class StopBusIcon extends ConsumerWidget {
  final RingStop stop;
  final double size;

  const StopBusIcon({super.key, required this.stop, this.size = 24});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(availableLinesProvider);
    final soonest = ref.watch(stopSoonestDepartureProvider(stop.id));

    return BusStopIcon(
      size: size,
      color: busStopColor(
        Theme.of(context).colorScheme,
        lines,
        soonestLineCode: soonest?.lineCode,
        stopLineNames: stop.lineNames,
      ),
    );
  }
}
