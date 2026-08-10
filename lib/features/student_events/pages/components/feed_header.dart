import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/event_feed_provider.dart';

/// 2a başlık bloğu: solda iki satır başlık, sağda arama tetikleyicisi.
/// Tetikleyiciye dokununca altında tam genişlik arama alanı açılır.
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KATEGORİLER',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.72,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Etkinlikler',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SearchTrigger(active: _searchOpen, onTap: _toggleSearch),
              const SizedBox(width: 8),
              _CreateTrigger(onTap: widget.onCreate),
            ],
          ),
          if (_searchOpen) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  ref.read(feedSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Etkinlik, kulüp veya konum ara...',
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
            ),
          ],
        ],
      ),
    );
  }
}

/// Etkinlik oluşturma girişi — FAB yerine üst barda durur.
class _CreateTrigger extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateTrigger({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Etkinlik oluştur',
      child: Material(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.add_rounded,
              size: 24,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchTrigger extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _SearchTrigger({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.close_rounded : Icons.search_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                active ? 'Kapat' : 'Ara',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
