import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/quick_action.dart';
import 'quick_action_style.dart';

const _columns = 3;
const _gap = 12.0;

/// Ana sayfadaki "Hızlı Erişim" bölümü: başlık, "Düzenle" bağlantısı ve 3
/// sütunlu kısayol ızgarası.
///
/// Yalnızca sunum yapar; seçimi okumaz, dokunuşu yorumlamaz. Bunlar çağıran
/// tarafın işidir ([onSelected], [onEdit]).
class QuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;
  final ValueChanged<QuickAction> onSelected;
  final VoidCallback onEdit;

  const QuickActionsGrid({
    super.key,
    required this.actions,
    required this.onSelected,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Sabit en-boy oranı yerine satır başına IntrinsicHeight: büyük yazı
    // boyutunda ya da dar ekranda iki satıra inen başlıklar taşma yapmaz.
    final rows = <Widget>[];
    for (var start = 0; start < actions.length; start += _columns) {
      if (start > 0) rows.add(const SizedBox(height: _gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var col = 0; col < _columns; col++) ...[
                if (col > 0) const SizedBox(width: _gap),
                Expanded(
                  child: start + col < actions.length
                      ? _QuickActionCard(
                          action: actions[start + col],
                          onTap: () => onSelected(actions[start + col]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Hızlı Erişim',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(onPressed: onEdit, child: const Text('Düzenle')),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  static const _titleFontSize = 13.0;
  static const _titleLineHeight = 1.25;

  final QuickAction action;
  final VoidCallback onTap;

  const _QuickActionCard({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = action.accent(colorScheme);
    // Başlık alanı her zaman iki satırlık yer ayırır; tek satırlık başlıklı
    // kartlar da aynı boyda kalır ve ızgara düzgün durur.
    final titleMinHeight =
        MediaQuery.textScalerOf(context).scale(_titleFontSize) *
        _titleLineHeight *
        2;

    return Semantics(
      button: true,
      label: action.title,
      hint: action.description,
      excludeSemantics: true,
      child: Card(
        key: ValueKey('quick-action-${action.name}'),
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: FaIcon(action.icon, size: 19, color: accent),
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: titleMinHeight),
                  child: Center(
                    child: Text(
                      action.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: _titleFontSize,
                        height: _titleLineHeight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
