import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;

import '../../models/ring_departures.dart';

/// Bir hattın günlük kalkış saatleri: yatay kaydırılabilen tek şerit.
///
/// Sıradaki kalkış büyük ve şeridin ortasında durur; öncekiler solda, sonrakiler
/// sağda soluk görünür. Şerit tüm günün saatlerini taşır, kullanıcı kaydırarak
/// geçmiş ve ilerideki seferlere bakabilir.
///
/// ÖNEMLİ: Her saat hattın **kalkış noktasından** ayrılma zamanıdır.
class DepartureStrip extends StatefulWidget {
  final RingDepartures departures;

  const DepartureStrip({super.key, required this.departures});

  @override
  State<DepartureStrip> createState() => _DepartureStripState();
}

/// Şeridin ne çizeceği: saatler, vurgulanan saat ve ortalanacak saat.
typedef _StripModel = ({
  List<String> times,
  int? highlight,
  bool isTomorrow,
  int anchor,
});

_StripModel _modelOf(RingDepartures departures) {
  final times = departures.times;

  final next = departures.nextTime;
  if (next != null) {
    final index = times.indexOf(next);
    if (index >= 0) {
      return (times: times, highlight: index, isTomorrow: false, anchor: index);
    }
  }

  // Bugün sefer kalmadı: yarının ilk kalkışı şeridin sonuna eklenir.
  final tomorrow = departures.tomorrowFirstTime;
  if (departures.isToday && tomorrow != null) {
    return (
      times: [...times, tomorrow],
      highlight: times.length,
      isTomorrow: true,
      anchor: times.length,
    );
  }

  // Vurgulanacak kalkış yok; gün bittiyse sona, tarife okunuyorsa başa gidilir.
  final anchor = departures.isToday && times.isNotEmpty ? times.length - 1 : 0;
  return (times: times, highlight: null, isTomorrow: false, anchor: anchor);
}

