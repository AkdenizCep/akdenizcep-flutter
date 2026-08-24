import 'package:flutter/material.dart';

import '../../models/ring_departures.dart';
import 'ring_format.dart';

/// Sayfanın ana hero kartı: sıradaki kalkış zamanı, hat seçimi, yön değiştirme
/// ve alt şeritte önceki / sonraki / son sefer.
///
/// ÖNEMLİ: Buradaki her saat hattın **kalkış noktasından** ayrılma zamanıdır;
/// herhangi bir durağa varış zamanı değildir.
class NextDepartureCard extends StatelessWidget {
  final RingDepartures departures;
  final String activeLine;
  final List<String> availableLines;
  final String directionSummary;

  /// Seçili tarifenin kalkış durağı. Durak verisi girilmemişse `null`.
  final String? originName;
  final bool canSwitchDirection;
  final ValueChanged<String> onLineChanged;
  final VoidCallback onSwitchDirection;

  const NextDepartureCard({
    super.key,
    required this.departures,
    required this.activeLine,
    required this.availableLines,
    required this.directionSummary,
    required this.originName,
    required this.canSwitchDirection,
    required this.onLineChanged,
    required this.onSwitchDirection,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Arka plan filigran otobüs ikonu
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(
              Icons.directions_bus_filled_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Üst satır: hat pill'leri + yön değiştirme
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final line in availableLines.isEmpty
                                ? [activeLine]
                                : availableLines) ...[
                              _LinePill(
                                label: lineLabel(line),
                                isSelected: line == activeLine,
                                onTap: () => onLineChanged(line),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (canSwitchDirection)
                      Material(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onSwitchDirection,
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Orta satır: kalkış saati ve yön açıklaması
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _displayTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          directionSummary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                // 3. Durum satırı: kalkış noktası + kalan süre
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _statusSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // 4. Alt şerit: önceki / sonraki / son sefer
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StripCell(
                          label: _leadingLabel,
                          value: _leadingValue,
                          isMuted: departures.isToday,
                        ),
                      ),
                      Expanded(
                        child: _StripCell(
                          label: 'SONRAKİ',
                          value: _followingValue,
                        ),
                      ),
                      Expanded(
                        child: _StripCell(
                          label: 'SON SEFER',
                          value: departures.times.isEmpty
                              ? null
                              : departures.times.last,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _displayTime {
    if (departures.nextTime != null) return departures.nextTime!;
    if (departures.times.isNotEmpty) return departures.times.first;
    return '—';
  }

  /// Tarife görüntülenirken "önceki" diye bir şey yok — o hücre günün ilk
  /// kalkışını gösterir.
  String get _leadingLabel => departures.isToday ? 'ÖNCEKİ' : 'İLK SEFER';

  String? get _leadingValue {
    if (departures.isToday) return departures.previousTime;
    return departures.times.isEmpty ? null : departures.times.first;
  }

  /// Hero'daki büyük saat sıradaki kalkış; bu hücre ondan **sonraki** kalkış.
  String? get _followingValue {
    if (!departures.isToday) {
      return departures.times.length > 1 ? departures.times[1] : null;
    }
    return departures.upcoming.length > 1 ? departures.upcoming[1] : null;
  }

  String get _statusSubtitle {
    if (!departures.isToday) return 'Tarife görüntülüyorsun';

    final origin = originName;
    final prefix = origin == null ? 'Kalkış' : 'Kalkış: $origin';

    final until = departures.untilNext;
    if (until != null) {
      final minutes = until.inMinutes;
      if (minutes <= 0) return '$prefix · kalkmak üzere';
      return '$prefix · ${countdownText(until)} kaldı';
    }

    final tomorrow = departures.tomorrowFirstTime;
    if (tomorrow != null) {
      return 'Bugün bitti · yarın ilk kalkış $tomorrow';
    }
    return departures.times.isEmpty
        ? 'Bu gün için sefer saati girilmemiş'
        : '$prefix · bugün için başka kalkış yok';
  }
}

/// Alt şeritteki tek hücre. Değer yoksa satır gizlenmez, "—" yazılır.
class _StripCell extends StatelessWidget {
  final String label;
  final String? value;

  /// Geçmiş kalkış olduğu için soluk gösterilir.
  final bool isMuted;

  const _StripCell({required this.label, this.value, this.isMuted = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.76,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value ?? '—',
          style: TextStyle(
            color: Colors.white.withValues(alpha: isMuted ? 0.65 : 1),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LinePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LinePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
