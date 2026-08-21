import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/components/progress_snackbar.dart';
import '../../../../shared/utils/error_message.dart';
import '../../models/club_member.dart';
import '../../providers/community_provider.dart';

/// Öğrenci numarasıyla yönetici üye arama/ekleme alt sayfası.
///
/// Numara 11 haneye ulaştığında otomatik arama yapar; bulunan öğrenciyi
/// onayla eklemek üzere döner, bulunamazsa "Üye bulunamadı" bilgisini
/// gösterir. Zaten üye olan ya da kulüp başkanının kendisi olan bir numara
/// girilirse ekleme engellenir.
class AddMemberSheet extends ConsumerStatefulWidget {
  final String clubId;
  final String presidentUid;
  final List<String> existingMemberUids;

  const AddMemberSheet({
    super.key,
    required this.clubId,
    required this.presidentUid,
    required this.existingMemberUids,
  });

  static Future<ClubMember?> show(
    BuildContext context, {
    required String clubId,
    required String presidentUid,
    required List<String> existingMemberUids,
  }) {
    return showModalBottomSheet<ClubMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMemberSheet(
        clubId: clubId,
        presidentUid: presidentUid,
        existingMemberUids: existingMemberUids,
      ),
    );
  }

  @override
  ConsumerState<AddMemberSheet> createState() => _AddMemberSheetState();
}

enum _SearchState { idle, loading, found, notFound }

class _AddMemberSheetState extends ConsumerState<AddMemberSheet> {
  static const _studentIdLength = 11;

  final _controller = TextEditingController();
  _SearchState _state = _SearchState.idle;
  ClubMember? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _alreadyMember =>
      _result != null && widget.existingMemberUids.contains(_result!.uid);

  bool get _isPresident =>
      _result != null && _result!.uid == widget.presidentUid;

  Future<void> _onChanged(String value) async {
    if (value.length < _studentIdLength) {
      setState(() {
        _state = _SearchState.idle;
        _result = null;
      });
      return;
    }

    setState(() => _state = _SearchState.loading);
    try {
      final member = await ref
          .read(communityServiceProvider)
          .findStudentByNumber(value);
      if (!mounted) return;
      setState(() {
        _result = member;
        _state = member == null ? _SearchState.notFound : _SearchState.found;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _SearchState.notFound);
      showProgressSnackBar(
        context,
        message: errorMessage(e),
        icon: Icons.error_outline_rounded,
        accentColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 6),
              child: Text(
                'ÜYE EKLE',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
              child: TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_studentIdLength),
                ],
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  labelText: 'Öğrenci numarası',
                  hintText: '11 haneli numara',
                  prefixIcon: Icon(Icons.badge_outlined),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _buildResult(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    switch (_state) {
      case _SearchState.idle:
        return const SizedBox(height: 64);
      case _SearchState.loading:
        return const SizedBox(
          height: 64,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case _SearchState.notFound:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_off_rounded,
                size: 20,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Üye bulunamadı',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      case _SearchState.found:
        final member = _result!;
        final blocked = _alreadyMember || _isPresident;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
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
                            fontWeight: FontWeight.w800,
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
                ],
              ),
            ),
            if (blocked) ...[
              const SizedBox(height: 8),
              Text(
                _isPresident
                    ? 'Bu kişi zaten topluluğun başkanı.'
                    : 'Bu kişi zaten yönetici üye.',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: blocked
                  ? null
                  : () => Navigator.of(context).pop(member),
              child: const Text('Ekle'),
            ),
          ],
        );
    }
  }
}
