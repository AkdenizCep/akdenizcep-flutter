import 'dart:async';

import 'package:flutter/material.dart';

/// Etkinliğe katılma butonunun görsel fazları.
enum _JoinPhase { idle, loading, success }

/// Etkinlik kartı ve etkinlik detayında ortak kullanılan katılma butonu.
///
/// Basıldığında [onPressed] tamamlanana kadar spinner gösterir; katılma
/// yönünde işlem başarılıysa kısa bir tik animasyonu oynatıp "Katılıyorsun"
/// görünümüne geçer. Ayrılma yönünde tik gösterilmez.
///
/// Katılım durumu provider tarafında optimistic güncellendiği için widget,
/// animasyon sürerken dışarıdan gelen [joined] değişimini yok sayar ve
/// animasyon bittiğinde güncel değere oturur.
class JoinButton extends StatefulWidget {
  /// Kullanıcının etkinliğe katılmış olup olmadığı.
  final bool joined;

  /// Butonun tıklanabilir olup olmadığı.
  final bool enabled;

  /// Katılma/ayrılma işlemi. Hata fırlatırsa buton eski görünümüne döner;
  /// hatayı kullanıcıya göstermek çağıranın sorumluluğundadır.
  final Future<void> Function() onPressed;

  /// Buton yüksekliği.
  final double height;

  /// Metnin solunda durum ikonu gösterilsin mi.
  final bool showLeadingIcon;

  /// Etiket stili. Verilmezse `labelLarge` kullanılır.
  final TextStyle? labelStyle;

  const JoinButton({
    super.key,
    required this.joined,
    required this.enabled,
    required this.onPressed,
    this.height = 44,
    this.showLeadingIcon = false,
    this.labelStyle,
  });

  @override
  State<JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<JoinButton> {
  static const _successHold = Duration(milliseconds: 700);
  static const _switchDuration = Duration(milliseconds: 300);

  _JoinPhase _phase = _JoinPhase.idle;

  /// Animasyon sürerken gösterilecek katılım durumu. Optimistic provider
  /// `joined`'ı anında çevirdiği için faz bitene kadar bu değer kullanılır.
  late bool _displayJoined = widget.joined;

  Timer? _successTimer;

  @override
  void didUpdateWidget(covariant JoinButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_phase == _JoinPhase.idle) {
      _displayJoined = widget.joined;
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_phase != _JoinPhase.idle) return;

    final wasJoined = _displayJoined;
    setState(() => _phase = _JoinPhase.loading);

    try {
      await widget.onPressed();
    } catch (_) {
      if (mounted) setState(() => _phase = _JoinPhase.idle);
      return;
    }

    if (!mounted) return;

    // Ayrılma yönünde tik yok — doğrudan "Katıl" görünümüne dön.
    if (wasJoined) {
      setState(() {
        _phase = _JoinPhase.idle;
        _displayJoined = widget.joined;
      });
      return;
    }

    setState(() {
      _phase = _JoinPhase.success;
      _displayJoined = true;
    });

    _successTimer?.cancel();
    _successTimer = Timer(_successHold, () {
      if (!mounted) return;
      setState(() {
        _phase = _JoinPhase.idle;
        _displayJoined = widget.joined;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filled = _displayJoined || _phase == _JoinPhase.success;
    final background = filled
        ? colorScheme.primaryContainer
        : colorScheme.primary;
    final foreground = filled
        ? colorScheme.onPrimaryContainer
        : colorScheme.onPrimary;

    final interactive = widget.enabled && _phase == _JoinPhase.idle;

    // Dis sinir: butonun renk/boyut/tik animasyonlari sayfanin geri kalanini
    // (kart gorseli, metinler, alttaki degrade) yeniden boyatmasin.
    return RepaintBoundary(
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        animationDuration: _switchDuration,
        child: InkWell(
          onTap: interactive ? _handleTap : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: _switchDuration,
            curve: Curves.easeOut,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // Kenarlik her zaman var, yalnizca rengi degisir: `null` ile
              // `Border.all` arasinda gidip gelmek butonun boyutunu
              // degistirir ve gecis boyunca her karede yeniden yerlesim
              // tetikler.
              border: Border.all(
                color: filled ? colorScheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            // Not: icerigin etrafina ayrica bir `RepaintBoundary` koymak
            // olcumde hicbir sey kazandirmadi (ayni kare sayisi), sadece
            // fazladan katman maliyeti getiriyordu. Isi yapan, butonun
            // tamamini saran distaki sinir.
            child: AnimatedSwitcher(
              duration: _switchDuration,
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: _buildContent(foreground, textTheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color foreground, TextTheme textTheme) {
    switch (_phase) {
      case _JoinPhase.loading:
        return SizedBox(
          key: const ValueKey('loading'),
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(foreground),
          ),
        );

      case _JoinPhase.success:
        return Icon(
          Icons.check_rounded,
          key: const ValueKey('success'),
          size: 24,
          color: foreground,
        );

      case _JoinPhase.idle:
        final label = _displayJoined ? 'Katılıyorsun' : 'Katıl';
        final style = (widget.labelStyle ?? textTheme.labelLarge)?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        );

        if (!widget.showLeadingIcon) {
          return Text(label, key: ValueKey('idle-$label'), style: style);
        }

        return Row(
          key: ValueKey('idle-$label'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _displayJoined
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_rounded,
              size: 20,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Text(label, style: style),
          ],
        );
    }
  }
}
