import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/utils/error_message.dart';
import '../models/attendance_record.dart';
import '../providers/community_provider.dart';

/// QR ile alınan katılımcı yoklama listesi — yalnızca kulüp yöneticisi/üyesi
/// bu adrese erişebilir (Firestore kuralları `isClubAdmin` şartını koyar).
class EventAttendanceListPage extends ConsumerWidget {
  final String clubId;
  final String eventId;

  const EventAttendanceListPage({
    super.key,
    required this.clubId,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(
      eventAttendanceProvider((clubId: clubId, eventId: eventId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katılımcılar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: attendanceAsync.when(
        data: (records) => _AttendanceList(records: records),
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
    );
  }
}

class _AttendanceList extends StatelessWidget {
  final List<AttendanceRecord> records;

  const _AttendanceList({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const _EmptyAttendanceView();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: records.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${records.length} katılımcı',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final record = records[index - 1];
        return _AttendanceRow(record: record);
      },
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final AttendanceRecord record;

  const _AttendanceRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                record.name.isNotEmpty ? record.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.studentId,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              DateFormat('HH:mm', 'tr').format(record.checkedInAt),
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAttendanceView extends StatelessWidget {
  const _EmptyAttendanceView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: colorScheme.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz kimse okutmadı.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Kapıda QR okutuldukça katılımcılar burada görünecek.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
