import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/components/akdeniz_cep_logo.dart';
import '../../../../shared/components/app_top_bar.dart';

/// Sayfanin ust basligi: standart [AppTopBar] (gradyan uzerinde beyaz
/// varyant) + gun gezinme oklari/tarih. Menu karti bu alanin uzerine biner
/// — bindirme payi [overlap] kadardir.
class CafeteriaHero extends StatelessWidget {
  static const overlap = 28.0;

  final DateTime date;

  /// Tarihin altindaki tek satirlik durum metni ("4 çeşit · Günün menüsü").
  final String subtitle;

  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextDay;
  final VoidCallback onPickDate;
  final VoidCallback onShowInfo;

  const CafeteriaHero({
    super.key,
    required this.date,
    required this.subtitle,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDate,
    required this.onShowInfo,
  });

  bool get _isToday => DateUtils.isSameDay(date, DateTime.now());

  /// Baslik zemini logo paletinden turetilir — ustte camgobegi (koyulastirilmis),
  /// altta logo laciverti. Koyulastirma siyaha karistirarak degil HSL parlakligi
  /// dusurulerek yapiliyor; siyaha karistirmak rengi soluklastiriyor.
  static ({Color top, Color bottom}) _gradientColors(bool isDark) {
    final cyanHsl = HSLColor.fromColor(AkdenizCepLogo.defaultCyan);
    final navyHsl = HSLColor.fromColor(AkdenizCepLogo.defaultNavy);

    final top = cyanHsl
        .withLightness((cyanHsl.lightness - (isDark ? 0.14 : 0.08)).clamp(0.0, 1.0))
        .toColor();
    final bottom = navyHsl
        .withLightness((navyHsl.lightness - (isDark ? 0.05 : 0.0)).clamp(0.0, 1.0))
        .toColor();

    return (top: top, bottom: bottom);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _gradientColors(isDark);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.top, colors.bottom],
        ),
      ),
      // Sag ustten gelen yumusak isik — duz zemine derinlik veriyor.
      // Metnin ustune degil arkasina basmasi icin DecoratedBox ile veriliyor.
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.66, -0.95),
            radius: 1.15,
            colors: [
              Colors.white.withValues(alpha: isDark ? 0.10 : 0.17),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.62],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopBar(
                title: 'Yemekhane',
                onGradient: true,
                actions: [
                  AppTopBarAction.translucent(
                    icon: Icons.info_outline_rounded,
                    tooltip: 'Yemekhane bilgileri',
                    onTap: onShowInfo,
                  ),
                  AppTopBarAction.translucent(
                    icon: Icons.calendar_month_rounded,
                    tooltip: 'Tarih seç',
                    onTap: onPickDate,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 26, 14, 16 + overlap),
                // Gun gezinme oklari dogrudan tarihin yaninda — ayri bir
                // arac cubugu satiri yerine hangi metni degistirdiklerini
                // gosteriyorlar.
                child: Row(
                  children: [
                    _HeroButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Önceki gün',
                      onPressed: onPreviousDay,
                    ),
                    Expanded(
                      child: _DateBlock(
                        date: date,
                        isToday: _isToday,
                        subtitle: subtitle,
                      ),
                    ),
                    _HeroButton(
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'Sonraki gün',
                      onPressed: onNextDay,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final String subtitle;

  const _DateBlock({
    required this.date,
    required this.isToday,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEEE', 'tr').format(date).toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'BUGÜN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Text(
          DateFormat('d MMMM', 'tr').format(date),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HeroButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed != null ? 1 : 0.35,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          iconSize: 22,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(foregroundColor: Colors.white),
          icon: Icon(icon),
        ),
      ),
    );
  }
}
