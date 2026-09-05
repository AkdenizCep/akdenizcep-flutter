import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/nav_visibility_provider.dart';
import 'open_stops_page.dart';
import 'stop_detail_sheet.dart';

enum _StopDetailResult { showOnMap }

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
  _StopDetailResult? result;
  try {
    result = await showModalBottomSheet<_StopDetailResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => StopDetailSheet(
        stopId: stopId,
        onShowOnMap: () =>
            Navigator.of(sheetContext).pop(_StopDetailResult.showOnMap),
      ),
    );
  } finally {
    ref.read(bottomNavVisibleProvider.notifier).state = true;
  }

  if (result == _StopDetailResult.showOnMap && context.mounted) {
    openStopsPage(context, ref, focusStopId: stopId);
  }
}
