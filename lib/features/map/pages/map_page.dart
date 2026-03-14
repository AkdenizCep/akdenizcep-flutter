import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  static const _akdenizCenter = LatLng(36.8969, 30.6364);

  static final _markers = <Marker>{
    const Marker(
      markerId: MarkerId('kampus'),
      position: _akdenizCenter,
      infoWindow: InfoWindow(title: 'Akdeniz Universitesi'),
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kampus Haritasi')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _akdenizCenter,
          zoom: 15,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
