import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ring_provider.dart';
import 'open_stops_page.dart';
import 'ring_action_button.dart';
import 'ring_format.dart';

/// Iki durumlu giris noktasi:
///
/// * Konum biliniyorsa en yakin duragi dogrudan gosterir — en degerli bilgi
///   tek satir, onu bir dokunusun arkasina saklamak gereksiz.
/// * Konum yoksa cagri metnine duser ve izni **yalnizca dokunulunca** ister;
///   sayfa acilisinda izin diyalogu cikmaz.
///
/// Durak verisi hic yoksa hicbir sey cizmez.
class NearestStopButton extends ConsumerWidget {
  const NearestStopButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stops = ref.watch(ringStopsProvider).valueOrNull ?? const [];
    if (stops.isEmpty) return const SizedBox.shrink();

    final nearest = ref.watch(nearestStopProvider);

    if (nearest == null) {
      return RingActionButton(
        icon: Icons.my_location_rounded,
        title: 'Yakındaki Duraklar',
        value: 'Konumunu aç, sana en yakın durağı bulalım',
        onTap: () => openStopsPage(context, ref),
      );
    }

    return RingActionButton(
      icon: Icons.place_rounded,
      title: 'En yakın durak',
      value:
          '${nearest.stop.name} · '
          '${distanceText(nearest.distanceMeters!)}',
      onTap: () => openStopsPage(context, ref),
    );
  }
}
