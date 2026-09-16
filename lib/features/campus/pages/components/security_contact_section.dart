import 'package:flutter/material.dart';

/// Shared card rhythm for every section of the security directory.
class SecurityContactSection extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;
  final bool urgent;

  const SecurityContactSection({
    super.key,
    required this.title,
    required this.description,
    required this.children,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(description, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: urgent
              ? (theme.brightness == Brightness.dark
                    ? colors.errorContainer
                    : colors.error)
              : null,
          shape: urgent
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colors.outlineVariant.withValues(alpha: 0.62),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The same label, detail and action alignment for direct and internal lines.
class SecurityContactTile extends StatelessWidget {
  final String title;
  final String detail;
  final String? note;
  final VoidCallback? onCall;
  final bool urgent;

  const SecurityContactTile({
    super.key,
    required this.title,
    required this.detail,
    this.note,
    this.onCall,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = urgent ? colors.error : colors.primary;
    final urgentForeground = theme.brightness == Brightness.dark
        ? colors.onErrorContainer
        : colors.onError;

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: urgent ? urgentForeground : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: urgent
                        ? urgentForeground
                        : onCall == null
                        ? colors.onSurfaceVariant
                        : accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: urgent
                          ? urgentForeground.withValues(alpha: 0.85)
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onCall != null) ...[
            const SizedBox(width: 12),
            ExcludeSemantics(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: urgent
                      ? urgentForeground
                      : accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.phone_outlined,
                  color: urgent && theme.brightness == Brightness.dark
                      ? colors.errorContainer
                      : accent,
                  size: 22,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onCall == null) return content;

    return Semantics(
      button: true,
      label: '$title, $detail${note == null ? '' : ', $note'}',
      hint: 'Arama uygulamasını aç',
      onTap: onCall,
      excludeSemantics: true,
      child: Tooltip(
        message: '$title ara',
        child: InkWell(onTap: onCall, child: content),
      ),
    );
  }
}
