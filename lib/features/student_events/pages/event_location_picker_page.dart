import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

typedef EventLocationSelection = ({
  String title,
  double latitude,
  double longitude,
});

class EventLocationPickerPage extends StatefulWidget {
  const EventLocationPickerPage({super.key});

  @override
  State<EventLocationPickerPage> createState() =>
      _EventLocationPickerPageState();
}

class _EventLocationPickerPageState extends State<EventLocationPickerPage> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(36.8969, 30.6512),
    zoom: 15.4,
  );

  final _titleController = TextEditingController();
  LatLng? _selectedPosition;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _selectPosition(LatLng position) {
    FocusScope.of(context).unfocus();
    setState(() => _selectedPosition = position);
  }

  void _complete() {
    final position = _selectedPosition;
    final title = _titleController.text.trim();
    if (position == null || title.isEmpty) return;

    context.pop<EventLocationSelection>((
      title: title,
      latitude: position.latitude,
      longitude: position.longitude,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final position = _selectedPosition;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onTap: _selectPosition,
            markers: position == null
                ? const <Marker>{}
                : {
                    Marker(
                      markerId: const MarkerId('event-location'),
                      position: position,
                    ),
                  },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 72,
              bottom: position == null ? 130 : 244,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: PointerInterceptor(
                child: Material(
                  color: colorScheme.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Geri',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'Etkinlik Konumu',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: PointerInterceptor(
                child: Material(
                  color: colorScheme.surface,
                  elevation: 3,
                  shadowColor: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                position == null
                                    ? Icons.touch_app_rounded
                                    : Icons.location_on_rounded,
                                color: position == null
                                    ? colorScheme.primary
                                    : colorScheme.secondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      position == null
                                          ? 'Haritada bir noktaya dokun'
                                          : 'Konum seçildi',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      position == null
                                          ? 'Etkinliğin yapılacağı yeri işaretle.'
                                          : 'Şimdi katılımcıların göreceği başlığı gir.',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (position != null) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _titleController,
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _complete(),
                              decoration: const InputDecoration(
                                labelText: 'Konum başlığı',
                                hintText: 'Örn. Mühendislik Fakültesi B Blok',
                                prefixIcon: Icon(
                                  Icons.edit_location_alt_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _titleController.text.trim().isEmpty
                                    ? null
                                    : _complete,
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Konumu kullan'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
