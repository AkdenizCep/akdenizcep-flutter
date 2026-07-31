import 'package:flutter/material.dart';

import '../../models/ring_departures.dart';
import 'ring_format.dart';

/// Sayfanın ana hero kartı: Sıradaki kalkış zamanı, hat seçimi ve yön değiştirme.
class NextDepartureCard extends StatelessWidget {
  final RingDepartures departures;
  final String activeLine;
  final List<String> availableLines;
  final String directionSummary;
  final bool canSwitchDirection;
  final ValueChanged<String> onLineChanged;
  final VoidCallback onSwitchDirection;

  const NextDepartureCard({
    super.key,
    required this.departures,
    required this.activeLine,
    required this.availableLines,
    required this.directionSummary,
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
        borderRadius: BorderRadius.circular(24),
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
            right: -10,
            bottom: -15,
            child: Icon(
              Icons.directions_bus_filled_rounded,
              size: 135,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Üst Satır: Hat Seçim Pill'leri ve Yön Değiştirme Butonu (Canlı yazısı yerine)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Hat seçici pill grubu
                    Row(
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
                    // Yön Değiştirme Butonu (CANLI rozeti yerine üst sağda)
                    if (canSwitchDirection)
                      Material(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onSwitchDirection,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 22),

                // 2. Orta Satır: Saat ve Yön Açıklaması
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Kalkış saati
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
                    const SizedBox(width: 14),
                    // Yön açıklaması
                    Expanded(
                      child: Text(
                        directionSummary.isNotEmpty
                            ? directionSummary
                            : 'Kuzey Ring (Rektörlük Yönü)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Alt Satır: Kalan süre / peron bilgisi
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _displayTime {
    if (departures.nextTime != null) {
      return departures.nextTime!;
    }
    if (departures.times.isNotEmpty) {
      return departures.times.first;
    }
    return '14:10';
  }

  String get _statusSubtitle {
    if (departures.untilNext != null) {
      final mins = departures.untilNext!.inMinutes;
      if (mins <= 0) return 'Peron 1\'den kalkış yapmak üzere';
      return 'Peron 1\'den kalkışa $mins dakika kaldı';
    }
    if (departures.nextTime != null) {
      return 'Peron 1\'den kalkış saati: ${departures.nextTime}';
    }
    return 'Peron 1\'den kalkışa 2 dakika kaldı';
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
      color: isSelected
          ? Colors.white
          : Colors.white.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
