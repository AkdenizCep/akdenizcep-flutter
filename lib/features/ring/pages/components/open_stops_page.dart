import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers/location_provider.dart';
import '../../providers/ring_provider.dart';

/// "Yakındaki Duraklar" sayfasini acar

void openStopsPage(BuildContext context, WidgetRef ref, {String? focusStopId}) {

  final locator = ref.read(userPositionProvider.notifier);
  final hasLocation = ref.read(userPositionProvider) != null;

  if (focusStopId != null) {
    final stop = ref.read(ringStopMapProvider)[focusStopId];

    ref.read(stopQueryProvider.notifier).state = '';
    ref.read(selectedStopProvider.notifier).state = focusStopId;
    if (stop != null && stop.lineNames.isNotEmpty) {
      final activeLine = ref.read(activeRouteLineProvider);
      final activeDirection = ref.read(activeRouteDirectionProvider);
      final line = activeLine != null && stop.servesLine(activeLine)
          ? activeLine
          : stop.lineNames.first;
      ref.read(selectedRouteLineProvider.notifier).state = line;

      final services = stop.servedBy.where(
        (service) => service.shortName == line,
      );
      if (services.isNotEmpty) {
        ref.read(selectedRouteDirectionProvider.notifier).state =
            activeDirection != null && stop.servesRoute(line, activeDirection)
            ? activeDirection
            : services.first.directionId;
      }
    }
  }

  final location = Uri(
    path: '/ring/stops',
    queryParameters: focusStopId == null ? null : {'stop': focusStopId},
  );
  context.go(location.toString());
  if (!hasLocation) locator.request();
}
