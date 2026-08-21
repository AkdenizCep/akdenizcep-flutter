import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/components/category_dropdown_field.dart';
import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/components/progress_snackbar.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/event_category.dart';
import '../models/club.dart';
import '../models/club_member.dart';
import '../providers/community_provider.dart';
import 'components/add_member_sheet.dart';

/// Kulüp yöneticisinin topluluk ayarlarını düzenlediği ekran.
class ClubSettingsPage extends ConsumerStatefulWidget {
  final String clubId;

  const ClubSettingsPage({super.key, required this.clubId});

  @override
  ConsumerState<ClubSettingsPage> createState() => _ClubSettingsPageState();
}

class _ClubSettingsPageState extends ConsumerState<ClubSettingsPage> {
  static const _maxNameLength = 60;
  static const _categories = [
    EventCategory.technology,
    EventCategory.sports,
    EventCategory.art,
    EventCategory.music,
    EventCategory.academic,
    EventCategory.social,
  ];

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _initialized = false;
  File? _logoImage;
  File? _coverImage;
  String _category = _categories.first.label;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initFromClub(Club club) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = club.name;
    _descriptionController.text = club.description;
    _category = _categories
        .firstWhere(
          (c) => c.label == club.category || c.id == club.category,
          orElse: () => _categories.first,
        )
        .label;
  }

  Future<void> _pickLogo() async {
    await _pickImage((file) => setState(() => _logoImage = file));
  }

  Future<void> _pickCover() async {
    await _pickImage((file) => setState(() => _coverImage = file));
  }

  Future<void> _pickImage(ValueChanged<File> onPicked) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      onPicked(File(picked.path));
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

  bool get _canSubmit =>
      !_submitting && _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSubmit) return;

    setState(() => _submitting = true);
    try {
      var logoUrl = ref
          .read(clubDetailProvider(widget.clubId))
          .valueOrNull
          ?.logoUrl;
      var coverUrl = ref
          .read(clubDetailProvider(widget.clubId))
          .valueOrNull
          ?.coverUrl;

      if (_logoImage != null) {
        logoUrl = await CloudinaryService().uploadImage(
          file: _logoImage!,
          folder: 'club-logos/${widget.clubId}',
        );
      }
      if (_coverImage != null) {
        coverUrl = await CloudinaryService().uploadImage(
          file: _coverImage!,
          folder: 'club-covers/${widget.clubId}',
        );
      }

      await ref.read(communityServiceProvider).updateClub(widget.clubId, {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'foundedYear': FieldValue.delete(),
        'logoUrl': logoUrl ?? '',
        'coverUrl': coverUrl ?? '',
      });

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
    final clubAsync = ref.watch(clubDetailProvider(widget.clubId));

    return Scaffold(
      body: clubAsync.when(
        data: _buildContent,
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
    );
  }

  Widget _buildContent(Club club) {
    _initFromClub(club);

    return SafeArea(
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
                      _CoverPicker(
                        image: _coverImage,
                        existingUrl: club.coverUrl,
                        onTap: _pickCover,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LogoPicker(
                            image: _logoImage,
                            existingUrl: club.logoUrl,
                            onTap: _pickLogo,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Topluluk adı'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  maxLength: _maxNameLength,
                                  onChanged: (_) => setState(() {}),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      _maxNameLength,
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: 'Topluluğun adı',
                                    counterText: '',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel('Hakkında'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText:
                              'Topluluğu birkaç cümleyle tanıt: ne yapıyorsunuz, '
                              'kimler katılabilir?',
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel('KATEGORİ'),
                      const SizedBox(height: 10),
                      CategoryDropdownField(
                        items: _categories,
                        value: _categories.firstWhere(
                          (c) => c.label == _category,
                          orElse: () => _categories.first,
                        ),
                        onChanged: (category) =>
                            setState(() => _category = category.label),
                      ),
                      const SizedBox(height: 22),
                      _MembersSection(clubId: widget.clubId, club: club),
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
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersSection extends ConsumerWidget {
  final String clubId;
  final Club club;

  const _MembersSection({required this.clubId, required this.club});

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final members =
        ref.read(clubMembersProvider(clubId)).valueOrNull ?? const [];

    final picked = await AddMemberSheet.show(
      context,
      clubId: clubId,
      presidentUid: club.adminUid,
      existingMemberUids: members.map((m) => m.uid).toList(),
    );
    if (picked == null || !context.mounted) return;

    try {
      await ref.read(communityServiceProvider).addClubMember(clubId, picked);
    } catch (e) {
      if (context.mounted) {
        showProgressSnackBar(
          context,
          message: errorMessage(e),
          icon: Icons.error_outline_rounded,
          accentColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    ClubMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üyeyi çıkar'),
        content: Text(
          '${member.name}, topluluğun yöneticiliğinden çıkarılsın mı?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(communityServiceProvider)
          .removeClubMember(clubId, member.uid);
    } catch (e) {
      if (context.mounted) {
        showProgressSnackBar(
          context,
          message: errorMessage(e),
          icon: Icons.error_outline_rounded,
          accentColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isPresident = currentUser != null && currentUser.id == club.adminUid;
    final membersAsync = ref.watch(clubMembersProvider(clubId));
    final members = membersAsync.valueOrNull ?? const <ClubMember>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionLabel('ÜYELER')),
            if (isPresident)
              TextButton.icon(
                onPressed: () => _addMember(context, ref),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Üye ekle'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Henüz yönetici üye yok.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                for (var i = 0; i < members.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colorScheme.outlineVariant),
                  _MemberRow(
                    member: members[i],
                    onRemove: isPresident
                        ? () => _removeMember(context, ref, members[i])
                        : null,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ClubMember member;
  final VoidCallback? onRemove;

  const _MemberRow({required this.member, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
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
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.studentId,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Üyeyi çıkar',
              onPressed: onRemove,
              icon: Icon(
                Icons.person_remove_rounded,
                size: 20,
                color: colorScheme.error,
              ),
            ),
        ],
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
              'Topluluk Ayarları',
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

class _CoverPicker extends StatelessWidget {
  final File? image;
  final String existingUrl;
  final VoidCallback onTap;

  const _CoverPicker({
    required this.image,
    required this.existingUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget preview;
    if (image != null) {
      preview = Image.file(image!, height: 150, width: double.infinity, fit: BoxFit.cover);
    } else if (existingUrl.isNotEmpty) {
      preview = CachedNetworkImage(
        imageUrl: existingUrl,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      preview = Container(
        height: 150,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(18), child: preview),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Text(
                  'Kapak görselini değiştir',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

class _LogoPicker extends StatelessWidget {
  final File? image;
  final String existingUrl;
  final VoidCallback onTap;

  const _LogoPicker({
    required this.image,
    required this.existingUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content;
    if (image != null) {
      content = Image.file(image!, fit: BoxFit.cover);
    } else if (existingUrl.isNotEmpty) {
      content = CachedNetworkImage(imageUrl: existingUrl, fit: BoxFit.cover);
    } else {
      content = ColoredBox(
        color: colorScheme.primaryContainer,
        child: Icon(
          Icons.groups_2_rounded,
          size: 32,
          color: colorScheme.onPrimaryContainer,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: colorScheme.outlineVariant, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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
              : const Icon(Icons.save_rounded, size: 22),
          label: Text(submitting ? 'Kaydediliyor...' : 'Kaydet'),
        ),
      ),
    );
  }
}
