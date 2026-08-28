import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/academic_calendar.dart';
import '../providers/academic_calendar_provider.dart';
import 'components/academic_calendar_format.dart';
import 'components/campus_service_group.dart';

class AcademicCalendarPage extends ConsumerWidget {
  const AcademicCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestones = ref.watch(academicMilestonesProvider);
    final holidays = ref.watch(publicHolidaysProvider);
    final term = ref.watch(selectedAcademicTermProvider);
    final nextEvent = ref.watch(nextAcademicEventProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Akademik Takvim')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          132 + MediaQuery.of(context).padding.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nextEvent != null) _NextEventCard(event: nextEvent),
                const SizedBox(height: 24),
                _TermToggle(
                  selected: term,
                  onChanged: (value) => ref
                      .read(selectedAcademicTermProvider.notifier)
                      .state = value,
                ),
                const SizedBox(height: 14),
                _MilestoneList(milestones: milestones, term: term),
                const SizedBox(height: 28),
                const CampusSectionTitle(title: 'Resmî Tatiller ve Dini Bayramlar'),
                const SizedBox(height: 10),
                _HolidayList(holidays: holidays),
                const SizedBox(height: 24),
                const _SourceNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextEventCard extends StatelessWidget {
  final AcademicEvent event;

  const _NextEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final isOngoing = event.isOngoingOn(today);

    // Devam eden bir aralikta "kalan gun" hedefi bitis tarihidir (son gune
    // kadar bekleniyor); henuz baslamamis bir olayda ise baslangic tarihidir.
    final targetDate = isOngoing ? event.end! : event.date;
    final daysLeft = DateUtils.dateOnly(targetDate).difference(today).inDays;
    final isLastOrOnlyDay = daysLeft == 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: isLastOrOnlyDay
                ? Text(
                    isOngoing ? 'SON\nGÜN' : 'BUGÜN',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$daysLeft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        'gün',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOngoing ? 'ŞU AN DEVAM EDİYOR' : 'SIRADAKİ ÖNEMLİ TARİH',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isOngoing
                      ? formatAcademicRange(AcademicDateRange(event.date, event.end))
                      : formatShortDate(event.date),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermToggle extends StatelessWidget {
  final AcademicTerm selected;
  final ValueChanged<AcademicTerm> onChanged;

  const _TermToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: AcademicTerm.values.map((term) {
          final isSelected = term == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(term),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  term.label,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MilestoneList extends StatelessWidget {
  final List<AcademicMilestone> milestones;
  final AcademicTerm term;

  const _MilestoneList({required this.milestones, required this.term});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.56),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          children: [
            for (var i = 0; i < milestones.length; i++) ...[
              _MilestoneRow(milestone: milestones[i], term: term),
              if (i != milestones.length - 1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final AcademicMilestone milestone;
  final AcademicTerm term;

  const _MilestoneRow({required this.milestone, required this.term});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final range = term == AcademicTerm.fall ? milestone.fall : milestone.spring;
    final isOngoing =
        range != null && range.isRange && range.containsDay(DateTime.now());

    return Container(
      color: isOngoing
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : null,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.hasFootnote
                      ? '${milestone.title} *'
                      : milestone.title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.32,
                  ),
                ),
                if (isOngoing) ...[
                  const SizedBox(height: 3),
                  Text(
                    'ŞU AN DEVAM EDİYOR',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatAcademicRange(range),
            textAlign: TextAlign.right,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
              height: 1.32,
            ),
          ),
        ],
      ),
    );
  }
}

class _HolidayList extends StatelessWidget {
  final List<PublicHoliday> holidays;

  const _HolidayList({required this.holidays});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.56),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          children: [
            for (var i = 0; i < holidays.length; i++) ...[
              _HolidayRow(holiday: holidays[i]),
              if (i != holidays.length - 1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HolidayRow extends StatelessWidget {
  final PublicHoliday holiday;

  const _HolidayRow({required this.holiday});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 12),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatHolidayDate(holiday.date),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (holiday.halfDay) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'YARIM GÜN',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Kapsam',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bu takvim yarıyıllık eğitim veren birimler içindir. Tıp '
            'Fakültesi, Diş Hekimliği Fakültesi ve Hukuk Fakültesi kendi '
            'yıllık akademik takvimlerini ayrıca yayınlar; bu birimlerdeki '
            'öğrenciler kendi fakültelerinin duyurularını takip etmelidir.\n\n'
            '* Öğrenci sayılarına göre OBS\'de işlem yapılarak Rektörlüğe '
            'bildirilir.\n\n'
            'Kaynak: Akdeniz Üniversitesi 2026-2027 Eğitim Öğretim Yılı '
            'Akademik Takvimi.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
