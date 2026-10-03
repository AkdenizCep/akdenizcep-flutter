import 'package:flutter/material.dart';

import '../../models/ring_departures.dart';
import 'departure_strip.dart';
import 'ring_format.dart';
import 'route_swap_title.dart';

/// Sayfanın ana hero kartı: seçili yön ve o yöndeki her hattın kalkış saatleri.
///
/// Her hat kendi satırında yatay kaydırılabilen bir saat şeridi taşır; sıradaki
/// kalkış büyük ve ortada durur.
///
/// ÖNEMLİ: Buradaki her saat hattın **kalkış noktasından** ayrılma zamanıdır;
/// herhangi bir durağa varış zamanı değildir.
class NextDepartureCard extends StatelessWidget {
  /// Seçili yöndeki hatlar, gösterim sırasıyla.
  final List<LineDepartures> lines;

  /// Kalkış ve varış noktaları. İkisi de biliniyorsa "Adli Tıp → Meltem
  /// Kapısı" yazılır; biri eksikse [fallbackTitle] kullanılır.
  final String? originName;
  final String? destinationName;

  /// Güzergâh adı bilinmediğinde başlık ("Gidiş" / "Dönüş").
  final String fallbackTitle;
  final bool canSwitchDirection;
  final VoidCallback onSwitchDirection;

  const NextDepartureCard({
    super.key,
    required this.lines,
    required this.originName,
    required this.destinationName,
    required this.fallbackTitle,
    required this.canSwitchDirection,
    required this.onSwitchDirection,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(
            originName: originName,
            destinationName: destinationName,
            fallbackTitle: fallbackTitle,
            canSwitchDirection: canSwitchDirection,
            onSwitchDirection: onSwitchDirection,
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < lines.length; i++) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.22),
            ),
            _LineRow(
              line: lines[i],
              chipColors: i == 0 ? _ChipColors.light : _ChipColors.dark,
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? originName;
  final String? destinationName;
  final String fallbackTitle;
  final bool canSwitchDirection;
  final VoidCallback onSwitchDirection;

  const _Header({
    required this.originName,
    required this.destinationName,
    required this.fallbackTitle,
    required this.canSwitchDirection,
    required this.onSwitchDirection,
  });

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 18,
      height: 1.2,
      fontWeight: FontWeight.w800,
    );

    final origin = originName;
    final destination = destinationName;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YÖN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              if (origin != null && destination != null)
                // Yön değişince iki ad birbirinin yerine kayar.
                RouteSwapTitle(
                  origin: origin,
                  destination: destination,
                  style: titleStyle,
                )
              else
                Text(fallbackTitle, style: titleStyle),
            ],
          ),
        ),
        if (canSwitchDirection) ...[
          const SizedBox(width: 12),
          _SwitchButton(onTap: onSwitchDirection),
        ],
      ],
    );
  }
}

/// Yönü değiştiren beyaz hap buton.
///
/// Basınca oklar kendi etrafında bir tam tur atar. Dönüş "kaç tur atıldı"
/// sayacına bağlıdır: her basış hedefi bir tur ilerletir, bu yüzden art arda
/// basışta ikon başa sıçramaz, bulunduğu açıdan bir tur daha döner.
class _SwitchButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SwitchButton({required this.onTap});

  @override
  State<_SwitchButton> createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<_SwitchButton> {
  static const _spinDuration = Duration(milliseconds: 450);

  final _turns = ValueNotifier(0);

  void _onTap() {
    // Yön değişimi animasyonu beklemez; ikon yalnızca geri bildirimdir.
    _turns.value++;
    widget.onTap();
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // Sistem animasyonları kapatıldıysa ikon beklemeden son konuma geçer.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sürekli dönen parça kendi katmanında olmalı: sınır yoksa her
              // karede en yakın üst katmanın tamamı (kart, gölgesi, saat
              // şeritleri) yeniden kaydedilir. Sınır dönüşümün **dışında**
              // durur; içinde olsaydı dönüşüm yine üst katmanı kirletirdi.
              RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _turns,
                  builder: (context, turns, child) => AnimatedRotation(
                    turns: turns.toDouble(),
                    duration: reduceMotion ? Duration.zero : _spinDuration,
                    curve: Curves.easeInOutCubic,
                    child: child,
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: primary,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Değiştir',
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kart mavi olduğu için ilk hat beyaz, ikincisi koyu rozet alır.
enum _ChipColors {
  light(fill: Colors.white, text: null),
  dark(fill: Color(0xFF171A22), text: Colors.white);

  final Color fill;

  /// `null` ise kartın ana rengi kullanılır.
  final Color? text;

  const _ChipColors({required this.fill, required this.text});
}

class _LineRow extends StatelessWidget {
  final LineDepartures line;
  final _ChipColors chipColors;

  const _LineRow({required this.line, required this.chipColors});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 62,
      child: Row(
        children: [
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chipColors.fill,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              lineLabel(line.lineCode),
              maxLines: 1,
              style: TextStyle(
                color: chipColors.text ?? primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Şerit satırın kalanını doldurur; kenarlarda kırpılması tasarım gereği.
          Expanded(
            child: DepartureStrip(
              // Hat değişince kaydırma konumu başka satıra sızmasın.
              key: ValueKey(line.lineCode),
              departures: line.departures,
            ),
          ),
        ],
      ),
    );
  }
}
