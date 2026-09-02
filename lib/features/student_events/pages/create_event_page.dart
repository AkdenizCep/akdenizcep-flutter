import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../shared/components/category_dropdown_field.dart';
import '../../../shared/components/progress_snackbar.dart';
import '../../../shared/models/club_option.dart';
import '../../../shared/providers/event_feed_provider.dart';
import '../../../shared/providers/nav_visibility_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/event_category.dart';
import '../providers/student_events_provider.dart';
import 'event_location_picker_page.dart';

/// Ekran 1f — etkinlik oluşturma.
class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage>
    with HidesBottomNav {
  static const _maxTitleLength = 80;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quotaController = TextEditingController(text: '30');

  ClubOption? _selectedClub;
  File? _coverImage;
  DateTime? _date;
  TimeOfDay? _time;
  EventLocationSelection? _selectedLocation;
  String _categoryId = EventCategory.technology.id;
  bool _hasQuota = false;
  bool _qrAttendance = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _titleController.text.trim().isNotEmpty &&
      _selectedLocation != null &&
      _date != null &&
      _time != null;

  DateTime get _eventDateTime => DateTime(
    _date!.year,
    _date!.month,
    _date!.day,
    _time!.hour,
    _time!.minute,
  );

  Future<void> _pickCover() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _coverImage = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      showProgressSnackBar(
        context,
        message: errorMessage(e),
        icon: Icons.error_outline_rounded,
        accentColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('tr'),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _time = time);
  }

  Future<void> _pickLocation() async {
    final selection = await context.push<EventLocationSelection>(
      '/student-events/create/location',
    );
    if (selection != null && mounted) {
      setState(() => _selectedLocation = selection);
    }
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || !_canSubmit) return;

    setState(() => _submitting = true);
    try {
      var imageUrl = '';
      if (_coverImage != null) {
        imageUrl = await CloudinaryService().uploadImage(
          file: _coverImage!,
          folder: 'event-covers/${user.id}',
        );
      }

      final capacity = _hasQuota
          ? int.tryParse(_quotaController.text.trim())
          : null;
      final club = _selectedClub;
      final location = _selectedLocation!;

      if (club != null) {
        await ref
            .read(eventFeedServiceProvider)
            .createClubEvent(
              clubId: club.id,
              adminUid: user.id,
              title: _titleController.text.trim(),
              date: _eventDateTime,
              location: location.title,
              locationLatitude: location.latitude,
              locationLongitude: location.longitude,
              description: _descriptionController.text.trim(),
              category: _categoryId,
              imageUrl: imageUrl,
              capacity: capacity,
              qrAttendance: _qrAttendance,
            );
      } else {
        await ref
            .read(studentEventsServiceProvider)
            .createEvent(
              authorUid: user.id,
              authorName: user.name,
              title: _titleController.text.trim(),
              date: _eventDateTime,
              location: location.title,
              locationLatitude: location.latitude,
              locationLongitude: location.longitude,
              description: _descriptionController.text.trim(),
              category: _categoryId,
              imageUrl: imageUrl,
              capacity: capacity,
            );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        showProgressSnackBar(
          context,
          message: errorMessage(e),
          icon: Icons.error_outline_rounded,
          accentColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final adminClubs =
        ref.watch(adminClubsProvider).valueOrNull ?? const <ClubOption>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(onClose: () => context.pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (adminClubs.isNotEmpty) ...[
                          const _SectionLabel('KİMİN ADINA'),
                          const SizedBox(height: 10),
                          _AuthorModeRow(
                            clubs: adminClubs,
                            selectedClub: _selectedClub,
                            onChanged: (club) => setState(() {
                              _selectedClub = club;
                              if (club == null) _qrAttendance = false;
                            }),
                          ),
                          const SizedBox(height: 22),
                        ],
                        _CoverPicker(
                          image: _coverImage,
                          onTap: _pickCover,
                          onClear: () => setState(() => _coverImage = null),
                        ),
                        const SizedBox(height: 22),
                        const _FieldLabel('Başlık'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          maxLength: _maxTitleLength,
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(_maxTitleLength),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Etkinliğin adı',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_titleController.text.characters.length}'
                            ' / $_maxTitleLength',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _PickerField(
                                icon: Icons.calendar_month_rounded,
                                value: _date == null
                                    ? 'Tarih seç'
                                    : DateFormat(
                                        'd MMMM yyyy',
                                        'tr',
                                      ).format(_date!),
                                placeholder: _date == null,
                                onTap: _pickDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PickerField(
                                icon: Icons.schedule_rounded,
                                value: _time == null
                                    ? 'Saat seç'
                                    : _time!.format(context),
                                placeholder: _time == null,
                                onTap: _pickTime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('Konum'),
                        const SizedBox(height: 8),
                        _LocationPickerField(
                          selection: _selectedLocation,
                          onTap: _pickLocation,
                        ),
                        const SizedBox(height: 22),
                        const _SectionLabel('KATEGORİ'),
                        const SizedBox(height: 10),
                        CategoryDropdownField(
                          items: EventCategory.selectableItems,
                          value: EventCategory.selectableItems.firstWhere(
                            (c) => c.id == _categoryId,
                            orElse: () => EventCategory.selectableItems.first,
                          ),
                          onChanged: (category) =>
                              setState(() => _categoryId = category.id),
                        ),
                        const SizedBox(height: 22),
                        const _FieldLabel('Açıklama'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            hintText:
                                'Etkinliği birkaç cümleyle anlat: kimler '
                                'katılabilir, ne getirmeli?',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _QuotaCard(
                          enabled: _hasQuota,
                          controller: _quotaController,
                          onChanged: (value) =>
                              setState(() => _hasQuota = value),
                        ),
                        if (_selectedClub != null) ...[
                          const SizedBox(height: 14),
                          _QrAttendanceCard(
                            enabled: _qrAttendance,
                            onChanged: (value) =>
                                setState(() => _qrAttendance = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _SubmitBar(
                enabled: _canSubmit,
                submitting: _submitting,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;

  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kapat',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 24),
          ),
          Expanded(
            child: Text(
              'Etkinlik Oluştur',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.48,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _LocationPickerField extends StatelessWidget {
  final EventLocationSelection? selection;
  final VoidCallback onTap;

  const _LocationPickerField({required this.selection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = selection != null;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.location_on_rounded
                    : Icons.add_location_alt_rounded,
                color: selected
                    ? colorScheme.secondary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      selected ? selection!.title : 'Haritadan konum seç',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        color: selected
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Değiştirmek için dokun',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorModeRow extends StatelessWidget {
  final List<ClubOption> clubs;
  final ClubOption? selectedClub;
  final ValueChanged<ClubOption?> onChanged;

  const _AuthorModeRow({
    required this.clubs,
    required this.selectedClub,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AuthorModeOption(
            icon: Icons.person_rounded,
            label: 'Kendi adıma',
            selected: selectedClub == null,
            onTap: () => onChanged(null),
          ),
        ),
        for (final club in clubs) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _AuthorModeOption(
              icon: Icons.groups_2_rounded,
              label: club.name,
              selected: selectedClub?.id == club.id,
              onTap: () => onChanged(club),
            ),
          ),
        ],
      ],
    );
  }
}

class _AuthorModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AuthorModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: selected ? colorScheme.primaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: foreground,
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

class _CoverPicker extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _CoverPicker({
    required this.image,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              image!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.42),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onClear,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: colorScheme.outline),
        child: Container(
          height: 150,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_rounded,
                size: 30,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Kapak görseli ekle',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'önerilen 1200 × 800 · opsiyonel',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 6).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool placeholder;
  final VoidCallback onTap;

  const _PickerField({
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: placeholder
                        ? colorScheme.outline
                        : colorScheme.onSurface,
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

class _QuotaCard extends StatelessWidget {
  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<bool> onChanged;

  const _QuotaCard({
    required this.enabled,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontenjan sınırı',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Katılımcı sayısını sınırla',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Kontenjan',
                hintText: 'Örn. 60',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QrAttendanceCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _QrAttendanceCard({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR ile katılımcı kaydı',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kapıda öğrenci QR\'ı okutarak yoklama al',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 10),
            Text(
              'Etkinlik sayfasında yalnızca topluluk yöneticileri ve üyeleri '
              'için bir tarayıcı butonu görünür.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;

  const _SubmitBar({
    required this.enabled,
    required this.submitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            background,
            background.withValues(alpha: 0.62),
            Colors.transparent,
          ],
        ),
      ),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: submitting
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.campaign_rounded, size: 22),
          label: Text(submitting ? 'Paylaşılıyor...' : 'Etkinliği Paylaş'),
        ),
      ),
    );
  }
}
