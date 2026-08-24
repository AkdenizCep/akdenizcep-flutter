import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/nav_visibility_provider.dart';
import 'stop_detail_sheet.dart';

/// Durak yapragini acar. Uc ekrandan da (ana ekran, harita, favori yapragi)
/// buradan gecilir — nav bar gizleme/gosterme kalibi tek yerde kalsin diye.
///
/// `finally` blogu onemli: yaprak nasil kapanirsa kapansin (surukleme, geri
/// tusu, disariya dokunma) nav bar geri gelmelidir.
Future<void> openStopDetail(
  BuildContext context,
  WidgetRef ref,
  String stopId,
) async {
  ref.read(bottomNavVisibleProvider.notifier).state = false;
  try {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StopDetailSheet(stopId: stopId),
    );
  } finally {
    ref.read(bottomNavVisibleProvider.notifier).state = true;
  }
}
