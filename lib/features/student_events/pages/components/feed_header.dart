import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/components/app_top_bar.dart';
import '../../../../shared/providers/event_feed_provider.dart';

/// Sayfa başlığı: standart [AppTopBar] + altında açılıp kapanan arama alanı.
class FeedHeader extends ConsumerStatefulWidget {
  final VoidCallback onCreate;

  const FeedHeader({super.key, required this.onCreate});

  @override
  ConsumerState<FeedHeader> createState() => _FeedHeaderState();
}

class _FeedHeaderState extends ConsumerState<FeedHeader> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _searchOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);

    if (_searchOpen) {
      _focusNode.requestFocus();
    } else {
      _controller.clear();
      ref.read(feedSearchQueryProvider.notifier).state = '';
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppTopBar(
      title: 'Etkinlikler',
      actions: [
        AppTopBarAction.outlined(
          icon: _searchOpen ? Icons.close_rounded : Icons.search_rounded,
          tooltip: _searchOpen ? 'Aramayı kapat' : 'Ara',
          onTap: _toggleSearch,
        ),
        AppTopBarAction.filled(
          icon: Icons.add_rounded,
          tooltip: 'Etkinlik oluştur',
          onTap: widget.onCreate,
        ),
      ],
      bottom: _searchOpen
          ? TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  ref.read(feedSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Etkinlik, topluluk veya konum ara...',
                filled: true,
                fillColor: colorScheme.surface,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.4,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
