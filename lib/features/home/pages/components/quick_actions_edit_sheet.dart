import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/quick_action.dart';
import 'quick_action_style.dart';

/// Hızlı erişim seçimini düzenleyen alt sayfa. Kaydedilirse yeni sıralı listeyi,
/// kaydetmeden kapatılırsa null döner.
Future<List<QuickAction>?> showQuickActionsEditSheet(
  BuildContext context,
  List<QuickAction> current,
) {
  return showModalBottomSheet<List<QuickAction>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => QuickActionsEditSheet(current: current),
  );
}

/// Seçili kısayolları sıralar/çıkarır, katalogdaki diğerlerini ekletir.
///
/// Izgara her zaman tam [kQuickActionSlotCount] öğe olmak zorunda olduğu için
/// "Kaydet" yalnızca liste doluyken açılır. Düzenleme sheet'e özel bir taslak
/// üzerinde yapılır; kaydedilmeden kapatılırsa seçim değişmez.
class QuickActionsEditSheet extends StatefulWidget {
  final List<QuickAction> current;

  const QuickActionsEditSheet({super.key, required this.current});

  @override
  State<QuickActionsEditSheet> createState() => _QuickActionsEditSheetState();
}

class _QuickActionsEditSheetState extends State<QuickActionsEditSheet> {
  late List<QuickAction> _draft;

  @override
  void initState() {
    super.initState();
    _draft = [...widget.current];
  }

  bool get _isFull => _draft.length == kQuickActionSlotCount;

  List<QuickAction> get _available => [
    for (final action in QuickAction.values)
      if (!_draft.contains(action)) action,
  ];

  void _remove(QuickAction action) => setState(() => _draft.remove(action));

  void _add(QuickAction action) {
    if (_isFull) return;
    setState(() => _draft.add(action));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      // ReorderableListView, öğe kaldırılmadan önceki hedef indeksi verir.
      if (newIndex > oldIndex) newIndex -= 1;
      _draft.insert(newIndex, _draft.removeAt(oldIndex));
    });
  }

  void _resetToDefaults() {
    setState(() => _draft = [...kDefaultQuickActions]);
  }

  void _save() => Navigator.of(context).pop(List<QuickAction>.of(_draft));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final available = _available;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hızlı Erişimi Düzenle',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ana sayfada görünecek $kQuickActionSlotCount kısayolu '
                    'seç ve sırala.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _SectionLabel(
                        'Seçili (${_draft.length}/$kQuickActionSlotCount)',
                      ),
                      if (!_isFull) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$kQuickActionSlotCount kısayol seçmelisin',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: _reorder,
                    proxyDecorator: _liftedRow,
                    children: [
                      for (var index = 0; index < _draft.length; index++)
                        _SelectedRow(
                          key: ValueKey('selected-${_draft[index].name}'),
                          action: _draft[index],
                          index: index,
                          onRemove: () => _remove(_draft[index]),
                        ),
                    ],
                  ),
                  if (available.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _SectionLabel('Eklenebilir'),
                    const SizedBox(height: 4),
                    for (final action in available)
                      _AvailableRow(
                        key: ValueKey('available-${action.name}'),
                        action: action,
                        onAdd: _isFull ? null : () => _add(action),
                      ),
                  ],
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _resetToDefaults,
                          icon: const FaIcon(
                            FontAwesomeIcons.rotateLeft,
                            size: 14,
                          ),
                          label: const Text(
                            'Varsayılana dön',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isFull ? _save : null,
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sürüklenen satırın yuvarlak köşelerini izleyen gölge.
  Widget _liftedRow(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Material(
        color: Colors.transparent,
        elevation: 6 * Curves.easeInOut.transform(animation.value),
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final QuickAction action;

  const _ActionIcon(this.action);

  @override
  Widget build(BuildContext context) {
    final accent = action.accent(Theme.of(context).colorScheme);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: FaIcon(action.icon, size: 16, color: accent)),
    );
  }
}

class _ActionText extends StatelessWidget {
  final QuickAction action;

  const _ActionText(this.action);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          action.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          action.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SelectedRow extends StatelessWidget {
  final QuickAction action;
  final int index;
  final VoidCallback onRemove;

  const _SelectedRow({
    super.key,
    required this.action,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
          child: Row(
            children: [
              _ActionIcon(action),
              const SizedBox(width: 12),
              Expanded(child: _ActionText(action)),
              IconButton(
                key: ValueKey('remove-${action.name}'),
                tooltip: 'Çıkar',
                onPressed: onRemove,
                icon: FaIcon(
                  FontAwesomeIcons.circleMinus,
                  size: 18,
                  color: colorScheme.error,
                ),
              ),
              ReorderableDragStartListener(
                key: ValueKey('drag-${action.name}'),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.gripVertical,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailableRow extends StatelessWidget {
  final QuickAction action;

  /// Izgara doluyken null: ekle butonu pasif görünür.
  final VoidCallback? onAdd;

  const _AvailableRow({super.key, required this.action, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
          child: Row(
            children: [
              _ActionIcon(action),
              const SizedBox(width: 12),
              Expanded(child: _ActionText(action)),
              IconButton(
                key: ValueKey('add-${action.name}'),
                tooltip: 'Ekle',
                onPressed: onAdd,
                icon: FaIcon(
                  FontAwesomeIcons.plus,
                  size: 16,
                  color: onAdd == null ? null : colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
