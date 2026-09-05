import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/route_key.dart';
import '../../models/route_shape.dart';
import '../../providers/ring_provider.dart';

/// Haritadaki hat ve yon secimini tek, kompakt bir kontrol olarak sunar.
///
/// Yonler iki buyuk segment yerine tek bir degistirme aksiyonundan gecerek
/// ekrandaki kalabaligi azaltir. Aktif yon hem "Gidis/Donus" hem de gercek
/// hedefiyle yazilir; yalnizca teknik yon adi kullaniciya birakilmaz.
class RouteMapFilters extends ConsumerWidget {
  final VoidCallback? onFilterChanged;

  const RouteMapFilters({super.key, this.onFilterChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(routeLineNamesProvider);
    final routes = ref.watch(activeRouteLineShapesProvider);
    if (lines.isEmpty || routes.isEmpty) return const SizedBox.shrink();

    final activeLine = ref.watch(activeRouteLineProvider);
    final activeDirection = ref.watch(activeRouteDirectionProvider);
    final activeRoute = routes.firstWhere(
      (route) => route.directionId == activeDirection,
      orElse: () => routes.first,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 190,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                // Material'in mobil icin onerilen minimum 48dp dokunma
                // hedefini korur; gorunen segment tum alani kullanir.
                height: 48,
                child: Row(
                  children: [
                    for (final line in lines)
                      Expanded(
                        child: _LineSegment(
                          label: line,
                          isActive: line == activeLine,
                          onTap: () {
                            if (line == activeLine) return;
                            onFilterChanged?.call();
                            ref.read(selectedRouteLineProvider.notifier).state =
                                line;
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (routes.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Divider(
                    height: 9,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                  ),
                ),
                _DirectionButton(
                  route: activeRoute,
                  onTap: () {
                    onFilterChanged?.call();
                    final currentIndex = routes.indexOf(activeRoute);
                    final next = routes[(currentIndex + 1) % routes.length];
                    ref.read(selectedRouteDirectionProvider.notifier).state =
                        next.directionId;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final RouteShape route;
  final VoidCallback onTap;

  const _DirectionButton({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final direction = isReturnFor(route.directionId) ? 'Dönüş' : 'Gidiş';
    final destination = _routeDestination(route);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Yön: $direction, $destination. Yönü değiştirmek için dokun.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    fit: FlexFit.loose,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(route.id),
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$direction yönü',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _routeDestination(RouteShape route) {
    final summary = route.label.split(' · ').last;
    return summary.replaceFirst(RegExp(r'\s+yönü$'), '');
  }
}

class _LineSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LineSegment({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