class _DepartureStripState extends State<DepartureStrip>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  final _anchorKey = GlobalKey();

  /// Şeridin görünürlüğü (0 = gizli, 1 = görünür).
  ///
  /// Ortalamak için sıradaki saatin konumu **yerleşimden sonra** bilinebilir,
  /// bu yüzden kaydırma bir kare geç uygulanır ([_centerAnchor]). İçerik
  /// değiştiği (ilk kurulum, yön, gün) karede şerit bu yüzden eski konumda
  /// kalır: yeni saatler yanlış yerde çizilir, vurgulanan saat ekran dışına
  /// düşer, sonraki karede merkeze atlar. O kare ekrana gitmesin diye şerit
  /// içerik değiştiği anda gizlenir ve ortalanınca açılır.
  late final AnimationController _reveal;

  static const _revealDuration = Duration(milliseconds: 160);

  /// Açılış, tam saydamdan değil buradan başlar: ortalanmış ilk kare zaten
  /// doğrudur, boş bir kare daha beklemeye gerek yok.
  static const _revealStart = 0.35;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: _revealDuration,
      value: 0,
    );
    _centerAnchor(animate: false);
  }

  @override
  void didUpdateWidget(DepartureStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    final before = _modelOf(oldWidget.departures);
    final after = _modelOf(widget.departures);
    final sameTimes = listEquals(before.times, after.times);
    if (sameTimes &&
        before.anchor == after.anchor &&
        before.isTomorrow == after.isTomorrow) {
      return;
    }

    // Aynı günün tarifesinde sıradaki sefer ilerlediyse kaydırarak ortala:
    // içerik aynı, şerit görünür kalır. Tarife (yön) değiştiyse atlayarak
    // ortala ve atlama görünmesin diye şeridi gizle. `didUpdateWidget`
    // yapıdan önce çalışır; şerit bu karede zaten gizli çizilir.
    if (!sameTimes) _reveal.value = 0;
    _centerAnchor(animate: sameTimes);
  }

  @override
  void dispose() {
    _reveal.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _centerAnchor({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final target = _anchorKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          alignment: 0.5,
          duration: animate ? const Duration(milliseconds: 350) : Duration.zero,
          curve: Curves.easeOutCubic,
        );
      }

      // Ortalanacak saat olmasa da şerit açılmalı: yoksa içerik sonsuza dek
      // gizli kalır.
      _showStrip();
    });
  }

  void _showStrip() {
    // Sistem animasyonları kapatıldıysa beklemeden açılır.
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward(from: math.max(_reveal.value, _revealStart));
    }
  }

  /// Ortalanmış başlangıç konumunun kaydırma ofseti. Şerit henüz çizilmediyse
  /// `null`.
  double? _homeOffset() {
    final anchor = _anchorKey.currentContext?.findRenderObject();
    if (anchor == null || !_controller.hasClients) return null;

    final viewport = RenderAbstractViewport.maybeOf(anchor);
    if (viewport == null) return null;

    final position = _controller.position;
    return viewport
        .getOffsetToReveal(anchor, 0.5)
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  /// Kaydırma başlangıç konumunun hemen yanında bittiyse şeridi oraya döndürür;
  /// biraz kaymış bir şerit yarım ortalanmış görünür.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollEndNotification) return false;

    final home = _homeOffset();
    if (home == null) return false;

    final distance = (notification.metrics.pixels - home).abs();
    // Başlangıçtaysa (kendi animasyonumuzun sonu dahil) yapılacak bir şey yok.
    if (distance > 0.5 && distance <= _snapBackDistance) {
      // Bildirim kaydırma etkinliği değişirken gelir; burada başlatılan
      // animasyon hemen ardından gelen "boşta" etkinliği tarafından iptal
      // edilir. Bu yüzden bir sonraki microtask'a ertelenir.
      Future.microtask(_snapBack);
    }
    return false;
  }

  void _snapBack() {
    final home = _homeOffset();
    if (!mounted || home == null) return;

    _controller.animateTo(
      home,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _modelOf(widget.departures);

    if (model.times.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Sefer saati girilmemiş',
          style: _dimStyle.copyWith(fontSize: 14),
        ),
      );
    }

    return FadeTransition(
      opacity: _reveal,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Yarım görünüm genişliği boşluk, ilk ve son saatin de ortalanmasını
          // sağlar.
          final edge = constraints.maxWidth.isFinite
              ? constraints.maxWidth / 2
              : 0.0;

          return NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: edge),
              child: Row(
                children: [
                  for (var i = 0; i < model.times.length; i++)
                    KeyedSubtree(
                      key: i == model.anchor ? _anchorKey : null,
                      child: _StripTime(
                        time: model.times[i],
                        isHighlighted: i == model.highlight,
                        isTomorrow: i == model.highlight && model.isTomorrow,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Kaydırma başlangıç konumuna bu kadar yakın bittiyse şerit oraya döner.
const _snapBackDistance = 60.0;

const _tabularFigures = [FontFeature.tabularFigures()];

final _dimStyle = TextStyle(
  color: Colors.white.withValues(alpha: 0.6),
  fontSize: 16,
  height: 1.0,
  fontWeight: FontWeight.w600,
  fontFeatures: _tabularFigures,
);

class _StripTime extends StatelessWidget {
  final String time;
  final bool isHighlighted;

  /// Vurgulanan saat bugünün değil yarının ilk kalkışıdır.
  final bool isTomorrow;

  const _StripTime({
    required this.time,
    required this.isHighlighted,
    required this.isTomorrow,
  });

  @override
  Widget build(BuildContext context) {
    if (!isHighlighted) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(time, style: _dimStyle),
      );
    }

    final timeText = Text(
      time,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 30,
        height: 1.0,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        fontFeatures: _tabularFigures,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: isTomorrow
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'yarın',
                  style: _dimStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                timeText,
              ],
            )
          : timeText,
    );
  }
}
