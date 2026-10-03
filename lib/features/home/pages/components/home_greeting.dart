import 'package:flutter/material.dart';

import '../../../../shared/models/academic_calendar.dart';
import '../../models/day_part.dart';
import 'horizon_vignette.dart';

/// Ana sayfanın üstündeki sakin karşılama: saate göre selam, varsa yarıyıl
/// haftası ve sağda deniz ufku. Bilinçli olarak küçük, içerikle yarışmaz.
class HomeGreeting extends StatelessWidget {
  final String? firstName;
  final DateTime now;
  final TermProgress? termProgress;

  const HomeGreeting({
    super.key,
    required this.firstName,
    required this.now,
    required this.termProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = DayPart.at(now).greeting;
    final name = firstName?.trim();
    final title = name == null || name.isEmpty ? greeting : '$greeting, $name';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      // Sabit yükseklik yerine alt sınır: büyük yazı tipinde taşmasın.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: HorizonVignette.height),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.72,
                      ),
                    ),
                  ),
                  if (termProgress != null)
                    Text(
                      termProgress!.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            HorizonVignette(now: now),
          ],
        ),
      ),
    );
  }
}
