import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tarih secimi icin alt sayfa.
///
/// Sayfanin geri kalani (bilgi, puanlama, tarife) alt sayfa kullaniyor;
/// ortada acilan Material diyalogu sistem penceresi gibi durup ekrandan
/// kopuyordu. Takvim izgarasinin kendisi yine [CalendarDatePicker] — ay
/// gecisleri, yerellestirilmis gun adlari ve haftanin ilk gunu Flutter'in
/// islevidir, yeniden yazilmasi hataya acik olurdu. Degisen yalnizca kabuk.
class CafeteriaDateSheet extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CafeteriaDateSheet({
    super.key,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
  });

  /// Secilen tarihi doner; kullanici kapatirsa `null`.
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime selectedDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CafeteriaDateSheet(
        selectedDate: selectedDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final canJumpToToday =
        !DateUtils.isSameDay(selectedDate, today) &&
        !today.isBefore(firstDate) &&
        !today.isAfter(lastDate);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TARİH SEÇ',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat(
                          'd MMMM yyyy, EEEE',
                          'tr',
                        ).format(selectedDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canJumpToToday)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(today),
                    child: const Text('Bugün'),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          // CalendarDatePicker kendi yuksekligini sinirlamaz; alt sayfa
          // icinde sabit bir alan verilmezse tasar.
          SizedBox(
            height: 340,
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: firstDate,
              lastDate: lastDate,
              onDateChanged: (date) => Navigator.of(context).pop(date),
            ),
          ),
        ],
      ),
    );
  }
}
