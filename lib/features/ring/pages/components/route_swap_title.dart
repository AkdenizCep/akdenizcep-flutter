import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rota başlığı: "Adli Tıp → Meltem Kapısı".
///
/// Yön değişince ([origin] ile [destination] birbirinin yerine geçince) iki ad
/// yer değiştirir: biri hafifçe yukarı, öteki aşağı kavis çizerek birbirinin
/// yerine kayar, ok da kaybolup yeni yerinde belirir. Adlar tamamen değişirse
/// (başka hat/güzergâh) animasyon oynamaz, yeni başlık hemen yerleşir.
///
/// Adlar iki ayrı parça olduğu için konumları metin ölçülerek hesaplanır;
/// başlık her zaman **tek satırdır**. Alan darsa tamamı birlikte küçülür
/// (`scaleDown`), satıra bölünmez — satıra bölünen metin yer değiştiremez.
///
/// Performans: her ad ve ok kendi [RepaintBoundary]'sinde durur ve hareket
/// yalnızca [Transform] ile verilir. Kare başına yeniden yerleşim ya da metin
/// çizimi yoktur; yalnızca üç katmanın dönüşüm matrisi güncellenir.
class RouteSwapTitle extends StatefulWidget {
  final String origin;
  final String destination;
  final TextStyle style;
  final Color arrowColor;
  final double arrowSize;

  const RouteSwapTitle({
    super.key,
    required this.origin,
    required this.destination,
    required this.style,
    this.arrowColor = Colors.white,
    this.arrowSize = 18,
  });

  /// Yer değiştirme animasyonunun süresi.
  static const swapDuration = Duration(milliseconds: 520);

  @override
  State<RouteSwapTitle> createState() => _RouteSwapTitleState();
}

/// Üç parçanın x konumları: ilk ad, ok bloğu, ikinci ad.
typedef _Slots = ({double first, double arrow, double second});

class _RouteSwapTitleState extends State<RouteSwapTitle>
    with SingleTickerProviderStateMixin {
  /// Adların yukarı/aşağı kavis yüksekliği. İkisi yan yana geçerken harfler
  /// üst üste binmesin diye zıt yöne kayarlar; ortada aralarındaki mesafe
  /// (2 x kavis) satır yüksekliğine yetişmelidir, yoksa harfler çakışır.
  /// Yukarı çıkan ad "YÖN" etiketinin yanından ancak kavis küçükken geçer:
  /// kavis yüksekken yatayda etiketten uzaktadır.
  static const _arc = 11.0;

  /// Okun iki yanındaki boşluk.
  static const _arrowPad = 7.0;

  late final AnimationController _controller;

  /// İki adın kimliği: ilk görüldükleri sıra. Yön çevrilince başlıktaki
  /// (kalkış, varış) çifti yer değiştirir ama kimlikler aynı kalır; hangi
  /// parçanın nereye kayacağı buradan bilinir.
  late String _first;
  late String _second;

  double _firstWidth = 0;
  double _secondWidth = 0;
  double _lineHeight = 0;

  late _Slots _from;
  late _Slots _to;

  double get _arrowBlock => widget.arrowSize + 2 * _arrowPad;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: RouteSwapTitle.swapDuration,
      // Başlangıçta yerleşik: ilk çizimde animasyon oynamaz.
      value: 1,
    );
    _first = widget.origin;
    _second = widget.destination;
  }

  /// Ölçü, yazı ölçeği ve miras alınan yazı stiline bağlıdır; ikisi de
  /// [BuildContext] ister, bu yüzden [initState] değil burası.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settle();
  }

  @override
  void didUpdateWidget(RouteSwapTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin == widget.origin &&
        oldWidget.destination == widget.destination &&
        oldWidget.style == widget.style) {
      return;
    }

    final isSwap =
        oldWidget.origin != oldWidget.destination &&
        oldWidget.origin == widget.destination &&
        oldWidget.destination == widget.origin &&
        oldWidget.style == widget.style;

    if (!isSwap) {
      // Başka güzergâh ya da stil: kimlikler yenilenir, animasyon yok.
      _first = widget.origin;
      _second = widget.destination;
      _settle();
      return;
    }

    // Yarıda kesilen animasyon bulunduğu konumdan devam eder, başa sıçramaz.
    _from = _currentSlots();
    _to = _slotsFor(widget);

    // Sistem animasyonları kapatıldıysa beklemeden son konuma geçilir.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ölçüleri yeniler ve animasyonsuz, yerleşik duruma geçer.
  void _settle() {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final scaler = MediaQuery.textScalerOf(context);

    Size measure(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final first = measure(_first);
    final second = measure(_second);
    _firstWidth = first.width;
    _secondWidth = second.width;
    _lineHeight = math.max(first.height, second.height);

    _from = _to = _slotsFor(widget);
    _controller.value = 1;
  }

  /// Verilen (kalkış, varış) çiftine göre üç parçanın yerleşik konumları.
  /// Toplam genişlik iki durumda da aynıdır: ad genişlikleri + ok bloğu.
  _Slots _slotsFor(RouteSwapTitle target) {
    final firstIsOrigin = target.origin == _first;
    return firstIsOrigin
        ? (first: 0, arrow: _firstWidth, second: _firstWidth + _arrowBlock)
        : (first: _secondWidth + _arrowBlock, arrow: _secondWidth, second: 0);
  }

  static double _ease(double t) => Curves.easeInOutCubic.transform(t);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  _Slots _currentSlots() {
    final t = _ease(_controller.value);
    return (
      first: _lerp(_from.first, _to.first, t),
      arrow: _lerp(_from.arrow, _to.arrow, t),
      second: _lerp(_from.second, _to.second, t),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget label(String text) => RepaintBoundary(
      child: Text(
        text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );

    // Yalnızca bir kez kurulur: kare başına değişen tek şey [Transform]'lar.
    final firstLabel = label(_first);
    final secondLabel = label(_second);
    final total = _firstWidth + _secondWidth + _arrowBlock;

    return Semantics(
      label: '${widget.origin} → ${widget.destination}',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: total,
              height: _lineHeight,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final settled = _controller.value >= 1;
                  final progress = _ease(_controller.value);
                  final slots = _currentSlots();

                  // Yerleşikken tam sıfır/bir: ondalık artıklar çizime sızmasın.
                  final bump = settled ? 0.0 : math.sin(math.pi * progress);
                  final arrowAlpha = widget.arrowColor.a * (1 - bump);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Transform.translate(
                        offset: Offset(slots.first, -_arc * bump),
                        child: firstLabel,
                      ),
                      Transform.translate(
                        offset: Offset(slots.arrow, 0),
                        child: RepaintBoundary(
                          child: SizedBox(
                            width: _arrowBlock,
                            height: _lineHeight,
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: widget.arrowSize,
                                color: widget.arrowColor.withValues(
                                  alpha: arrowAlpha,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(slots.second, _arc * bump),
                        child: secondLabel,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
