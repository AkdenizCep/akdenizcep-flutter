import 'package:flutter/material.dart';

class RateMealSheet extends StatefulWidget {
  final void Function(int rating, String comment) onSubmit;

  const RateMealSheet({super.key, required this.onSubmit});

  @override
  State<RateMealSheet> createState() => _RateMealSheetState();
}

class _RateMealSheetState extends State<RateMealSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bugünün menüsünü puanla',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return IconButton(
                  iconSize: 34,
                  icon: Icon(
                    Icons.star_rounded,
                    color: i < _rating
                        ? colorScheme.secondary
                        : colorScheme.outlineVariant,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLength: 300,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Yorumunuzu yazın (opsiyonel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating == 0
                  ? null
                  : () {
                      widget.onSubmit(_rating, _commentController.text.trim());
                      Navigator.of(context).pop();
                    },
              child: const Text('Gönder'),
            ),
          ),
        ],
      ),
    );
  }
}
