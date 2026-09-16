import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/swipe_down_image_viewer.dart';
import '../models/feed_event.dart';
import '../providers/event_feed_provider.dart';
import '../utils/error_message.dart';

String eventImageHeroTag(EventRef ref) =>
    'event-image-${ref.source.name}-${ref.clubId ?? 'student'}-${ref.eventId}';

class EventImageViewerPage extends ConsumerWidget {
  final EventRef eventRef;

  const EventImageViewerPage({super.key, required this.eventRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventRef));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: eventAsync.when(
        data: (event) => event.imageUrl.isEmpty
            ? const _ViewerMessage(text: 'Etkinlik görseli bulunamadı.')
            : SwipeDownImageViewer(
                onDismiss: () => Navigator.of(context).pop(),
                child: Center(
                  child: Hero(
                    tag: eventImageHeroTag(eventRef),
                    child: CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (error, _) => _ViewerMessage(text: errorMessage(error)),
      ),
    );
  }
}

class _ViewerMessage extends StatelessWidget {
  final String text;

  const _ViewerMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
