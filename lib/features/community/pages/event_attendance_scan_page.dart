import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/components/app_top_bar.dart';
import '../../../shared/providers/nav_visibility_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/student_qr.dart';
import '../models/attendance_record.dart';
import '../providers/community_provider.dart';

enum _ScanResultType { success, duplicate, notFound, error }

class _ScanResult {
  final _ScanResultType type;
  final String? name;
  final String? studentId;
  final DateTime? checkedInAt;
  final String? message;

  const _ScanResult._({
    required this.type,
    this.name,
    this.studentId,
    this.checkedInAt,
    this.message,
  });

  factory _ScanResult.success({required String name, required String studentId}) =>
      _ScanResult._(type: _ScanResultType.success, name: name, studentId: studentId);

  factory _ScanResult.duplicate({
    required String name,
    required String studentId,
    required DateTime checkedInAt,
  }) => _ScanResult._(
    type: _ScanResultType.duplicate,
    name: name,
    studentId: studentId,
    checkedInAt: checkedInAt,
  );

  factory _ScanResult.notFound(String rawValue) =>
      _ScanResult._(type: _ScanResultType.notFound, studentId: rawValue);

  factory _ScanResult.error(String message) =>
      _ScanResult._(type: _ScanResultType.error, message: message);
}

/// Etkinlik kapısında QR okutarak yoklama alma ekranı — yalnızca kulüp
/// yöneticisi/üyesi tarafından açılır (yetki kontrolü çağıran sayfada yapılır).
class EventAttendanceScanPage extends ConsumerStatefulWidget {
  final String clubId;
  final String eventId;

  const EventAttendanceScanPage({
    super.key,
    required this.clubId,
    required this.eventId,
  });

  @override
  ConsumerState<EventAttendanceScanPage> createState() =>
      _EventAttendanceScanPageState();
}

class _EventAttendanceScanPageState
    extends ConsumerState<EventAttendanceScanPage> with HidesBottomNav {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final rawValue = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    final studentId = decodeStudentQr(rawValue);
    if (studentId == null) return;

    setState(() => _busy = true);
    await _controller.stop();

    final result = await _lookUpAndRecord(studentId);
    if (!mounted) return;
    await _showResult(result);

    if (!mounted) return;
    setState(() => _busy = false);
    await _controller.start();
  }

  Future<_ScanResult> _lookUpAndRecord(String studentId) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      return _ScanResult.error('Oturum bulunamadı.');
    }

    final service = ref.read(communityServiceProvider);
    try {
      final student = await service.findStudentByNumber(studentId);
      if (student == null) return _ScanResult.notFound(studentId);

      final existing = await service.getAttendanceRecord(
        clubId: widget.clubId,
        eventId: widget.eventId,
        uid: student.uid,
      );
      if (existing != null) {
        return _ScanResult.duplicate(
          name: existing.name,
          studentId: existing.studentId,
          checkedInAt: existing.checkedInAt,
        );
      }

      await service.recordAttendance(
        clubId: widget.clubId,
        eventId: widget.eventId,
        record: AttendanceRecord(
          uid: student.uid,
          name: student.name,
          studentId: student.studentId,
          checkedInAt: DateTime.now(),
          recordedBy: currentUser.id,
        ),
      );
      return _ScanResult.success(name: student.name, studentId: student.studentId);
    } catch (e) {
      return _ScanResult.error(errorMessage(e));
    }
  }

  Future<void> _showResult(_ScanResult result) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScanResultSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const _ScanOverlay(),
          SafeArea(
            child: AppTopBar(
              title: 'QR Okut',
              onGradient: true,
              actions: [
                AppTopBarAction.translucent(
                  icon: Icons.close_rounded,
                  tooltip: 'Kapat',
                  onTap: () => context.pop(),
                ),
                AppTopBarAction.translucent(
                  icon: Icons.groups_rounded,
                  tooltip: 'Katılımcılar',
                  onTap: () => context.push(
                    '/club/${widget.clubId}/event/${widget.eventId}/attendance',
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

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Öğrencinin QR kodunu çerçeveye getir',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanResultSheet extends StatelessWidget {
  final _ScanResult result;

  const _ScanResultSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (icon, color, title, subtitle) = switch (result.type) {
      _ScanResultType.success => (
        Icons.check_circle_rounded,
        colorScheme.primary,
        result.name ?? '',
        'Kayıt alındı · ${result.studentId ?? ''}',
      ),
      _ScanResultType.duplicate => (
        Icons.info_rounded,
        colorScheme.tertiary,
        result.name ?? '',
        'Zaten kayıtlı · '
            '${result.checkedInAt != null ? DateFormat('HH:mm', 'tr').format(result.checkedInAt!) : ''}',
      ),
      _ScanResultType.notFound => (
        Icons.person_off_rounded,
        colorScheme.error,
        'Öğrenci bulunamadı',
        result.studentId ?? '',
      ),
      _ScanResultType.error => (
        Icons.error_outline_rounded,
        colorScheme.error,
        'Bir hata oluştu',
        result.message ?? '',
      ),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          10,
          24,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Bitti',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
