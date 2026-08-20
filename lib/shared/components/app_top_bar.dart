import 'package:flutter/material.dart';

import 'akdeniz_cep_logo.dart';

/// Sekme sayfalarında paylaşılan üst bar iskeleti: solda logo + sayfa adı
/// tek bir kolonda üst üste, sağda o kolonun yüksekliğiyle hizalanmış
/// aksiyonlar.
///
/// Logo ve başlık fontu sabit olduğundan (sayfa adının uzunluğu satırı
/// sarmadığı sürece) kolonun toplam yüksekliği her sayfada aynıdır —
/// sekmeler arası geçişte aksiyon hizası kaymaz.
const kTopBarHPad = 20.0;
const kTopBarLogoFontSize = 18.0;
const kTopBarTitleFontSize = 26.0;
const kTopBarTitleGap = 0.0;
const kTopBarActionSize = 40.0;

class AppTopBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  /// Genişleyen ek içerik (ör. arama alanı) — logo/başlık kolonunun altında,
  /// hiza garantisinin dışında yer alır.
  final Widget? bottom;

  /// Gradyan/koyu bir zemin üzerinde mi çiziliyor (Yemekhane) — logo ve
  /// başlık beyaz varyanta döner.
  final bool onGradient;

  final EdgeInsets padding;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.onGradient = false,
    this.padding = const EdgeInsets.fromLTRB(
      kTopBarHPad,
      4,
      kTopBarHPad,
      6,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AkdenizCepLogo(
                      fontSize: kTopBarLogoFontSize,
                      akdenizColor: onGradient ? Colors.white : null,
                      cepColor: onGradient ? const Color(0xFF8FD0FF) : null,
                    ),
                    const SizedBox(height: kTopBarTitleGap),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: kTopBarTitleFontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                        letterSpacing: -0.2,
                        color: onGradient
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actions[i],
              ],
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 14), bottom!],
        ],
      ),
    );
  }
}

/// [AppTopBar] sağındaki sabit boyutlu (40x40, radius 20) aksiyon türleri.
class AppTopBarAction extends StatelessWidget {
  final Widget child;

  const AppTopBarAction._(this.child);

  /// Dış hatlı, düz zemin — Etkinlikler'de ara/kapat.
  factory AppTopBarAction.outlined({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return AppTopBarAction._(
      Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Tooltip(
            message: tooltip,
            child: Material(
              color: colorScheme.surface,
              shape: CircleBorder(
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: kTopBarActionSize,
                  height: kTopBarActionSize,
                  child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Dolu marka rengi — Etkinlikler'de oluştur.
  factory AppTopBarAction.filled({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return AppTopBarAction._(
      Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Tooltip(
            message: tooltip,
            child: Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  width: kTopBarActionSize,
                  height: kTopBarActionSize,
                  child: Icon(icon, size: 22, color: colorScheme.onPrimary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Yarı saydam beyaz — gradyan zemin üzerinde (Yemekhane bilgi/takvim).
  factory AppTopBarAction.translucent({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return AppTopBarAction._(
      Opacity(
        opacity: onTap != null ? 1 : 0.35,
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onTap,
            iconSize: 20,
            constraints: const BoxConstraints.tightFor(
              width: kTopBarActionSize,
              height: kTopBarActionSize,
            ),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(foregroundColor: Colors.white),
            icon: Icon(icon),
          ),
        ),
      ),
    );
  }

  /// Kullanıcı baş harfi rozeti — profile gider (Home, Ring).
  factory AppTopBarAction.avatar({
    required String initial,
    required VoidCallback onTap,
  }) {
    return AppTopBarAction._(
      Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: kTopBarActionSize / 2,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Görünmez yer tutucu — Harita'da sağ slotu boş bırakır ama hizayı korur.
  factory AppTopBarAction.placeholder() {
    return const AppTopBarAction._(
      SizedBox(width: kTopBarActionSize, height: kTopBarActionSize),
    );
  }

  @override
  Widget build(BuildContext context) => child;
}
