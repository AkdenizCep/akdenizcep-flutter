import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'open_stops_page.dart';
import 'timetable_sheet.dart';

/// Haritada Gör kartının arka plan görüntüsü. Dosya henüz yoksa kart düz
/// gradyanla çizilir ([Image.errorBuilder]).
const kRingMapPreviewAsset = 'assets/images/ring_map_preview.png';

const _cardHeight = 112.0;
const _cardRadius = 24.0;

/// Alt buton satırı: "Haritada Gör" (büyük) + "Tüm Tarife".
///
/// İki kart da birebir aynı yükseklikte olmalı: kenarlık `Container`'ın
/// `BoxDecoration`'ında tutulur, yüksekliği sabit bir `SizedBox` belirler.
class RingActionsRow extends ConsumerWidget {
  const RingActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            flex: 16,
            child: _MapCard(onTap: () => openStopsPage(context, ref)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 10,
            child: _TimetableCard(
              onTap: () => openTimetableSheet(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MapCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    return SizedBox(
      height: _cardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                kRingMapPreviewAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      primary,
                      primary.withValues(alpha: 0.5),
                      primary.withValues(alpha: 0.1),
                    ],
                    stops: const [0, 0.45, 0.75, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 12,
                bottom: 12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        size: 21,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    Text(
                      'Haritada Gör',
                      maxLines: 1,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 17,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimetableCard extends StatelessWidget {
  final VoidCallback onTap;

  const _TimetableCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _cardHeight,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 13,
              top: 11,
              bottom: 11,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 21,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Tüm Tarife',
                    maxLines: 1,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 17,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}
