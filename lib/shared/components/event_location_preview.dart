import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../models/feed_event.dart';

typedef EventMapPreviewBuilder =
    Widget Function(BuildContext context, double latitude, double longitude);

class EventLocationPreview extends StatelessWidget {
  final FeedEvent event;
  final VoidCallback? onTap;
  final EventMapPreviewBuilder? mapBuilder;

  const EventLocationPreview({
    super.key,
    required this.event,
    required this.onTap,
    this.mapBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preview = event.hasCoordinates
        ? (mapBuilder ?? _buildMap)(
            context,
            event.locationLatitude!,
            event.locationLongitude!,
          )
        : ColoredBox(
            color: colorScheme.surfaceContainer,
            child: Center(
              child: Icon(
                Icons.location_on_rounded,
                size: 40,
                color: colorScheme.secondary,
              ),
            ),
          );

    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: preview),
          if (onTap != null)
            PointerInterceptor(
              child: Semantics(
                label: 'Konumu haritada aç',
                button: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context, double latitude, double longitude) {
    final position = LatLng(latitude, longitude);
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: position, zoom: 16.5),
      markers: {
        Marker(
          markerId: const MarkerId('event-location-preview'),
          position: position,
        ),
      },
      liteModeEnabled:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
}
