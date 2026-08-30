import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/components/category_dropdown_field.dart';
import '../../../shared/components/photo_source_sheet.dart';
import '../../../shared/components/progress_snackbar.dart';
import '../../../shared/providers/nav_visibility_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../../shared/utils/error_message.dart';
import '../models/lost_found_category.dart';
import '../providers/lost_found_provider.dart';

class CreateLostFoundItemPage extends ConsumerStatefulWidget {
  const CreateLostFoundItemPage({super.key});

  @override
  ConsumerState<CreateLostFoundItemPage> createState() =>
      _CreateLostFoundItemPageState();
}

class _CreateLostFoundItemPageState
    extends ConsumerState<CreateLostFoundItemPage>
    with HidesBottomNav {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  String _type = 'kayip';
  LostFoundCategory _category = LostFoundCategory.other;
  File? _photo;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _titleController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty;

  Future<void> _pickPhoto() async {
    final source = await choosePhotoSource(context);
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _photo = File(picked.path));
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

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || !_canSubmit) return;

    setState(() => _submitting = true);
    try {
      var imageUrl = '';
      if (_photo != null) {
        imageUrl = await CloudinaryService().uploadImage(
          file: _photo!,
          folder: 'lost-found/${user.id}',
        );
      }

      await ref
          .read(lostFoundServiceProvider)
          .createItem(
            authorUid: user.id,
            authorName: user.name,
            type: _type,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category.id,
            location: _locationController.text.trim(),
            imageUrl: imageUrl,
            contactPhone: _phoneController.text.trim(),
          );

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
                        const _SectionLabel('İLAN TÜRÜ'),
                        const SizedBox(height: 10),
                        _TypeToggle(
                          type: _type,
                          onChanged: (type) => setState(() => _type = type),
                        ),
                        const SizedBox(height: 22),
                        _PhotoPicker(
                          image: _photo,
                          onTap: _pickPhoto,
                          onClear: () => setState(() => _photo = null),
                        ),
                        const SizedBox(height: 22),
                        const _FieldLabel('Ne'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Örn. Siyah cüzdan',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _SectionLabel('KATEGORİ'),
                        const SizedBox(height: 10),
                        CategoryDropdownField<LostFoundCategory>(
                          items: LostFoundCategory.all,
                          value: _category,
                          onChanged: (category) =>
                              setState(() => _category = category),
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel(
                          _type == 'kayip' ? 'Nerede kaybettin' : 'Nerede buldun',
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _locationController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.location_on_rounded),
                            hintText: 'Örn. Mühendislik Fakültesi kantini',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('Açıklama'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText:
                                'Ayırt edici bir detay ekle: renk, marka, '
                                'üstünde ne yazıyor...',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('İletişim telefonu (opsiyonel)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '05xx xxx xx xx',
                          ),
                        ),
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
                type: _type,
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
              'İlan Ver',
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
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w800),
    );
  }
}

/// Tek kayan pill içinde iki seçenek — academic_calendar_page.dart'taki
/// yarıyıl seçici ile aynı desen. İki ayrı renkli kutu yerine tek bir
/// gösterge kayıyor.
class _TypeToggle extends StatelessWidget {
  final String type;
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.type, required this.onChanged});

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
        children: [
          Expanded(
            child: _TypeOption(
              label: 'Kaybettim',
              selected: type == 'kayip',
              onTap: () => onChanged('kayip'),
            ),
          ),
          Expanded(
            child: _TypeOption(
              label: 'Buldum',
              selected: type == 'bulundu',
              onTap: () => onChanged('bulundu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
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
          label,
          style: TextStyle(
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _PhotoPicker({
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
                  child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
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
      child: Container(
        height: 120,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 26,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              'Fotoğraf ekle',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'opsiyonel — eşyayı tanımaya yardımcı olur',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final bool enabled;
  final bool submitting;
  final String type;
  final VoidCallback onPressed;

  const _SubmitBar({
    required this.enabled,
    required this.submitting,
    required this.type,
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
          colors: [background, background.withValues(alpha: 0.62), Colors.transparent],
        ),
      ),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
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
          label: Text(
            submitting
                ? 'Paylaşılıyor...'
                : type == 'kayip'
                ? 'Kayıp İlanı Ver'
                : 'Buluntu İlanı Ver',
          ),
        ),
      ),
    );
  }
}
